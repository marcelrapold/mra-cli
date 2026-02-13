# Module Development Guide

> How to create, structure, and register custom ÆON CLI modules.

## Quick Start

Create a new module in 60 seconds:

```bash
mkdir -p modules/hello
cat > modules/hello/module.sh << 'EOF'
#!/usr/bin/env bash
# @desc Say hello from AEON

mod_hello_main() {
    echo -e "${C}Hello from ÆON!${N}"
}
EOF
```

Done. Run it: `aeon hello`

## Module Structure

```
modules/<name>/
├── module.sh          # REQUIRED — Module entry point
├── *.sh               # Optional helper scripts
└── <resources>/       # Optional data files, configs, etc.
```

## Conventions

### Entry Point

Every module MUST:

1. Have a `module.sh` file
2. Define `mod_<name>_main()` function
3. Include `# @desc <description>` comment (shown in `aeon --help`)

### Available Context

When your module loads, these are already sourced:

| Variable/Function | Source | Description |
|-------------------|--------|-------------|
| `$RCLI_VERSION` | `aeon` | CLI version string |
| `$RCLI_ROOT` | `aeon` | Install directory |
| `$RCLI_PROFILE` | `detect.sh` | Current resolution profile |
| `$RCLI_CONFIG_DIR` | `config.sh` | Config directory (`~/.rapoldio/`) |
| `log_info`, `log_error` | `core.sh` | Logging functions |
| `$C`, `$W`, `$G`, etc. | `core.sh` | ANSI color codes |
| `config_get()` | `config.sh` | Read config values |
| `box_line()`, `box_top()` | `core.sh` | Box drawing helpers |

### Command Routing

Use a case statement for subcommands:

```bash
mod_mymod_main() {
    local cmd="${1:-default}"
    shift 2>/dev/null || true

    case "$cmd" in
        default|show)  do_show "$@" ;;
        create)        do_create "$@" ;;
        --help|-h)     show_help ;;
        *)             log_error "Unknown: $cmd"; show_help ;;
    esac
}
```

### Using SSH

For remote-capable modules, source `ssh.sh`:

```bash
mod_mymod_main() {
    source "$RCLI_LIB/ssh.sh"
    gateway_exec "uptime"
}
```

## Testing

Run ShellCheck on your module:

```bash
shellcheck modules/mymod/module.sh
```

## Examples

See the built-in modules for reference patterns:

- **Simple:** `modules/status/module.sh` — Status display with subcommands
- **Complex:** `modules/dashboard/module.sh` — tmux orchestration with profiles
- **Remote:** `modules/deploy/module.sh` — SSH-based fleet operations
- **Interactive:** `modules/config/module.sh` — Config management with user input
