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

### Exploitation
`metasploit-framework` `pwntools`

### Post-exploitation & Pivoting
`Responder` `chisel` `ligolo-ng` `proxychains4` `socat`

### Linux / Windows PrivEsc
`linPEAS` `winPEAS` `pspy64`

### Forensics / Misc
`binwalk` `exiftool` `steghide` `xxd` `tmux` `jq` `p7zip`

### Wordlists
`rockyou.txt` · full `SecLists` collection  
Available at `$ROCKYOU`, `$WORDLISTS`, `$SECLISTS`

---

## Requirements

- Docker
- Make
- (Optional) Claude Code for AI-assisted analysis

---

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/your-username/kali-htb-docker
cd kali-htb-docker

# 2. Build the image (~15–20 min first time)
make build

# 3. Connect OpenVPN on your host (HTB .ovpn file)
sudo openvpn --config ~/Downloads/your.ovpn

# 4. Start the container
make up
```

You're in. The container sees your `tun0` interface directly — no extra config needed.

---

## Usage

```bash
make up          # Start a new container
make resume      # Jump back into a stopped container
make shell       # Open a second shell in the running container
make stop        # Pause (work is saved)
make rm          # Remove container (image and ctfdata folder stay)
make rebuild     # Rebuild image from scratch (no cache)
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

### Built-in aliases

```bash
nmap-quick 10.10.11.x      # Fast open ports scan, saves to /ctfdata/scans/
nmap-full  10.10.11.x      # Full -sC -sV -p- scan
nmap-udp   10.10.11.x      # Top 200 UDP ports
ff http://10.10.11.x/      # ffuf with raft-medium wordlist
```

---

## Persistence

Everything important lives in `./ctfdata/` on your **host machine** — not inside the container:

```
your-writeups/
├── ctfdata/              ← mounted as /ctfdata inside the container
│   ├── .bash_history     ← shell history survives rebuilds
│   ├── .target           ← current target IP
│   ├── scans/
│   ├── loot/
│   ├── exploit/
│   ├── notes/
│   └── vpn/              ← put your .ovpn files here
├── Forest/               ← your writeups live alongside
└── Active/
```

Rebuild the image, your history, scans, and loot are all still there.

---

## Using with Claude Code

Because the container uses `--network host`, Claude Code running on your host machine can interact with it directly:

```bash
# Pipe nmap output to Claude for analysis
nmap -sC -sV 10.10.11.206 | claude "what services look interesting and what should I try first?"

# Ask Claude to help with a hash
echo "5f4dcc3b5aa765d61d8327deb882cf99" | claude "what hash type is this and how do I crack it?"

# Get next steps after gobuster
gobuster dir -u http://10.10.11.206 -w $SECLISTS/Discovery/Web-Content/raft-medium-files.txt \
  | claude "analyze these results and suggest what to investigate"
```

---

## Customization

To add or remove tools, edit `Dockerfile` and rebuild:

```bash
# Add a tool
vim Dockerfile        # add apt install / pip install / git clone

# Rebuild
make rebuild
```

The Makefile target and container name can be changed at the top of `Makefile`:

```makefile
IMAGE     := kali-ctf      # Docker image name
CONTAINER := ctf-box       # Container name
WORKDIR   := $(PWD)/ctfdata  # Host folder mounted into container
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
- [ ] Add `netexec` modules for MSSQL, WinRM, LDAP workflows
- [ ] Add `pypykatz` as a Python alternative to mimikatz
- [ ] Add `certipy` for AD CS (certificate services) attacks
- [ ] Add `coercer` for NTLM coercion attacks
- [ ] Add pre-downloaded `PayloadsAllTheThings` cheatsheets to `/opt`
- [ ] Pin SecLists to a specific release tag for reproducibility

### Shell & UX
- [ ] Add `fzf` for fuzzy history search (Ctrl+R)
- [ ] Add `zsh` + `oh-my-zsh` as an optional alternative to bash
- [ ] Add `bat` (better `cat`) and `fd` (better `find`)
- [ ] Auto-source `.target` file so `$TARGET` is always set on entry
- [ ] Add a `make notes` target that opens notes.md for current machine in vim

### Workflow
- [ ] `make vpn` — auto-detect `.ovpn` file in `ctfdata/vpn/` if only one exists
- [ ] `make update` — pull latest versions of git-cloned tools (Responder, adPEAS, etc.)
- [ ] `make serve` — start a quick HTTP server on port 8080 to serve loot/exploit files to targets
- [ ] `make clean-scans` — archive old scans for a machine instead of deleting
- [ ] Add a `docker-compose.yml` as an alternative to the Makefile for those who prefer it

### Claude Code integration
- [ ] Write wrapper scripts: `nmap-claude`, `gobuster-claude` — run tool and pipe to Claude automatically
- [ ] Add a `make ai-recon IP=x.x.x.x` target that runs nmap + Claude analysis in one command
- [ ] Document example prompts for common CTF scenarios in the README

### CI / Maintenance
- [+] GitHub Actions workflow to build and push image to GHCR on every commit
- [+] Weekly scheduled build to pull latest Kali packages and tool updates
- [ ] Add a `make check` target that verifies all key tools are present and executable after build