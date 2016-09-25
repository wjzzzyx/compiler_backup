/*
 *  the scanner definition for cool.
 */

/*
 *  stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* the compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
  if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
    YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern YYSTYPE cool_yylval;


/* Add Your own definitions here */
int comment_depth = 0;    /* This var is used to count the depth of nested comments */
int string_error = 0;    /* This var shows whether a string contains invalid character */
int string_too_long = 0;    /* This var shows whether a string is too long */
int string_insert(char);    /* This function is used to insert a char to the string_buf */
%}

%option noyywrap
%x COMMENT
%x STRING

/*
 * Define names for regular expressions here.
 */
delim		[ \f\r\t\v]
ws		{delim}+
letter		[a-zA-Z]
digit		[0-9]
integer		{digit}+

/* keywords which are case insensitive*/
class		(?i:class)
inherits	(?i:inherits)
if		(?i:if)
then		(?i:then)
else		(?i:else)
fi		(?i:fi)
in		(?i:in)
while		(?i:while)
loop		(?i:loop)
pool		(?i:pool)
case		(?i:case)
esac		(?i:esac)
new		(?i:new)
of		(?i:of)
not		(?i:not)
isvoid		(?i:isvoid)
let		(?i:let)
true		(?i:(?-i:t)rue)
false		(?i:(?-i:f)alse)

typeid		[A-Z]({letter}|{digit}|_)*
objectid	[a-z]({letter}|{digit}|_)*
%%

 /*
  * Define regular expressions for the tokens of COOL here. Make sure, you
  * handle correctly special cases, like:
  *   - Nested comments
  *   - String constants: They use C like systax and can contain escape
  *     sequences. Escape sequence \c is accepted for all characters c. Except
  *     for \n \t \b \f, the result is c.
  *   - Keywords: They are case-insensitive except for the values true and
  *     false, which must begin with a lower-case letter.
  *   - Multiple-character operators (like <-): The scanner should produce a
  *     single token for every such operator.
  *   - Line counting: You should keep the global variable curr_lineno updated
  *     with the correct line number
  */

 /* comment */
 /* if "*)" is met out of the comment mode */
"*)"			{
			    cool_yylval.error_msg = "Unmatched *)";
			    return(ERROR);
			}
"(*"			{
			    comment_depth = 1;
			    BEGIN(COMMENT);
			}
<COMMENT>"(*"		{comment_depth += 1;}
<COMMENT>"*)"		{
			    comment_depth -= 1;
			    if(comment_depth == 0)
		    	        BEGIN(INITIAL);
			}
<COMMENT>\n		{curr_lineno++;}
<COMMENT>.		{}
<COMMENT><<EOF>>	{
			    BEGIN(INITIAL);
			    cool_yylval.error_msg = "EOF in comment";
			    return(ERROR);
			}
--.*			{}

 /* string */
\"			{
			    BEGIN(STRING);
			    string_error = 0;
			    string_too_long = 0;
			    string_buf_ptr = string_buf;
			}
<STRING>\"		{
			    BEGIN(INITIAL);
			    if(!string_error && !string_too_long){
			        *string_buf_ptr = '\0';    /* indicate end of string */
			        cool_yylval.symbol = stringtable.add_string(string_buf);    /* add a string to the string_tab */
			        string_buf_ptr = NULL;
			        return(STR_CONST);
			    }
			}
 /*if an unescaped \n is met in a string, return ERROR and resume lexer from the next line */
<STRING>\n		{
			    curr_lineno++;
			    cool_yylval.error_msg = "Unterminated string constant";
			    BEGIN(INITIAL);
			    return(ERROR);
			}
 /* "\c" is translated into "c", except for "\b" "\t" "\n" and "\f" */
<STRING>\\[^btnf]	{
			    if(yytext[1] == '\n')    /* if an escaped \n is met in a string, add the line number and continue */
			        curr_lineno++;
			    if(string_insert(yytext[1]) != 0 && !string_too_long){
			        string_too_long = 1;
			        cool_yylval.error_msg = "String constant too long";
			        return(ERROR);
			    }
			}
 /* handle "\b" "\t" "\f" and "\n" specifically */
<STRING>\\[b]		{
			    if(string_insert('\b') != 0 && !string_too_long){
			        string_too_long = 1;
			        cool_yylval.error_msg = "String constant too long";
			        return(ERROR);
			    }
			}
<STRING>\\[t]		{
			    if(string_insert('\t') != 0 && !string_too_long){
			        string_too_long = 1;
			        cool_yylval.error_msg = "String constant too long";
			        return(ERROR);
			    }
			}
<STRING>\\[f]		{
			    if(string_insert('\f') != 0 && !string_too_long){
			        string_too_long = 1;
			        cool_yylval.error_msg = "String constant too long";
			        return(ERROR);
			    }
			}
<STRING>\\[n]		{
			    if(string_insert('\n') != 0 && !string_too_long){
			        string_too_long = 1;
			        cool_yylval.error_msg = "String constant too long";
			        return(ERROR);
			    }
			}
<STRING><<EOF>>		{
			    cool_yylval.error_msg = "EOF in string constant";
			    BEGIN(INITIAL);
			    return(ERROR);
			}
<STRING>\0		{
			    if(!string_error){
			        string_error = 1;
			        cool_yylval.error_msg = "String contains null character";
			        return(ERROR);
			    }
			}
 /* for any other character, add it to the string if there is still space */
<STRING>.		{
			    if(string_insert(yytext[0]) != 0 && !string_too_long){
			        string_too_long = 1;
			        cool_yylval.error_msg = "String constant too long";
			        return(ERROR);
			    }
			}

 /* white space*/
{ws}		{/*no action and no return*/}
\n		{curr_lineno++;}

 /* key words*/
{class}		{return(CLASS);}
{inherits}	{return(INHERITS);}
{if}		{return(IF);}
{then}		{return(THEN);}
{else}		{return(ELSE);}
{fi}		{return(FI);}
{in}		{return(IN);}
{while}		{return(WHILE);}
{loop}		{return(LOOP);}
{pool}		{return(POOL);}
{case}		{return(CASE);}
{esac}		{return(ESAC);}
{new}		{return(NEW);}
{of}		{return(OF);}
{not}		{return(NOT);}
{isvoid}	{return(ISVOID);}
{let}		{return(LET);}
{true}		{cool_yylval.boolean = true;
		return(BOOL_CONST);}
{false}		{cool_yylval.boolean = false;
		return(BOOL_CONST);}

 /* character symbols */
"+"		{return('+');}
"/"		{return('/');}
"-"		{return('-');}
"*"		{return('*');}
"="		{return('=');}
"<"		{return('<');}
"."		{return('.');}
"~"		{return('~');}
","		{return(',');}
";"		{return(';');}
":"		{return(':');}
"("		{return('(');}
")"		{return(')');}
"@"		{return('@');}
"{"		{return('{');}
"}"		{return('}');}
"=>"		{return(DARROW);}
"<="		{return(LE);}
"<-"		{return(ASSIGN);}

 /* id */
{typeid}	{
		    cool_yylval.symbol = idtable.add_string(yytext);
		    return(TYPEID);
		}
{objectid}	{
		    cool_yylval.symbol = idtable.add_string(yytext);
		    return(OBJECTID);
		}
{integer}	{
		    cool_yylval.symbol = inttable.add_string(yytext);
		    return(INT_CONST);
		}

 /* error character */
.		{
		    cool_yylval.error_msg = yytext;
		    return(ERROR);
		}
%%

int string_insert(char ch){
    if(string_buf_ptr >= string_buf + MAX_STR_CONST - 1){
        return 1;
    }
    else{
        *string_buf_ptr++ = ch;
        return 0;
    }
}

