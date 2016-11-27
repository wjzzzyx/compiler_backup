int main()
{
    int a[5];
    int max = 0;
    for(int i = 0;i < 5;i++)
	    a[i] = i;
    if(a[3] > max)
        max = a[3];
    else
        max = a[2];
    return 0;
}
