class A {
	a : INT <- 10;
	d : INT;
	m1(b : STRING, c : BB__) : BOOL
	{
		{
			a <- 20;
			d <- d * a;
		}
	};
	m2(b : INT) : SELF_TYPE
	{
		{
			(let b1 : INT <- 17,
			     b2 : INT
			 in b1 + b2 * 5
			);
		}
	};
};

Class BB__ inherits A {
};
