#include <stdio.h>

class A {
public:
    int a;
};
class B: public A {
public:
    int b;
};
class C: public A {
public:
    int c;
};
class D: public B, public C {
public:
    int d;
};

class E {
public:
    int e;
};
class F: virtual public E {
public:
    int f;
};
class G: virtual public E {
public:
    int g;
};
class H: public F, public G {
public:
    int h;
};

int main()
{
    D d;
    printf("multiple inheritence\n");
    printf("address:\n");
    printf("d.B::a : %ld\nd.b : %ld\nd.C::a : %ld\nd.c : %ld\nd.d : %ld\n", (long)&d.B::a, (long)&d.C::a, (long)&d.b, (long)&d.c, (long)&d.d);
    H h;
    printf("%ld", (long)&h);
    printf("virtual inheritance\n");
    printf("address:\n");
    printf("h.F::e : %ld\nh.G::e : %ld\nh.f : %ld\nh.g : %ld\nh.h : %ld\n", (long)&h.F::e, (long)&h.G::e, (long)&h.f, (long)&h.g, (long)&h.h);
    return 0;
}
    
