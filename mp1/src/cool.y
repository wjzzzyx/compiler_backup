/*
 *  cool.y
 *              Parser definition for the COOL language.
 *
 */
%{
#include <iostream>
#include "cool-tree.h"
#include "stringtab.h"
#include "utilities.h"

/* Add your own C declarations here */


/************************************************************************/
/*                DONT CHANGE ANYTHING IN THIS SECTION                  */

extern int yylex();           /* the entry point to the lexer  */
extern int curr_lineno;
extern char *curr_filename;
Program ast_root;            /* the result of the parse  */
Classes parse_results;       /* for use in semantic analysis */
int omerrs = 0;              /* number of errors in lexing and parsing */

/*
   The parser will always call the yyerror function when it encounters a parse
   error. The given yyerror implementation (see below) justs prints out the
   location in the file where the error was found. You should not change the
   error message of yyerror, since it will be used for grading puproses.
*/
void yyerror(const char *s);

/*
   The VERBOSE_ERRORS flag can be used in order to provide more detailed error
   messages. You can use the flag like this:

     if (VERBOSE_ERRORS)
       fprintf(stderr, "semicolon missing from end of declaration of class\n");

   By default the flag is set to 0. If you want to set it to 1 and see your
   verbose error messages, invoke your parser with the -v flag.

   You should try to provide accurate and detailed error messages. A small part
   of your grade will be for good quality error messages.
*/
extern int VERBOSE_ERRORS;

%}

/* A union of all the types that can be the result of parsing actions. */
%union {
  Boolean boolean;
  Symbol symbol;
  Program program;
  Class_ class_;
  Classes classes;
  Feature feature;
  Features features;
  Formal formal;
  Formals formals;
  Case case_;
  Cases cases;
  Expression expression;
  Expressions expressions;
  char *error_msg;
}

/* 
   Declare the terminals; a few have types for associated lexemes.
   The token ERROR is never used in the parser; thus, it is a parse
   error when the lexer returns it.

   The integer following token declaration is the numeric constant used
   to represent that token internally.  Typically, Bison generates these
   on its own, but we give explicit numbers to prevent version parity
   problems (bison 1.25 and earlier start at 258, later versions -- at
   257)
*/
%token CLASS 258 ELSE 259 FI 260 IF 261 IN 262 
%token INHERITS 263 LET 264 LOOP 265 POOL 266 THEN 267 WHILE 268
%token CASE 269 ESAC 270 OF 271 DARROW 272 NEW 273 ISVOID 274
%token <symbol>  STR_CONST 275 INT_CONST 276 
%token <boolean> BOOL_CONST 277
%token <symbol>  TYPEID 278 OBJECTID 279 
%token ASSIGN 280 NOT 281 LE 282 ERROR 283

/*  DON'T CHANGE ANYTHING ABOVE THIS LINE, OR YOUR PARSER WONT WORK       */
/**************************************************************************/

   /* Complete the nonterminal list below, giving a type for the semantic
      value of each non terminal. (See section 3.6 in the bison 
      documentation for details). */

/* Declare types for the grammar's non-terminals. */
%type	<program>	program
%type	<classes>	class_list
%type	<class_>	class
%type	<features>	feature_list
%type	<feature>	feature
%type	<expressions>	exp_list
%type	<expressions>	exp_block
%type	<expression>	expression
%type	<expression>	dispatch_exp
%type	<expression>	cond_exp
%type	<expression>	loop_exp
%type	<expression>	let_exp
%type	<expression>	let_init
%type	<expression>	case_exp
%type	<formals>	formal_list
%type	<formal>	formal
%type	<cases>		branch_list
%type	<case_>		branch


/* You will want to change the following line. */
/*%type <features> dummy_feature_list*/

/* Precedence declarations go here. */
%right ASSIGN
%right NOT
%nonassoc LE '=' '<'
%left '+' '-'
%left '*' '/'
%right ISVOID
%right '~'
%nonassoc '@'
%nonassoc '.'

%%
/* 
   Save the root of the abstract syntax tree in a global variable.
*/
program		: class_list
				{ ast_root = program($1); }
			;

class_list  : class            /* single class */
            	{ $$ = single_Classes($1); }
        	| class_list class /* several classes */
		    	{ $$ = append_Classes($1,single_Classes($2)); }
        	;

/* If no parent is specified, the class inherits from the Object class. */
/* Empty feature list and non-empty feature list are handled separately. */
class  		: CLASS TYPEID '{' '}' ';'
				{ $$ = class_($2,idtable.add_string("Object"),nil_Features(),stringtable.add_string(curr_filename)); }
			| CLASS TYPEID INHERITS TYPEID '{' '}' ';'
				{ $$ = class_($2,$4,nil_Features(),stringtable.add_string(curr_filename)); }
			| CLASS TYPEID '{' feature_list '}' ';'
				{ $$ = class_($2,idtable.add_string("Object"),$4,stringtable.add_string(curr_filename)); }
			| CLASS TYPEID INHERITS TYPEID '{' feature_list '}' ';'
				{ $$ = class_($2,$4,$6,stringtable.add_string(curr_filename)); }
			/* Error recovery */
			| CLASS error ';'
				{ $$ = NULL; }
			| CLASS error '{' feature_list '}' ';'
				{ $$ = NULL; }
			| CLASS error CLASS
				{ $$ = NULL; yychar = CLASS; }
			| CLASS error '{' feature_list '}' CLASS
				{ $$ = NULL; yychar = CLASS; }
			| CLASS TYPEID '{' '}' error
				{
					if(VERBOSE_ERRORS)
						fprintf(stderr, "Missing semicolon after class\n");
				}
			| CLASS TYPEID INHERITS TYPEID '{' '}' error
				{
					if(VERBOSE_ERRORS)
						fprintf(stderr, "Missing semicolon after class\n");
				}
			| CLASS TYPEID '{' feature_list '}' error
				{
					if(VERBOSE_ERRORS)
						fprintf(stderr, "Missing semicolon after class\n");
				}
			| CLASS TYPEID INHERITS TYPEID '{' feature_list '}' error
				{
					if(VERBOSE_ERRORS)
						fprintf(stderr, "Missing semicolon after class\n");
				}
        	;

/* Definition of non-empty feature list */
feature_list	: feature
					{ $$ = single_Features($1); }
				| feature_list feature
					{ $$ = append_Features($1,single_Features($2)); }
				/* error recovery */

				;

feature		: OBJECTID ':' TYPEID ';'    /* Attribute */
				{ $$ = attr($1,$3,no_expr()); }
			| OBJECTID ':' TYPEID ASSIGN expression ';'    /* Attribute with initialization */
				{ $$ = attr($1,$3,$5); }
			| OBJECTID '(' ')' ':' TYPEID '{' expression '}' ';'    /* Method */
				{ $$ = method($1,nil_Formals(),$5,$7); }
			| OBJECTID '(' formal_list ')' ':' TYPEID '{' expression '}' ';'    /* Method with formals */
				{ $$ = method($1,$3,$6,$8); }
			/* error recovery */
			| error ';'
				{
					$$ = NULL;
					if(VERBOSE_ERRORS)
						fprintf(stderr, "Error in feature\n");
				}
			| OBJECTID ':' TYPEID error
				{
					$$ = NULL;
					if(VERBOSE_ERRORS)
						fprintf(stderr, "Missing semicolon after feature\n");
				}
			| OBJECTID ':' TYPEID ASSIGN expression error
				{
					$$ = NULL;
					if(VERBOSE_ERRORS)
						fprintf(stderr, "Missing semicolon after feature\n");
				}
			| OBJECTID '(' ')' ':' TYPEID '{' expression '}' error
				{
					$$ = NULL;
					if(VERBOSE_ERRORS)
						fprintf(stderr, "Missing semicolon after feature\n");
				}
			| OBJECTID '(' formal_list ')' ':' TYPEID '{' expression '}' error
				{
					$$ = NULL;
					if(VERBOSE_ERRORS)
						fprintf(stderr, "Missing semicolon after feature\n");
				}
			;

/* Definition of non-empty formal list */
formal_list	: formal
				{ $$ = single_Formals($1); }
			| formal_list ',' formal
				{ $$ = append_Formals($1,single_Formals($3)); }
			/* error recovery */
			| error ','
				{ $$ = NULL; yychar = ','; }
			| error ')'
				{ $$ = NULL; yychar = ')'; }
			| formal_list ',' error ','
				{ $$ = NULL; yychar = ','; }
			| formal_list ',' error ')'
				{ $$ = NULL; yychar = ')'; }
			;

formal		: OBJECTID ':' TYPEID
				{ $$ = formal($1,$3); }
			;

/* Definition of all kinds of expressions */
expression	: BOOL_CONST
				{ $$ = bool_const($1); }
			| INT_CONST
				{ $$ = int_const($1); }
			| STR_CONST
				{ $$ = string_const($1); }
			| OBJECTID    /* TYPEID is not an expression */
				{ $$ = object($1); }
			| OBJECTID ASSIGN expression
				{ $$ = assign($1,$3); }
			| dispatch_exp
			| cond_exp
			| loop_exp
			| '(' expression ')'
				{ $$ = $2; }
			| '{' exp_block '}'
				{ $$ = block($2); }
			| let_exp
			| case_exp
			| NEW TYPEID
				{ $$ = new_($2); }
			| ISVOID expression
				{ $$ = isvoid($2); }
			| expression '+' expression
				{ $$ = plus($1,$3); }
			| expression '-' expression
				{ $$ = sub($1,$3); }
			| expression '*' expression
				{ $$ = mul($1,$3); }
			| expression '/' expression
				{ $$ = divide($1,$3); }
			| NOT expression
				{ $$ = comp($2); }
			| '~' expression
				{ $$ = neg($2); }
			| expression '<' expression
				{ $$ = lt($1,$3); }
			| expression LE expression
				{ $$ = leq($1,$3); }
			| expression '=' expression
				{ $$ = eq($1,$3); }
			/* error recovery */

			;

/* Definition of non-empty expression list. Used in dispatch expressions. */
exp_list	: expression
				{ $$ = single_Expressions($1); }
			| exp_list ',' expression
				{ $$ = append_Expressions($1,single_Expressions($3)); }
			/* error recovery */
			| error ','
				{ $$ = NULL; yychar = ','; }
			| error ')'
				{ $$ = NULL; yychar = ')'; }
			| exp_list ',' error ','
				{ $$ = NULL; yychar = ','; }
			| exp_list ',' error ')'
				{ $$ = NULL; yychar = ')'; }
			;

/* The definition of expression block does not consider the outer '{' and '}'. */
/* In an expression block, expressions are terminated by ';'. */ 
exp_block	: expression ';'
				{ $$ = single_Expressions($1); }
			| exp_block expression ';'
				{ $$ = append_Expressions($1,single_Expressions($2)); }
			/* error recovery */
			| expression error
				{
					$$ = NULL;
					if(VERBOSE_ERRORS)
						fprintf(stderr, "Missing semicolon after expression in block\n");
				}
			| exp_block expression error
				{
					$$ = NULL;
					if(VERBOSE_ERRORS)
						fprintf(stderr, "Missing semicolon after expression in block\n");
				}			
			| error ';'
				{ $$ = NULL; }
			| exp_block error ';'
				{ $$ = NULL; }		
			;

/* There are three kinds of dispatch expressions, and the circumstances of empty feature list and non-empty feature list are handled separately. */
dispatch_exp: expression '.' OBJECTID '(' ')'
				{ $$ = dispatch($1,$3,nil_Expressions()); }
			| OBJECTID '(' ')'
				{ $$ = dispatch(object(idtable.add_string("self")),$1,nil_Expressions()); }
			| expression '@' TYPEID '.' OBJECTID '(' ')'
				{ $$ = static_dispatch($1,$3,$5,nil_Expressions()); }
			| expression '.' OBJECTID '(' exp_list ')'
				{ $$ = dispatch($1,$3,$5); }
			| OBJECTID '(' exp_list ')'
				{ $$ = dispatch(object(idtable.add_string("self")),$1,$3); }
			| expression '@' TYPEID '.' OBJECTID '(' exp_list ')'
				{ $$ = static_dispatch($1,$3,$5,$7); }
			;

cond_exp	: IF expression THEN expression ELSE expression FI
				{ $$ = cond($2,$4,$6); }
			/* error recovery */
			| IF error FI
				{
					$$ = NULL;
					if(VERBOSE_ERRORS)
						fprintf(stderr, "Error in if expression\n");
				}
			| IF expression THEN expression ELSE expression error
				{
					$$ = NULL;
					if(VERBOSE_ERRORS)
						fprintf(stderr, "Missing fi after if expression\n");
				}
			;

loop_exp	: WHILE expression LOOP expression POOL
				{ $$ = loop($2,$4); }
			/* error recovery */
			| WHILE error POOL
				{
					$$ = NULL;
					if(VERBOSE_ERRORS)
						fprintf(stderr, "Error in while expression\n");
				}
			;
/* So far there is no shift/reduce or reduce/reduce conflict. */
/* I am not sure if let_exp is defined as such. It seems work. */
/* The optional initialization part of a let expression */
let_init	:
				{ $$ = no_expr(); }
			| ASSIGN expression
				{ $$ = $2; }
			;
let_exp		: OBJECTID ':' TYPEID let_init IN expression
				{ $$ = let($1, $3, $4, $6); }
			| OBJECTID ':' TYPEID let_init ',' let_exp
				{ $$ = let($1, $3, $4, $6); }
			| LET OBJECTID ':' TYPEID let_init IN expression
				{ $$ = let($2, $4, $5, $7); }
			| LET OBJECTID ':' TYPEID let_init ',' let_exp
				{ $$ = let($2, $4, $5, $7); }
			/* error recovery */
			| LET error expression
				{ $$ = NULL; }	
			;
/* So far 18 more shift/reduce conflicts are caused. They rise when it needs to determine whether to reduce a let_exp or shift to a longer exp at the tail of a let_exp. The default shift action is adopted. */

case_exp	: CASE expression OF branch_list ESAC
				{ $$ = typcase($2,$4); }
			/* error recovery */
			| CASE error ESAC
				{ $$ = NULL; }
			;

			
/* Definition of non-empty branch list. A branch list cannot be empty. */
branch_list	: branch
				{ $$ = single_Cases($1); }
			| branch_list branch
				{ $$ = append_Cases($1,single_Cases($2)); }
			;
branch		: OBJECTID ':' TYPEID DARROW expression ';'
				{ $$ = branch($1,$3,$5); }
			/* error recovery */			
			| error ';'
				{ $$ = NULL; }
			;

/* end of grammar */
%%

/* This function is called automatically when Bison detects a parse error. */
void yyerror(const char *s)
{
  cerr << "\"" << curr_filename << "\", line " << curr_lineno << ": " \
    << s << " at or near ";
  print_cool_token(yychar);
  cerr << endl;
  omerrs++;

  if(omerrs>20) {
      if (VERBOSE_ERRORS)
         fprintf(stderr, "More than 20 errors\n");
      exit(1);
  }
}

