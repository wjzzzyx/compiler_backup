class A {
    int a;
public:
    int geta(int k, char p) { return a + k; }
};

class B : virtual public A {
    int b;
public:
    int getb() { return b; }
};

class C : virtual public A {
    int c;
public:
    int getc() { return c; }
};

class D : public C {
public:
    int d;
    int getd() { return d; }
};

int main()
{
    A aa;
    B bb;
    C cc;
    D dd;
    int e;
    e = aa.geta(1, 2) + bb.getb() + dd.geta(1, 2);
    return 0;
}
