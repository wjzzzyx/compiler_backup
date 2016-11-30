#include <stdio.h>
int main()
{
    FILE *fp1, *fp2;
    fp1 = fopen("foo1.txt", "r");
    fp2 = fopen("foo2.txt", "r");
    fprintf(fp2, "a");
    fclose(fp1);
    return 0;
}
