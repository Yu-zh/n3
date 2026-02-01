#include <stdio.h>

// Math functions from libmath.a
int add(int a, int b);
int subtract(int a, int b);
int multiply(int a, int b);
int divide(int a, int b);
int modulo(int a, int b);

// Utility functions
void print_header(const char* title);
void print_separator();
void print_result(const char* op, int result);

int main() {
    int a = 20, b = 7;

    print_header("Response File Demo");
    printf("This program was built using response files!\n");
    printf("Check libmath.a.rsp and program_rsp.rsp to see them.\n");

    print_separator();
    printf("Computing with a=%d, b=%d:\n", a, b);

    print_result("a + b", add(a, b));
    print_result("a - b", subtract(a, b));
    print_result("a * b", multiply(a, b));
    print_result("a / b", divide(a, b));
    print_result("a % b", modulo(a, b));

    print_separator();
    printf("Build system: n2\n");
    printf("Response files prevent 'Argument list too long' errors!\n");

    return 0;
}
