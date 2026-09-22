#include <stdio.h>
int Get_Script_Count();
char * Get_Script_Name(int scrnum);
char * Get_Script_Param_Description(int scrnum);
int i,j;
int main()
{
i = Get_Script_Count();
for (j=0;j<i;j++)
{
printf("%s ",Get_Script_Name(j));
printf("%s\n",Get_Script_Param_Description(j));
}
}

