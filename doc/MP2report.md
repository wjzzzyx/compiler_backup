####一、综述
在本实验中，我实现了将COOL语言的子集翻译到LLVM IR。该子集包括一个唯一的类Main，Main类中唯一的方法Main_main()，赋值语句，if语句，while语句，let语句，算数与比较表达式和表达式块。

####二、核心问题、设计与实现
本实验的核心问题在于：为LLVM IR中的入口函数main生成代码、为Main_main()方法生成代码以及为各种类型的COOL表达式生成代码。

---

######设计思路如下
1. 为了能够编译得到可执行文件，需要在IR中定义一个main()函数，在其中调用Main_main方法，并将它的返回值输出。
该函数在IR中的格式类似如下
```
define i32 @main() {
entry:
%tpm.0 = call i32 @Main_main()
%tpm.1 = getelementptr [25 * i8], [25 * i8]* @.str, i32 0, i32 0
%tpm.2 = call i32(i8*, ...) @printf(i8* %tpm.1, i32 %tpm.0)
ret i32 0
}
```

其中有难度的是getelementptr指令的生成和printf的调用。实现方法将在下文说明。
2. 为Main_main()函数生成代码时，有两个要点。一是，要为该函数创建一个environment，存储该函数中局部标识符与其存储地址间的映射关系。二是调用方法内expr的code()方法，为函数体中的表达式生成代码。这两步也是为任何一个函数生成代码的必要步骤。
3. 首先为比较简单的常量、算术、比较表达式生成代码。对于常量表达式，只要返回该常量操作数即可，无需生成代码。对于算术和比较表达式，首先为它们的各个操作数（也是表达式）生成代码，然后调用相应的接口为整个表达式生成代码即可。需要注意的是在除法表达式中要进行除0错误检查。
4. 对于块表达式，它的body是一个指向Expressions_class对象的指针。由于Expressions_class本质是list_node<Expression>类，因此可以用list_node类中的方法first()、more()和next()来遍历其中的表达式，调用各个表达式的code方法生成代码，并返回最后一个表达式的结果。
5. 对于赋值语句，应当去environment中查找相应的标识符的存储位置，然后用store指令将赋值表达式的值存入其中。
6. 对于let语句，由于在语法分析中做了分层处理，因此此时只需考虑一层的let语句。这里面涉及到用alloc_mem()为变量分配存储位置，在environment中添加变量与存储位置的关联，以及将初始化值存入该存储位置等操作。还有一个关键点是，每一层let语句都是一个局部的作用域，在用add_local()方法向environment中添加变量时进入了一个新的作用域，在产生完let语句的代码后也要用kill_local()方法退出该作用域。
7. 对于if语句，需要产生"true""false""end"三个标号，每个标号处开始一个新的基本块，分别是判断条件、then分支和else分支的基本块。在true和false的基本块中，各自生成then和else分支的代码，并将结果存放起来，最后在end基本块中，用一条load语句，取出存放的结果。
    *为了使同一层次的标号看起来整齐，我稍微修改了Environment类，使得同一if表达式的标号有相同的数字后缀。*
8. while语句是用条件转移和无条件转移的结合实现的。它同样需要三个标号"loop""body""out"标志的三个基本块，分别表示循环判断条件、循环体和循环结束后的下一个基本块。

---

######关键点实现方案：
1. 对于需要输出的字符串常量"Main_main() returned %d\n"，将它作为一个全局的常量，需要输出时用getelementptr取它的首地址。该字符串的类型是一个长度为25、每个元素是INT8的op_arr_type，因此getelementptr指令的第一个参数是[25 * i8]，第二个参数是类型为[25 * i8]*的指向该字符串指针。后两个参数都为0,表示取该指针指向的第一个聚合类型（即该字符串）的第一个字符的地址。
```
operand tmp1 = vp.getelementptr(fmt_type, fmt_addr, int_value(0), int_value(0), INT8_PTR);
```
然后，产生一条call指令调用printf函数，其第一个参数是上面步骤中得到的首地址，第二个参数是调用Main_main函数得到的返回值。
```
vp.call(printf_argtypes, op_type(INT32), "printf", true, printf_args);
```
2. 除0错误处理。为了实现除0错误处理，需要在Main_main()方法内部的ret语句之后定义一个"abort"基本块。该基本块在程序正常执行时是不可达的，只有检测到除数为0时才会跳转到这儿。在为除法表达式生成代码之前，先用一条比较指令将除数与0比较，再跟着一条条件转移指令，如果除数等于0，则转移到abort基本块。
```
operand z = vp.icmp(EQ, op2, int_value(0));
vp.branch_cond(z, "abort", "not_zero");
```
在abort基本块中，调用预先设置的abort函数。
```
vp.begin_block("abort");
vector<op_type> abort_args_types;
vector<operand> abort_args;
operand ab_call = vp.call(abort_args_types, VOID, "abort", true, abort_args);
vp.unreachable();
```
3. let语句代码生成。let是MP2中唯一涉及到Object的语句，涉及到定义变量及其存储位置，以及存取变量的值等操作。在let表达式中定义一个变量时，先用alloca_mem()方法生成一条alloca指令，为其分配存储空间，然后在environment中注册该变量的标识符与存储位置间的关联。最后，生成一条store语句，将变量的值（可能由初始化表达式计算得到，也可能是默认值）存到地址中。
```
// alloc memory for id
operand idaddr = vp.alloca_mem(type);
// bind variable name to memory location
env->add_local(identifier, idaddr);
// store init value into idaddr
if(initval.get_type().get_id() == EMPTY){
		if(type.get_id() == INT1)
			vp.store(bool_value(false, true), idaddr);
		else if(type.get_id() == INT32)
			vp.store(int_value(0), idaddr);
}
else
		vp.store(initval, idaddr);
```
    为了实现let语句，还要实现Object表达式的代码生成，即在使用一个变量之前，在environment中查找该变量的存储位置，并用一条load指令取出它的值。
4. if语句的代码生成。在LLVM中比较规范的处理方式是用一条phi指令合并then分支和else分支的值，但所给的框架中并不支持phi指令。
    在这里我采用了参考程序的做法。在参考程序中，then分支和else分支中得到的值被存储到栈上分配的一个区域，然后在分支结束后从该区域取出值。在分配存储区域时先要获得变量的类型信息，这可以通过then_exp或else_exp中的get_type()方法获得。
```
// alloca memory for return value
operand valaddr = vp.alloca_mem(type);
vp.branch_cond(cond, label_true, label_false);
```
```
vp.begin_block(label_true);
operand then_val = then_exp->code(env);
vp.store(then_val, valaddr);
vp.branch_uncond(label_end);
```
```
vp.begin_block(label_false);
operand else_val = else_exp->code(env);
vp.store(else_val, valaddr);
vp.branch_uncond(label_end);
```
```
vp.begin_block(label_end);
return vp.load(type, valaddr);
```

####三、遇到的问题与解决方法
* 起初在生成if表达式的代码时，我试图用一条select语句，根据条件成立与否，从then分支和else分支得到的结果中选择其中之一。这样做在编译到可执行文件时报错"Instruction does not dominate all uses"，即if或else分支中定义的变量没有支配对该变量的使用。因此我仍然改用了reference中的做法。
* 为了让同一个if或while表达式中的标号有相同的后缀，我稍微修改了CgenEnvironment类，在其中增加一个属性suff_count。在生成一个标号时，将suff_count而不是block_count作为后缀。为整个if或while表达式生成所有标号后，才将suff_count加1。
* 由于LLVM的规定，一个基本块必须以return语句或branch语句结束，因此在进入第一个循环判断条件基本块之前要加一条无条件转移指令，转移到该基本块。我起初没意识到这个问题，导致汇编到字节码时出错。
* 框架中没有提供生成求相反数和not表达式的接口，因此用“0-源操作数”的方法求相反数，用“与true异或”的方法求逻辑非。

####四、参考文献
LLVM Language Reference
UIUC MP2文档
Kaleidoscope教程
https://github.com/CharlieMartell/Compiler-Construction/blob/master/mps/mp3/src/cgen.cc
（借鉴了一下，但我的实现比他优雅）