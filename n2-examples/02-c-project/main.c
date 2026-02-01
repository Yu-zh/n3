#include <stdio.h>

int add(int a, int b);
void print_banner(const char* msg);

int main() {
    print_banner("n2 Build Example");

    int result = add(5, 7);
    printf("5 + 7 = %d\n", result);

    printf("Build successful!\n");
    return 0;
}
