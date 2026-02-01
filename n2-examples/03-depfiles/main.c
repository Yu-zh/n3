#include <stdio.h>
#include "geometry.h"

int main() {
    printf("Circle Area Calculator\n");
    printf("======================\n\n");

    double radius = 5.0;
    double area = circle_area(radius);

    printf("Radius: %.2f\n", radius);
    printf("Area: %.2f\n", area);

    return 0;
}
