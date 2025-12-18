# Tool Configurations

This folder contains recommended configurations for optional CLI tools.

## How It Works

When you install a tool via the installer, the corresponding config file is copied to your system:

| Tool | Source | Destination |
|------|--------|-------------|
| Starship | `tools/starship.toml` | `~/.config/starship.toml` |
| Atuin | `tools/atuin.toml` | `~/.config/atuin/config.toml` |

**If you already have a config**, it will be backed up before copying (e.g., `starship.toml.backup`).

## Customization

### Option 1: Edit the Installed Config (Recommended)
After installation, edit the config at its destination:
```bash
# Starship
nano ~/.config/starship.toml

# Atuin
nano ~/.config/atuin/config.toml
```

### Option 2: Use Your Own Config
If you prefer your own config, simply restore from backup:
```bash
mv ~/.config/starship.toml.backup ~/.config/starship.toml
```

Or skip tool config installation by using `--skip-tools` and installing tools manually.

## Tool Documentation

- **Starship**: [starship.rs/config](https://starship.rs/config/)
- **Atuin**: [docs.atuin.sh](https://docs.atuin.sh/)
