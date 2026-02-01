# Example 4: Pools and Parallelism

## What This Demonstrates
- **Pools**: Controlling parallelism for different types of tasks
- **depth**: Maximum concurrent tasks in a pool
- **console pool**: Sequential execution for interactive commands
- **Custom pools**: Resource management (e.g., limiting memory-heavy tasks)

## Pool Types

### 1. Default Pool (unlimited)
Fast compilation tasks run without restriction. With `-j8`, all 4 fast tasks run simultaneously.

### 2. Heavy Pool (depth = 2)
Heavy compilation limited to 2 concurrent tasks, even with `-j8`. Simulates:
- Memory-intensive linking
- Resource-constrained operations
- License-limited tools

### 3. Console Pool (depth = 1)
Interactive tasks run one at a time. Used for:
- Tasks needing stdin/stdout
- Interactive prompts
- Serial logging

## Run It
```bash
# Build with high parallelism
n2 -j8

# Watch the output - you'll see:
# - All 4 fast_compile tasks start immediately
# - Only 2 heavy_compile tasks run at once
# - Interactive tasks run one by one
```

## Observe the Behavior

### Terminal 1 - Watch n2's fancy progress:
```bash
time n2 -j8
```

You'll see the progress bar showing:
- Fast tasks complete quickly (~0.5s each)
- Heavy tasks take longer (~2s each), but only 2 at a time
- Interactive tasks are sequential

### Check timing:
```bash
# With parallelism
time n2 -j8
# vs without
rm -f *.o *.txt
time n2 -j1
```

## Real-World Use Cases

### 1. Heavy Pool
```ninja
pool link_pool
  depth = 2

rule link
  command = ld $in -o $out
  pool = link_pool  # Limit concurrent links (memory intensive)
```

### 2. Console Pool
```ninja
rule run_tests
  command = ./run_test.sh $in
  pool = console  # Interactive test output
```

### 3. Network Pool
```ninja
pool download_pool
  depth = 4

rule download
  command = curl $url -o $out
  pool = download_pool  # Don't overwhelm network
```

## Experiment

1. **See pool enforcement**:
   ```bash
   # Even with -j100, heavy tasks respect pool depth
   n2 -j100
   ```

2. **Watch the state machine**:
   With n2's fancy progress, watch how tasks queue up when pool is full.

3. **Modify pool depth**:
   Change `depth = 2` to `depth = 1` in build.ninja and rebuild:
   ```bash
   n2 -j8
   # Now only 1 heavy task runs at a time
   ```

## Why Pools Matter

In real builds:
- **Linking**: Very memory-intensive, limit concurrent linkers
- **Testing**: May need database locks, run serially
- **Code generation**: May use license-limited tools
- **Downloads**: Respect server rate limits

Pools let you balance parallelism with resource constraints!
