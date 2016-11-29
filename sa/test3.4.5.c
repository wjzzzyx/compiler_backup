#include <stdio.h>
int main()
{
    FILE *fp1 = NULL, *fp2 = NULL, *fp3 = NULL;
    fp1 = fopen("test.txt", "w");
    if(fp1){
        fclose(fp1);
        fprintf(fp1, "hello\n");
    }
    fprintf(fp2, "world\n");
    fclose(fp3);
}
