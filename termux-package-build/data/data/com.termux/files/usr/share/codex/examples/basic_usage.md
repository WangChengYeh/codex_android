# Android Codex Examples

## Basic Usage
```bash
# System analysis
codex exec "Analyze this Android system and show hardware info"

# Code generation
codex exec "Create a shell script to monitor system resources"

# File operations (with write permissions)
codex exec --sandbox workspace-write "Create a test configuration file"
```

## Advanced Usage
```bash
# Skip git repo check (useful in non-git directories)
codex exec --skip-git-repo-check "Your prompt here"

# Different sandbox modes
codex exec --sandbox read-only "Safe read-only operations"
codex exec --sandbox workspace-write "Operations that need file access"
```
