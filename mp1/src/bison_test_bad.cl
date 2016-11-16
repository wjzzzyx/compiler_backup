(*
(*
 *  execute "coolc bad.cl" to see the error messages that the coolc parser
 *  generates
 *
 *  execute "myparser bad.cl" to see the error messages that your parser
 *  generates
 *)
(* no error *)
class A {
};

(* error:  b is not a type identifier *)
Class b inherits A {
};

(* error:  a is not a type identifier *)
Class C inherits a {
};

(* error:  keyword inherits is misspelled *)
Class D inherts A {
};

(* error:  closing brace is missing *)
Class E inherits A {
;
*)

class a{
	a : INT <- 10,10;
	d : INT;
	m1(b : STRING, c : BB__ jump) : BOOL
	{
		{
			a <- 20;
			d <- d * a;
			f.test(abc, abc,);
			if : then 2 else 3 fi;
			
		}
	};
	m2(b : INT) : SELF_TYPE
	{
		{
			(let b1 : INT <- 17,
			     b2 : INT
			 in b1 + b2 * 5
			);
			(b5 <- 1);
			case 1 of 
				b6 : b7 => 1, 2;
			esac;
			self;
		}
	};
};

Class Ab 

Class BB__ eeinherits A {
	bba : SELF_TYPE;
	getbba(n : Main) : SELF_TYPE {
		bba
	};
};

Class Main inherits IO {
	a : A;
	bb : BB__;
	s : STRING;
	main() : BB__ {
		{
			if isvoid a.m1("wander", new BB__) then
				b <- (new BB__).getbba(self)
			else
				while a.m1("abc", bb) loop
					a.m2(5)
				pool@IO.in_int()
			fi;
			a <- new A;
			s <- "block";
			let f : F(*,*) g : G, h : A <- a (*in*) 
				case f.test(g.test(h.m2(34))) of
					a : Main => if isvoid a.m1("wander", new BB__) then
									b <- (new BB__).getbba(self)
								else
									isvoid case main() of
										i : Int => let
														j : 
														J,
														k :
														K
														in
														~j / k
										;
									esac
								fi;
					bb : A => expr;
					s : BB__ => expr;
				esac
				+
				main()
			;
		}
	};
}(*;*)

