# Neovim Scripts

This directory contains helper scripts for Neovim integrations.

## bazel-jdtls-classpath

Extracts classpath information from Bazel for jdtls (Java LSP).

**Location:** `~/.config/nvim/scripts/bazel-jdtls-classpath`
**Symlink:** `~/.local/bin/bazel-jdtls-classpath` (for easy CLI access)

### Usage

```bash
# Extract classpath for specific domains
bazel-jdtls-classpath //domains/event-platform/...

# Extract for multiple domains
bazel-jdtls-classpath //domains/event-platform/... //domains/event-store/...
```

### How It Works

1. Queries Bazel for Java targets and dependencies
2. Extracts all JAR files (compiled code + external deps)
3. Finds all source directories (src/main/java, generated sources, etc.)
4. Writes to `~/.cache/jdtls-bazel/`:
   - `classpath.txt` - all JARs
   - `sources.txt` - all source paths
5. jdtls config in `lua/custom/plugins/jdtls.lua` reads these files

### When to Run

- After pulling changes
- After modifying dependencies in BUILD files
- When proto definitions change
- When starting work on a new domain

### Setup

The script is already symlinked to `~/.local/bin/` so it's in your PATH.

If you need to re-create the symlink:
```bash
ln -sf ~/.config/nvim/scripts/bazel-jdtls-classpath ~/.local/bin/bazel-jdtls-classpath
```

See `README-bazel-jdtls.md` for detailed usage and troubleshooting.
