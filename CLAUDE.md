# Project Guidelines

## Commits

- **Never include `Co-Authored-By` lines in commit messages.** No Claude co-authorship attribution.

## Mise Tool Management

- **Always verify a tool exists in the mise registry before adding it to `dot_config/mise/config.toml`.**
  Run `mise registry | grep -i <tool>` to confirm availability and get the correct package name.
- If a tool isn't in the registry, inform the user rather than guessing at package names.

## Dotfiles Repository

- **All tool installations and configuration changes must be made in the dotfiles repo (`~/dotfiles`)**, not directly on the system.
- Use chezmoi to apply changes from the dotfiles repo to the local system.
