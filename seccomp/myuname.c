#include <stdio.h>
#include <sys/utsname.h>

int main(int argc, char* argv[]) {
    puts("Hello world");
    
    struct utsname unameData;
    uname(&unameData);
    printf("%s \n", unameData.sysname);

    return 0;
}