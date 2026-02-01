# Example 5: Phony Targets and Order-Only Dependencies

## What This Demonstrates
- **Phony targets**: Virtual targets that don't correspond to files
- **Order-only dependencies**: Dependencies that must exist but don't trigger rebuilds
- **Build organization**: Grouping related targets
- **Clean targets**: Removing build artifacts

## Key Concepts

### 1. Phony Targets
Phony targets are virtual - they don't create actual files. They're used to:
- Group related targets (`all`, `test`, `clean`)
- Create convenient aliases
- Define commands without outputs

```ninja
build clean: phony
  command = rm -f *.o
```

### 2. Order-Only Dependencies
Syntax: `build output: rule inputs | order-only-deps`

The `|` separates regular from order-only dependencies:
- **Regular deps**: If they change (newer mtime), rebuild
- **Order-only deps**: Must exist, but changes don't trigger rebuild

Example: Directory creation
```ninja
build output_dir/.created: ...
build output_dir/file.o: cc file.c | output_dir/.created
```

`file.o` needs the directory to exist, but touching the directory won't rebuild `file.o`.

## Run It

### Basic usage:
```bash
# Build default target (all)
n2

# Build specific phony target
n2 data          # Just build data files
n2 processed     # Just build processed files
n2 outputs       # Build outputs in directory

# Clean
n2 clean

# Rebuild everything
n2 clean && n2 all
```

### Observe order-only dependencies:
```bash
# Build outputs (creates directory)
n2 outputs

# Touch the directory marker
touch output_dir/.created

# Rebuild - notice output files DON'T rebuild
n2 outputs
# No work needed!

# But if you touch actual input:
touch data1.txt
n2 outputs
# Now output_dir/final1.txt rebuilds
```

## Understand the Difference

### Regular dependency:
```ninja
build output.o: cc input.c header.h
```
If `header.h` changes → rebuild `output.o` ✓

### Order-only dependency:
```ninja
build output.o: cc input.c | directory_marker
```
If `directory_marker` changes → DON'T rebuild `output.o` ✗
But `directory_marker` must exist before building ✓

## Real-World Use Cases

### 1. Directory Creation
```ninja
build obj/.created: phony
  command = mkdir -p obj && touch $out

build obj/file.o: cc file.c | obj/.created
# Directory must exist, but touching it won't trigger recompile
```

### 2. Configuration Files
```ninja
build config.h: generate_config
build main.o: cc main.c | config.h
# config.h must exist before compile, but timestamp doesn't matter
```

### 3. Tool Building
```ninja
build bin/codegen: link codegen.o
build generated.c: run_codegen src.def | bin/codegen
# Codegen tool must exist, but rebuilding it doesn't regenerate code
# (unless you want it to - then make it a regular dependency!)
```

### 4. Phony Task Groups
```ninja
build test: phony unit_tests integration_tests
build unit_tests: phony test1 test2 test3
build integration_tests: phony int_test1 int_test2

# Now `n2 test` runs all tests
# `n2 unit_tests` runs only unit tests
```

## Experiment

1. **Test order-only semantics**:
   ```bash
   n2 outputs
   # Touch order-only dep
   touch output_dir/.created
   n2 outputs    # No rebuild

   # Touch regular dep
   touch data1.txt
   n2 outputs    # Rebuilds final1.txt only
   ```

2. **Use phony targets**:
   ```bash
   n2 data       # Build just data files
   n2 processed  # Build just processed files
   n2 all        # Build everything
   ```

3. **Clean and rebuild**:
   ```bash
   n2 clean
   ls *.txt      # All gone
   n2            # Rebuild from scratch
   ```

## Common Patterns

### Makefile-style targets:
```ninja
build all: phony main tests docs

build clean: phony
  command = rm -rf build/

build install: phony all
  command = cp build/bin/* /usr/local/bin/

build test: phony tests
  command = ./run_tests.sh
```

### Forced rebuilds:
```ninja
# Always rebuild (phony has no actual file)
build force: phony

build always_rebuild.txt: generate | force
# This will always rebuild because 'force' is always out of date
```

This pattern is useful for version stamps, timestamps, etc.
