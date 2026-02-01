# Example 3: Dependency Files (Dynamic Dependencies)

## What This Demonstrates
- **Depfiles**: Automatic header dependency tracking
- **Dynamic dependencies**: Dependencies discovered during compilation
- **gcc -MMD**: Compiler-generated dependency information
- How n2 tracks header file changes

## How It Works
1. GCC's `-MMD -MF $out.d` generates a `.d` file listing all headers each .c file includes
2. The `depfile = $out.d` line tells n2 to read this file
3. n2 automatically tracks header changes - modify a .h file, relevant .c files rebuild

## Run It
```bash
# Initial build
n2

# Run the program
./calculator

# Now modify the header file
echo "// Updated" >> geometry.h

# Rebuild - n2 knows to rebuild main.o and geometry.o!
n2

# Check the generated depfile
cat main.o.d
# You'll see: main.o: main.c geometry.h
```

## The Magic
Without depfiles, you'd have to manually specify in build.ninja:
```
build main.o: cc main.c geometry.h
```

With depfiles, the compiler discovers this dependency automatically!

## Experiment
1. **Change a header**:
   ```bash
   # Change PI value in geometry.h
   n2  # Automatically rebuilds files that include it
   ```

2. **Add a new include**:
   ```bash
   # Add `#include <math.h>` to geometry.c
   n2  # Depfile automatically updated
   ```

3. **Inspect the dependency file**:
   ```bash
   cat geometry.o.d
   # Shows all headers geometry.c depends on
   ```

## Why This Matters
This is how real build systems (CMake, Meson, etc.) track C/C++ header dependencies without manual maintenance. The compiler knows what it includes, so it tells the build system!
