fib-m: fib.s
	gcc fib-m.s -o fib-m
fib.s: fib-m.ll
	llc fib-m.ll
clean:
	rm fib-m fib-m.s
