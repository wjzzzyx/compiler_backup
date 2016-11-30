#include <stdio.h>
int main()
{
    FILE *fp;
    fp = fopen("foo.txt", "r");
    for(int i = 0;i < 1000;i++)
        fprintf(fp, "a");
    return 0;
}
