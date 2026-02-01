# Example 6: Response Files (rspfile)

## What This Demonstrates
- **Response files**: Handling long command lines
- **`rspfile`** and **`rspfile_content`** attributes in Ninja
- **Why they matter**: Avoiding "Argument list too long" errors
- **When to use**: Large projects with 100+ files, Windows builds, static libraries

## The Problem

Operating systems limit command line length:
- **Windows**: 8,191 characters (very restrictive!)
- **Linux/macOS**: 2MB (usually fine, but can still hit limits)

Large projects can exceed these limits:
```bash
# This could fail on Windows with 100+ files!
gcc -o program obj1.o obj2.o obj3.o ... obj100.o
```

## The Solution: Response Files

Instead of passing arguments directly:
```bash
gcc -o program file1.o file2.o file3.o ... (too long!)
```

Write arguments to a file and reference it:
```bash
echo "file1.o file2.o file3.o ..." > args.rsp
gcc -o program @args.rsp
```

The `@filename` syntax tells the compiler to read arguments from that file.

## How It Works in Ninja

Look at the linker rule in `build.ninja`:

```ninja
rule link
  command = gcc -o $out @$out.rsp
  rspfile = $out.rsp
  rspfile_content = $in -lm
```

**Breakdown**:
1. **`rspfile = $out.rsp`** - Where to write the response file
2. **`rspfile_content = $in -lm`** - What to put in it (all inputs + flags)
3. **`@$out.rsp`** - Reference in the command

**What n2 does**:
1. Before running `gcc`, n2 creates `program_rsp.rsp` containing all object files and flags
2. Runs `gcc -o program_rsp @program_rsp.rsp`
3. The linker reads the file list from the response file

**Platform Note**: macOS's BSD `ar` doesn't support `@file` syntax, but GNU ar (Linux) and all modern compilers/linkers (gcc, clang, MSVC) do support it. This example uses response files for linking, which works everywhere.

## Run It

### Build the project:
```bash
n2
```

### Run the program:
```bash
./program_rsp
```

Output:
```
=== Response File Demo ===
This program was built using response files!
Check libmath.a.rsp and program_rsp.rsp to see them.
------------------------
Computing with a=20, b=7:
  a + b = 27
  a - b = 13
  a * b = 140
  a / b = 2
  a % b = 6
------------------------
Build system: n2
Response files prevent 'Argument list too long' errors!
```

### Inspect the generated response file:
```bash
# See what went into the linker
cat program_rsp.rsp
```

You'll see something like:
```
obj/main.o obj/utils1.o obj/utils2.o obj/utils3.o libmath.a -lm
```

Notice it contains:
- All object files to link
- The static library
- Any linker flags (-lm for math library)

## Compare: With vs Without Response Files

This example builds the program two ways:

### With response file:
```ninja
rule link
  command = gcc -o $out @$out.rsp
  rspfile = $out.rsp
  rspfile_content = $in -lm

build program_rsp: link obj/main.o obj/utils1.o ...
```

### Without response file:
```ninja
rule link_direct
  command = gcc -o $out $in -lm

build program_direct: link_direct obj/main.o obj/utils1.o ...
```

Both work for small projects, but the response file version scales to thousands of files!

## Experiments

### 1. See the response files:
```bash
n2
ls -la *.rsp

# Inspect them
cat libmath.a.rsp
cat program_rsp.rsp
```

### 2. Verify the commands:
```bash
# Run n2 with verbose output to see actual commands
n2 -v
```

You'll see:
```
ar rcs libmath.a @libmath.a.rsp
gcc -o program_rsp @program_rsp.rsp
```

### 3. Test the response file manually:
```bash
# Expand the response file manually
gcc -o test_manual $(cat program_rsp.rsp)
./test_manual  # Should work the same
```

### 4. Compare file sizes:
```bash
# Response file is tiny
ls -lh libmath.a.rsp

# But it represents many files
cat libmath.a.rsp | wc -w  # Count files listed
```

### 5. Simulate a large project:
Edit `build.ninja` and imagine having 1000 object files instead of 9. The command line would be:
```
gcc -o program obj1.o obj2.o ... obj1000.o
```

That's easily **50,000+ characters** on Windows - would fail without response files!

## When to Use Response Files

### ✅ Use rspfile when:
1. **Linking** large projects (100+ object files)
2. **Archiving** static libraries (many .o files)
3. **Building on Windows** (strict 8KB limit)
4. **Cross-platform** builds (ensures it works everywhere)
5. **Generated code** (auto-generated files, often many)

### ❌ Not needed when:
1. Small projects (< 20 files)
2. Single-file builds
3. Running shell scripts (not compiler commands)

## Real-World Usage

Look at any large CMake project that generates Ninja files:

```bash
# Example from Chromium, LLVM, etc.
cat build.ninja | grep rspfile
```

You'll see hundreds of response files used for:
- Linking executables
- Creating static libraries
- Compiling with many include paths
- Passing many defines

## Built-in Variables

Ninja provides special variables for response files:

| Variable | Description |
|----------|-------------|
| `$in` | Space-separated inputs |
| `$in_newline` | Newline-separated inputs (safer) |
| `$out` | Space-separated outputs |
| `$out_newline` | Newline-separated outputs |

### Example with newlines:
```ninja
rule link
  command = gcc -o $out @$out.rsp
  rspfile = $out.rsp
  rspfile_content = $in_newline
  # Uses newlines instead of spaces (handles paths with spaces better)
```

## Response File Hashing

Important: n2 includes response file **content** in the build hash!

From `n2/src/hash.rs`:
```rust
if let Some(rspfile) = &build.rspfile {
    manifest.write_rsp(rspfile);  // Hash the content
}
```

**This means**:
- Changing `rspfile_content` → triggers rebuild ✓
- Changing library list → triggers relink ✓
- Changing compiler flags in rsp → triggers recompile ✓

## Clean Up

Response files persist after the build:

```bash
# They're left on disk for debugging
ls *.rsp

# Clean them up
rm -f *.rsp

# Or add to clean target in build.ninja:
build clean: phony
  command = rm -f obj/*.o *.a *.rsp program_*
```

## Platform Differences

### Linux/macOS:
- Generous limits (2MB)
- Response files still helpful for very large projects
- Primarily for Windows compatibility

### Windows:
- **CRITICAL**: 8,191 character limit
- Response files are **essential** for any non-trivial project
- CMake automatically generates them for Windows builds

## Tool Support

Response files work with:

✅ **GCC/G++**: `@file` syntax
✅ **Clang**: `@file` syntax
✅ **MSVC**: `@file` syntax
✅ **GNU ar**: `@file` for archiving
✅ **GNU ld**: `@file` for linking
✅ **lld**: `@file` (LLVM linker)

Basically all modern compilers and linkers support it!

## Historical Note

Response files date back to **MS-DOS** where command lines were limited to 128 characters! They've been a staple of build systems ever since.

## Further Reading

- **Ninja manual**: Search for "rspfile" at https://ninja-build.org/manual.html
- **GCC docs**: https://gcc.gnu.org/onlinedocs/gcc/Overall-Options.html
- **See**: `../RESPONSE_FILES.md` for detailed explanation
- **n2 source**: `n2/src/task.rs` - search for `write_rspfile`

---

**Key Takeaway**: Response files are Ninja's solution to command line length limits. They're transparent, automatic, and essential for large-scale builds, especially on Windows!
