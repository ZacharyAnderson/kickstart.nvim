# Bazel + jdtls Integration

This setup configures jdtls to work with Bazel projects by extracting classpath information directly from Bazel.

## Quick Start

1. **Extract classpath for your domain:**
   ```bash
   cd /path/to/logs-backend
   bazel-jdtls-classpath //domains/event-platform/...
   ```

2. **Open nvim:**
   ```bash
   nvim domains/event-platform/libs/topology/src/main/java/YourFile.java
   ```

3. **jdtls will automatically use the extracted classpath!**

## Commands

### Extract classpath for specific domains:
```bash
# Just event-platform
bazel-jdtls-classpath //domains/event-platform/...

# Multiple domains
bazel-jdtls-classpath //domains/event-platform/... //domains/event-store/...

# Everything (slow!)
bazel-jdtls-classpath //...
```

### Check what was extracted:
```bash
# View classpath (all JARs)
cat ~/.cache/jdtls-bazel/classpath.txt

# View sources (all source directories)
cat ~/.cache/jdtls-bazel/sources.txt

# Count
wc -l ~/.cache/jdtls-bazel/*.txt
```

## When to Re-run

Run `bazel-jdtls-classpath` again when:
- ✅ You add new dependencies to BUILD files
- ✅ You pull changes that modify dependencies
- ✅ Proto definitions change (generates new sources)
- ✅ You start working on a new domain

## Shell Alias (Recommended)

Add to your `.zshrc` or `.bashrc`:
```bash
alias bjc='bazel-jdtls-classpath'
```

Then just run:
```bash
bjc //domains/event-platform/...
```

## Automation (Optional)

### Auto-refresh on git pull:
Add to `.git/hooks/post-merge`:
```bash
#!/bin/bash
echo "Refreshing jdtls classpath..."
bazel-jdtls-classpath //domains/event-platform/... &
```

Make it executable:
```bash
chmod +x .git/hooks/post-merge
```

## How It Works

1. `bazel-jdtls-classpath` queries Bazel for:
   - All Java targets in the specified pattern
   - All JAR dependencies (including transitive)
   - All source directories

2. Writes to `~/.cache/jdtls-bazel/`:
   - `classpath.txt` - all JAR files
   - `sources.txt` - all source directories

3. jdtls config in nvim reads these files and configures:
   - `referencedLibraries` - so jdtls knows about dependencies
   - `sourcePaths` - so jdtls can find your sources and generated code

## Troubleshooting

### No autocomplete/errors?
```bash
# Re-extract classpath
bazel-jdtls-classpath //domains/your-domain/...

# Restart nvim
:qa
nvim your-file.java
```

### Missing generated sources (proto)?
```bash
# Build first to generate sources
bzl build //domains/your-domain/...

# Then extract
bazel-jdtls-classpath //domains/your-domain/...
```

### Slow?
```bash
# Only extract what you need
bazel-jdtls-classpath //domains/event-platform/libs/topology:topology

# Instead of
bazel-jdtls-classpath //...  # <- don't do this
```
