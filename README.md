# dotfiles

Reproducible dev environment using [chezmoi](https://www.chezmoi.io/) + [mise](https://mise.jdx.dev/). Sensitive files (AWS credentials) are encrypted with [age](https://age-encryption.org/).

## One-Command Bootstrap

```bash
curl -fsSL https://raw.githubusercontent.com/JayHennessy/dotfiles/main/install.sh | bash
```

This installs chezmoi, clones this repo, **prompts for your age passphrase** to decrypt AWS credentials, installs all tools, and applies all configs. Supports Debian/Ubuntu, Fedora, RHEL, and Amazon Linux.

## What Gets Installed

### Via mise (29 tools)

Python, Node.js, Bun, Go, GitHub CLI, AWS CLI, Google Cloud SDK, Terraform, s5cmd, DuckDB, uv, k9s, lazygit, lazydocker, yazi, process-compose, fzf, just, bottom, jq, Neovim, zellij, tmux, zoxide, ripgrep, aws-vault, age, delta, Bitwarden CLI

This is the **shared** set installed everywhere; individual machines can add more via [environment overlays](#environments-work--home--other).

### Via other methods

| Tool | Method |
|------|--------|
| chezmoi | `get.chezmoi.io` |
| mise | `mise.run` |
| Docker | `get.docker.com` |
| Rust/cargo | `rustup.rs` |
| taws, stu | `cargo install` |
| gdrive | GitHub release binary |
| bpytop | `pip install` |
| tldr | `npm install -g` |
| Claude Code | `claude.ai/install.sh` (standalone) |
| diffnav | `go install` |
| lazyworktree | `go install` |
| gh-dash | `gh extension install` |
| oh-my-zsh | `ohmyz.sh` install script |
| System deps | `apt`/`dnf`/`yum` (build-essential, zsh, ripgrep, fd-find, xclip) |

## Configs Included

- **Shell**: `.bashrc` and `.zshrc` with oh-my-zsh, mise activation, fzf, zoxide, aliases
- **Git**: Templated `.gitconfig` with delta as pager
- **Neovim**: LazyVim-based config with codediff.nvim plugin
- **Yazi**: File manager with DuckDB previews for csv/json/parquet
- **Kitty**: Terminal config
- **Claude Code**: Settings, permissions, statusline, and plugin marketplaces (superpowers, agents, altis-skills, warp)
- **opencode**: `opencode.jsonc` with plugins loaded by default (oh-my-openagent, superpowers, opencode-caveman, openrtk, openslimedit, opencode-mem, opencode-tool-search). The `opencode` tool + `rtk` binary install only in the **home** environment ([overlay](#environments-work--home--other)); opencode auto-installs the npm plugins on first launch. Note: opencode's `opencode-caveman` is a separate npm plugin from Claude Code's `caveman` marketplace — same idea, different ecosystems.
- **Lazygit**: Delta pager integration
- **AWS**: SSO config (plain) + credentials (age-encrypted)
- **Kube**: Cluster configs for EKS and GKE (exec-based auth, no embedded secrets)

## Environments (work / home / other)

Every machine installs a **shared** set of tools, plus an **environment-specific overlay**. The environment is chosen once when you run `chezmoi init` (prompt: `work`, `home`, or `other` — defaults to `home`) and stored in chezmoi's config as `environment`.

### How it works

mise supports config "environments": when `MISE_ENV` is set, mise merges an extra config file on top of the base one. The shells (`.zshrc`/`.bashrc`) export `MISE_ENV` from the chezmoi-selected environment, so the right overlay is always active.

| File | Loaded when | Contents |
|------|-------------|----------|
| `dot_config/mise/config.toml` | always | shared tools (every machine) |
| `dot_config/mise/config.work.toml` | `MISE_ENV=work` | work-only tools |
| `dot_config/mise/config.home.toml` | `MISE_ENV=home` | home-only tools |
| `dot_config/mise/config.other.toml` | `MISE_ENV=other` | tools for any other machine |

All three overlay files are deployed to every machine, but only the one matching `MISE_ENV` is ever loaded. The `run_onchange_after_01` install script exports the selected `MISE_ENV` before running `mise install`, so applying installs the shared tools **plus** the right overlay. It re-runs whenever any of the four config files change.

### Choosing / changing the environment

`chezmoi init` prompts for it interactively. Non-interactive:

```bash
chezmoi init --promptString "Environment (work/home/other)=work"
```

To change a machine's environment later, re-run `chezmoi init` (re-prompts), or edit `environment = "..."` in `~/.config/chezmoi/chezmoi.toml`, then `chezmoi apply`.

### Adding an environment-specific tool

Shared tools go in `config.toml`; environment-specific tools go in the matching overlay. For example, to install Terraform only on work machines, add it to `dot_config/mise/config.work.toml`:

```toml
[tools]
terraform = "latest"
```

`chezmoi apply` on a work machine installs it; home/other machines never see it.

### Repo-specific tools and config

For tools or settings scoped to a **single project** (not a whole environment), use mise's per-directory config — this lives in the project repo, **not** in this dotfiles repo:

```bash
cd ~/path/to/project
mise use node@20 terraform@1.7   # writes ./mise.toml, pinning tools for this dir
```

mise layers `mise.toml` (committed, shared with collaborators) and `mise.local.toml` (gitignored, personal) on top of the global config + environment overlay whenever you `cd` into that directory. Run `mise trust` once per repo to allow it. This is the right place for project-specific tool versions, env vars, and tasks.

## Shell Aliases

| Alias | Command |
|-------|---------|
| `vim` | `nvim` |
| `lg` | `lazygit` |
| `ld` | `lazydocker` |
| `k` | `k9s` |
| `y` | `yazi` |
| `yy` | yazi with cd-on-exit |
| `lw` | `lazyworktree` |

## Encryption

Sensitive files (AWS credentials) are encrypted with [age](https://age-encryption.org/) before being stored in this repo. The age identity key is itself passphrase-protected (`key.txt.age`).

**On a new machine**, the bootstrap script (`install.sh`) handles everything automatically:
1. Installs `age` if not present
2. Prompts for your passphrase to decrypt the age identity key
3. Runs `chezmoi apply` which decrypts all encrypted files

**If setting up manually** (without `install.sh`):
```bash
chezmoi init JayHennessy/dotfiles           # clone repo + generate config
age --decrypt --output ~/.config/chezmoi/key.txt "$(chezmoi source-path)/key.txt.age"  # decrypt age key
chezmoi apply                                # apply all files (encrypted ones now work)
```

## Updating

On other machines, pull and apply in one step:

```bash
chezmoi update
```

This pulls the latest changes from the repo and re-applies. If `mise/config.toml` changed, tools will be re-installed automatically. The age identity key must already be decrypted at `~/.config/chezmoi/key.txt` (done once during initial bootstrap).

### Making Changes

After editing any files in this repo, push and apply:

```bash
git add -A && git commit -m "description" && git push
chezmoi apply
```

### What to edit

| Change | Where to edit | Re-apply |
|--------|--------------|----------|
| Add/remove a mise tool (all machines) | `dot_config/mise/config.toml` | `chezmoi apply` (auto re-runs) |
| Add a tool for one environment | `dot_config/mise/config.<work\|home\|other>.toml` | `chezmoi apply` (auto re-runs) |
| Add a tool for one project/repo | `mise use ...` in that repo (not here) | — (mise loads it per-dir) |
| Change a machine's environment | Re-run `chezmoi init`, or edit `~/.config/chezmoi/chezmoi.toml` | `chezmoi apply` |
| Upgrade all mise tools to latest | Nothing — just run `mise upgrade` | No chezmoi needed |
| Add an apt package | `run_once_before_01-...` | Rename script or clear state |
| Add a cargo tool | `run_once_before_05-...` | Rename script or clear state |
| Change shell aliases | `dot_bashrc.tmpl` | `chezmoi apply` |
| Add oh-my-zsh plugins | `dot_zshrc.tmpl` (plugins list) | `chezmoi apply` |
| Change nvim/yazi/kitty config | Edit the file in `dot_config/` | `chezmoi apply` |
| Change Claude Code settings | `dot_claude/settings.json` | `chezmoi apply` |
| Change Claude Code permissions | `dot_claude/settings.local.json` | `chezmoi apply` |
| Add a Claude plugin marketplace | `.chezmoiexternal.toml` + `dot_claude/settings.json` | `chezmoi apply` |

### mise tools

Edit `dot_config/mise/config.toml` to add, remove, or pin tools that should exist on **every** machine. The `run_onchange_after_01` script automatically re-runs `mise install -y` whenever this file (or any environment overlay) changes (it hashes the file contents). For tools that should only exist in one environment, see [Environments](#environments-work--home--other).

To pin a specific version, change `"latest"` to a version string:

```toml
python = "3.12"
node = "20"
```

### oh-my-zsh plugins

Plugins are configured in `dot_zshrc.tmpl` on the `plugins=(...)` line:

```zsh
plugins=(git extract copypath copyfile zoxide)
```

To add a plugin, append its name to the list. oh-my-zsh ships with many [built-in plugins](https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins) that just need to be listed here — no extra installation required. Some useful ones:

| Plugin | What it does |
|--------|-------------|
| `git` | Git aliases and functions |
| `extract` | `extract <file>` to unpack any archive format |
| `copypath` | `copypath` copies current directory path to clipboard |
| `copyfile` | `copyfile <file>` copies file contents to clipboard |
| `zoxide` | Smarter `cd` that learns your most-used directories |
| `docker` | Docker command completions |
| `kubectl` | Kubectl completions and aliases |
| `aws` | AWS CLI completions |
| `terraform` | Terraform aliases and completions |

For third-party plugins, clone the repo into `$ZSH_CUSTOM/plugins/` and add the name to the list. For example:

```bash
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```

Then add `zsh-autosuggestions` to the plugins list in `dot_zshrc.tmpl` and run `chezmoi apply`.

### apt / cargo / other tools

The `run_once_before_*` scripts only run once per machine. If you edit one and need it to re-run, either:

1. **Rename the script** (e.g. add a version suffix) — chezmoi treats it as a new script
2. **Clear chezmoi's script state**:
   ```bash
   chezmoi state delete-bucket --bucket=scriptState
   chezmoi apply
   ```

### Claude Code

Claude Code config lives in `dot_claude/` and deploys to `~/.claude/`. Plugin marketplace repos are managed via `.chezmoiexternal.toml` and cloned automatically on `chezmoi apply`.

**Tracked files:**

| File | Purpose |
|------|---------|
| `dot_claude/settings.json` | Global settings (auto-mode, statusline, marketplace registrations) |
| `dot_claude/settings.local.json` | Default permissions (allowed tools, domains) |
| `dot_claude/executable_statusline.sh` | Statusline script (shows model + context %) |

**Not tracked** (generated at runtime): credentials, history, cache, debug logs, telemetry, project-specific settings, plugin blocklist.

**Included marketplaces:**

| Marketplace | Repo |
|-------------|------|
| claude-plugins-official | `anthropics/claude-plugins-official` |
| claude-code-warp | `warpdotdev/claude-code-warp` |
| superpowers | `obra/superpowers` |
| agents | `wshobson/agents` |
| altis-skills | `altis-labs/skills` |
| caveman | `JuliusBrussee/caveman` |

#### Adding a new plugin marketplace

1. Add the marketplace repo to `.chezmoiexternal.toml`:
   ```toml
   [".claude/plugins/marketplaces/marketplace-name"]
       type = "git-repo"
       url = "https://github.com/org/marketplace-name.git"
       refreshPeriod = "168h"
   ```

2. If the marketplace isn't official, register it in `dot_claude/settings.json`:
   ```json
   {
     "extraKnownMarketplaces": {
       "marketplace-name": {
         "source": {
           "source": "github",
           "repo": "org/marketplace-name"
         }
       }
     }
   }
   ```

3. Run `chezmoi apply` to clone the repo and update settings.

#### Adding default permissions

Edit `dot_claude/settings.local.json` to add tools or domains to the allow list:

```json
{
  "permissions": {
    "allow": [
      "WebSearch",
      "WebFetch(domain:example.com)",
      "Bash(some-safe-command)"
    ]
  }
}
```

#### Project-specific settings

Project-level Claude config (like `CLAUDE.md` or `.claude/settings.local.json` within a repo) is not managed here — those belong in their respective repos.

#### Installing/enabling skills

Skills come from plugin marketplaces. After `chezmoi apply` clones the marketplace repos, use `/install-skill` inside Claude Code to browse and enable skills from available marketplaces.

## open-design (optional, not automated)

[nexu-io/open-design](https://github.com/nexu-io/open-design) is a local-first design app + daemon + `od` CLI + MCP server — **not** an opencode plugin. opencode consumes it over MCP. It's intentionally **not wired into the dotfiles**: it isn't on npm and has no stable Linux build (only macOS `.dmg` / Windows `.exe`), so on Linux it runs via Docker or from source. To run it manually when wanted:

```bash
git clone https://github.com/nexu-io/open-design && cd open-design/deploy
cp .env.example .env
# set OD_API_TOKEN: openssl rand -hex 32
docker compose up -d              # serves http://localhost:7456
```

Then wire its MCP server into opencode (adds an `mcp` entry to `~/.config/opencode/opencode.json`):

```bash
od mcp install opencode           # use `--print` to preview, `--uninstall` to remove
```

If you later want this reproducible across machines, the resulting opencode MCP entry can be copied into `dot_config/opencode/opencode.jsonc`.

## Local Overrides

Add a `~/.bashrc.local` (or `~/.zshrc.local`) for machine-specific config — these are sourced at the end and not managed by chezmoi.
