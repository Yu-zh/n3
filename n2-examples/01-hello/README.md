# Example 1: Hello World

## What This Demonstrates
- Basic `rule` and `build` syntax
- Variable expansion (`$name`, `$out`)
- Overriding rule commands in build statements
- Input/output dependencies
- `default` target

## Run It
```bash
# Build with n2 (or ninja)
n2

# Clean and rebuild
rm -f *.txt
n2

# Build specific target
n2 hello.txt

# See what n2 would build
n2 -n
```

## What Happens
1. Creates `hello.txt` with "Hello from Ninja Build System!"
2. Creates `world.txt` with "Hello from n2!"
3. Combines both into `combined.txt`

## Experiment
- Modify `hello.txt` manually and run `n2` - only `combined.txt` rebuilds
- Touch one file: `touch hello.txt && n2` - watch n2 detect the change
