# Example 2: C Project

## What This Demonstrates
- Real C compilation workflow
- Multiple source files
- Separate compilation and linking steps
- Variable usage (`$cc`, `$cflags`)
- Dependency tracking (changing a .c file rebuilds only what's needed)

## Run It
```bash
# Build the project
n2

# Run the program
./program

# Clean and rebuild
rm -f *.o program
n2

# Watch incremental builds - modify one file
echo "// comment" >> math.c
n2  # Only rebuilds math.o and program, not main.o or utils.o

# Build with different compiler flags
n2 --explain  # See why things are being rebuilt
```

## Observe n2's Features
1. **Incremental builds**: Change only `math.c`, see that only `math.o` and `program` rebuild
2. **Parallel compilation**: With `-j4`, n2 compiles .c files in parallel
3. **Smart dependency**: Touch a .o file, see that linking happens but no recompilation

## Experiment
```bash
# Parallel build (faster on multi-core)
n2 -j4

# See build trace
n2 -d trace
# Then open chrome://tracing in Chrome and load the trace file

# Explain why rebuilding
touch main.c
n2 --explain
```
