###一、综述
在本实验中，我实现了COOL语言的词法分析器和语法分析器，并在语法分析的过程中做了一定的错误恢复。
词法分析器可以完美地从输入流中读取token，并能处理嵌套注释、字符串中的转义字符等。此外它还能做如下的错误处理：
>遇到无效字符(不可能是任何 token 的开头)时, 返回包含这个字符的字符串, 并从下个字符开始继续分析.
>字符串过长, 或者包含了无效字符，则报错 "String constant too long" / "String contains null character". 在这个字符串的结束处开始继续分析
>如果一个字符串包含非转义的换行, 则报错 "Unterminated string constant"， 并从下一行开始恢复词法分析
>如果在字符串/注释中遇到了 EOF, 则报错 "EOF in string constant/comment"
>在注释之外的地方遇到了 *), 报错 "Unmatched *)"

语法分析器可以正确地为COOL语法的每一种结构建立AST上的结点，并且在遇到以下语法错误时能够恢复分析：
>class：可以处理class类的类名、继承的基类错误或末尾的分号缺失。class中可能包含feature_list，它内部出现的错误交给下层处理。
>feature_list:其中用分号间隔的各个feature处理各自的错误。feature中可能包含formal_list和expression部分，它们内部出现的错误交给下层处理。
>formal_list:其中一个formal错误，可以跳到下一个formal。
>expression:可以处理条件语句、循环语句、let语句和case语句中的部分错误。例如，可以处理条件语句中除了末尾的fi缺失外的其他错误、循环语句中末尾的pool缺失外的其他错误。可以处理let语句中变量列表错误或in缺失错误。
>expression block:其中一条表达式错误，可以跳出到下一条表达式。
>expression list:其中一条表达式错误，可以跳到下一条表达式。

###二、MP1.2说明文档
分以下几部分阐述本实验的实现
#####一、基础部分
　　这部分的要求是：
>1、完成关键词的分析.
>2、完成行号的记录, 变量 curr\_lineno 用来记录源码的行号(已经定义).
>3、程序中一个词法单位(lexeme) 往往出现多次, 比如一个变量名. 为了节省时间和空间, 编译器会把这些词法单元用一个 string table 保存. 在 cool-support 里面提供了一个 string table 的实现. 有三种 String Table： 字符串的、整型常量的、标识符的. 请填好这三个 String Table.
>4、此外，不用检查整型常量是否合适. 特殊的 Identifier (如 Object, Int, self 等)暂时不用特殊处理, 以后再说.

　　由于除了true和false以外的关键词是大小写不敏感的，因此用flex中的（？：）正则表达式来定义关键字，例如if定义为`（？:if）`。而true和false可分别定义为`(?i:(?-i:t)rue)`和`(?i:(?-i:f)alse)`。当匹配到关键字或运算符等token时，只需返回该token类型的标号（已在cool-support/include/cool-parse.h中定义）。当匹配到true或false时，还需对yylval赋值以告诉语法分析器该布尔量的真假。
　　Typeid是以大写字母开始并由字母、数字、下划线组成的串，Objectid是以小写字母开始并由字母、数字、下划线组成的串，因此匹配两者的正则表达式分别是`[A-Z]\({letter}|{digit}|\_)\*`， `[a-z]\({letter}|{digit}|\_)\*`。
　　一个需注意的地方是匹配关键字的模式应放在匹配标识符的模式之前，这与flex消除二义的方式相一致。这样，这些关键字将成为保留字。
　　无论是在普通状态下，还是在后叙的COMMENT或STRING状态下，每次匹配到非转义的换行符时，就将curr\_lineno加1,以此实现行号的记录。
　　当匹配到整数或标识符时，调用相应的符号表的add\_string()函数向符号表中增加条目，并向语法分析器返回相应的类型标号。
　　最后，用模式.来匹配所有的无效字符。
#####二、注释的处理
　　对注释的要求是：
>1、注释有两种类型，形如(\*...\*)的注释可以嵌套。
>2、如果在注释中遇到了 EOF，则报错 "EOF in string comment"。不要为这个注释生成 token.
>3、在注释外遇到”\*)“时报错，而不是返回两个符号\*和）。

　　对形如"--..."的注释的处理较简单，只需以--.\*模式匹配它即可。因为.匹配除换行符外的所有字符，所以这一模式可以匹配整行注释直到遇到行末的换行符或EOF。
　　对形如"(\*...\*)"的注释的处理需要用到flex的起始状态。起始状态被用来限定特定规则的作用范围，或者根据文件的特定内容来改变词法分析器的工作方式。起始状态有两种，分别是用%s声明的共享模式和用%x声明的独占模式，两者的差异在于在独占的起始状态下，没有任何起始状态修饰的规则将不会被匹配。起始状态可以用BEGIN()语句设置。
　　本实验中设置了COMMENT和STRING两个独占的起始状态，分别用于注释和字符串的处理。在COMMENT起始状态下，需要特殊处理的匹配的模式有"(\*"、"\*)"、\n、和EOF等。匹配到前两个模式时要更改当前注释的嵌套层数，匹配到\n时将curr\_lineno加1,匹配到EOF时返回INITIAL起始状态，匹配到其他字符时不执行任何操作。
#####三、字符串的处理
　　对字符串处理的要求是：
>1、字符串过长，则报错 "String constant too long"。在这个字符串的结束处开始继续分析, 不要为这个字符串生成错误记号之前生成一个string token。
>2、包含了无效字符，则报错"String contains null character"。在这个字符串的结束处开始继续分析, 不要为这个字符串生成错误记号之前生成一个string token。
>3、如果一个字符串包含非转义的换行，则报错 "Unterminated string constant"，并从下一行开始恢复词法分析。这里假设程序员忘记加 close-quote （即右引号）。在生成错误记号前不产生一个 string token。
>4、如果在字符串中遇到了 EOF, 则报错 "EOF in string constant". 不要为这个注释生成 token。
>5、除了"\b"、"\t"、"\r"和"\n"外，遇到"\c"时，转换为"c"再写入字符串。

　　与comment类似，对字符串处理需要用到一个STRING起始状态。在INITIAL状态下匹配到"""时进入STRING状态，直到再次遇到"""、非转义换行符或EOF时退出STRING状态。
　　本实验中对过长字符串采用这样的处理方式：每次调用string\_insert()函数向string\_buf中插入字符时，检查string\_buf是否已满，若未满则插入，否则插入失败。string\_insert()函数调用失败返回后，如果string\_too\_long标志为0,则将其置为1，并返回错误信息。对于无效字符null采用类似的方式处理，即匹配到null模式时，如果string\_error标志为0，则将其置为1，并返回相应错误信息。无论字符串中含有几个null字符，都只产生一条错误信息。
　　如果匹配到非转义换行符，将行数加一，退出STRING起始状态并返回错误信息。因此错误信息的行号是在字符串的下一行（与标准程序做法相同）。匹配到EOF时类似处理。
　　如果匹配到转义换行符，将行数加一。由于这是一种允许的模式，因此把'\n'写入字符串并继续处理下一行的字符。这个模式被统一在对\\[^btnf]模式的处理中。
　　匹配到其他字符时，调用string\_insert()函数插入。注意遇到"\c"时，需要根据c的值做特殊处理。
#####四、备注
　　本实现与标准程序的不同之处在于，当字符串中同时出现多类错误时(例如一个过长字符串中含有null)，标准程序只报告一类错误，而本程序会报告所有错误类型。

###三、MP1.3说明文档
#####1. 基础部分
这部分的要求是
>你的程序应当能够处理lexer的输出，对于正确的输入，你的程序应当打印输出整个AST。打印工作已经在cool-support/src/parser-phase.cc中做了，因此，你只要在 cool.y 中正确地构造好 ast_root 即可。为了最后的评测，你不需要、也不应该修改输出的格式或者错误报告的格式。

　　根据COOL的语法，用各个非终结符表示各种语法结构（如class，class_list等），对于每条产生式，执行相应的动作（一般来说就是生成AST上的一个结点）。这其中大部分产生式都比较简单，需要留意的地方有dispach表达式和let表达式。此外，还需注意尽量避免移进-归约和归约-归约冲突。
　　由于COOL中dispatch表达式有三种形式，
　　`<expr>.<id>(<expr>, ..., <expr>)`
　　`<id>(<expr>, ..., <expr>)`
　　`<expr>@<type>.id(<expr>, ..., <expr>)`
因此要根据不同的产生式为这三种形式的dispatch表达式生成树结点。其中第一种是普通的对象方法调用;第二种等价于`self.<id>(<expr>, ..., <expr>)`，因此要先将“self”加到idtable中，然后将得到的Symbol作为参数传递给相应的构造函数；第三种是static dispatch，通过这种方式可以指定调用基类中被覆盖的方法，它的构造函数也与前两种不同。
　　在COOL语言中，let语句中可以定义多个变量，但在语法分析的过程中，将let语句分层处理，每一层中只处理一个变量定义。这样，可以用如下的四个产生式来刻画let语句
```
let_exp	 : OBJECTID ':' TYPEID let_init IN expression
            | OBJECTID ':' TYPEID let_init ',' let_exp
			| LET OBJECTID ':' TYPEID let_init IN expression
			| LET OBJECTID ':' TYPEID let_init ',' let_exp
```
其中let_init部分是可选的初始化表达式。

#####2. 通过优先级与结合性消除冲突
这部分的要求是
>你需要定义具有正确行为的LALR文法。有时你所编写的文法文件会包含有移进-归约冲突或者归约-归约冲突。原则上，你可以通过修改文法来避免它们，然而在保证你理解Bison针对冲突的默认处理规则的情况下，你可以在文法中保留部分冲突。

移进-归约冲突分析：
通过对 '+' , '-' , '*' , '/' , ASSIGN , '<' , LE 的优先级和结合性定义，可以消除算数运算表达式、赋值表达式和比较表达式之间的的移进-归约冲突。
通过对 '.' , '@' 的优先级和结合性定义，可以消除dispatch表达式和上述表达式间的冲突。
以上算符的优先级与结合性规定如下：
```
%right ASSIGN
%right NOT
%nonassoc LE '=' '<'
%left '+' '-'
%left '*' '/'
%right ISVOID
%right '~'
%nonassoc '@'
%nonassoc '.'
```
目前实现的分析器中还存在18个移进-归约冲突，它们是let表达式和其他表达式之间的冲突。这是由于按照COOL语法，let语句末尾的表达式可以任意长而导致的。而bison的默认处理方式是移进，因此能够正确处理这种冲突。

#####3、错误恢复
这部分的基础要求是
>如果在一个class定义中遇到错误，这个类定义应能被正确终止，并且你的parser要能够继续解析下一个类定义（如果有）。
>类似地，你的parser要能从feature、let语句、{...}中的表达式中发生的错误中恢复，并跳到下一个对应层次的语法结构继续解析。

* 我认为在本实验中，class的错误处理是较难的一个，尤其是当class末尾的分号缺失时的请况下，难以判断当前class是否分析结束。因此我用了两种标志：若分号存在则以分号作为当前class的分析结束标志，否则以下一个class的开始符号‘CLASS’作为当前class的结束标志。第二种方式会把下一个类的CLASS终结符“吞掉”，因此在错误处理动作中需要将CLASS终结符重新写会yychar中。这样，parser就会以CLASS为下一个输入的token继续分析。
```
/* Error recovery */
			| CLASS error ';'
				{ $$ = NULL; }
			| CLASS error '{' feature_list '}' ';'
				{ $$ = NULL; }
			| CLASS error CLASS
				{ $$ = NULL; yychar = CLASS; }
			| CLASS error '{' feature_list '}' CLASS
				{ $$ = NULL; yychar = CLASS; }
```
为了实现力度更细的错误检测，我还把class中的错误分成两种：class本身定义的错误和class内feature的错误，后一种错误交给下层分析。
* 在分析feature时，对于简单的attribute定义，如果其中出现了错误，则将整个attribute归约为一个error。对于method定义，如果它的错误出现在参数列表中或method内的表达式中，则交给下层处理，而当它的语法错误确实是method这一层时，将整个method归约为一个error。
```
			| error ';'
				{
					$$ = NULL;
					if(VERBOSE_ERRORS)
						fprintf(stderr, "Error in feature\n");
				}
```
此外，我还专门检测了feature末尾分号丢失的错误类型。
* 方法参数的错误恢复是在formal_list这一层实现的，如果一个formal出现了语法错误，则将它归约为一个error。注意此时的结束标志可以是formal_list内的分割符‘，’，也可以是整个formal_list结束的标志‘）’。如果是后者，则还要将‘）’重新写入yychar中，以免影响后面的分析。
```
/* error recovery */
			| error ','
				{ $$ = NULL; yychar = ','; }
			| error ')'
				{ $$ = NULL; yychar = ')'; }
			| formal_list ',' error ','
				{ $$ = NULL; yychar = ','; }
			| formal_list ',' error ')'
				{ $$ = NULL; yychar = ')'; }
```
* 表达式中的错误恢复比较复杂，由于我在定义非终结符与产生式时就将一些复杂的表达式单独列出处理，因此也可以对这些表达式进行分类的错误处理。
 - 方法调用中的形参列表exp_list的错误恢复与formal_list十分类析，即如果list其中一个expression出错，将它归约为一个error。同样以分隔符‘，’或形参末的‘）’作为结束标志。
```
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
```
 - 如果在块表达式中，某个expression出错，则将它归约为一个error。由于块表达式中每个表达式都应以‘；’结尾，因此可以以‘；’作为结束标志。
```
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
```
 - 对于let表达式，如果中间变量定义部分出现语法错误，则将中间部分归约为一个error，并以表达式最后的expression作为结束标志。该expression中如果也出现了语法错误，则递归地通过对expression的错误处理来处理。
```
/* error recovery */
			| LET error expression
				{ $$ = NULL; }
```
 - 对于case表达式，实现了两种力度的检测：如果某个branch出错，将其归约为一个error，以‘；‘作为结束标志。在整个case表达式的层级，如果出错，将整个表达式中间部分归约为一个error，以ESAC作为结束标志。
```
/* error recovery */
			| CASE error ESAC
				{ $$ = NULL; }
```
```
/* error recovery */
			| error ';'
				{ $$ = NULL; }
```
 - 此外，我还对条件表达式和循环表达式作了简单的错误检测，但要求这两个表达式末尾的结束符FI和POOL不能缺失。
```
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
```
```
/* error recovery */
			| WHILE error POOL
				{
					$$ = NULL;
					if(VERBOSE_ERRORS)
						fprintf(stderr, "Error in while expression\n");
				}
```