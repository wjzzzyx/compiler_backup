#include <stdio.h>
int main()
{
    FILE *fp1 = fopen("foo.txt", "r");
    FILE *fp2 = fopen("aaa.txt", "w");
    char buffer[10];
    if(fp1)
        fprintf(fp1, "a");
    if(fp2)
        fread(buffer, 2, 2, fp2);
    fclose(fp1);
    fclose(fp2);
    return 0;
}
