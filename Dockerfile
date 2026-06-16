FROM kalilinux/kali-rolling

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color

# ─── Base system ───────────────────────────────────────────────────────────────
# Split into smaller groups so if one fails it's easier to debug
RUN apt-get update && apt-get install -y \
    nmap masscan netcat-traditional curl wget \
    dnsutils whois traceroute tcpdump \
    iproute2 iputils-ping net-tools \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    gobuster ffuf nikto whatweb dirb wfuzz sqlmap \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    hydra john hashcat \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    smbclient smbmap ldap-utils \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    openvpn proxychains4 socat \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    python3 python3-pip python3-venv \
    vim tmux git jq \
    zip unzip p7zip-full \
    file xxd binwalk exiftool steghide \
    gcc g++ make \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ─── Wordlists ─────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y wordlists seclists \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && if [ -f /usr/share/wordlists/rockyou.txt.gz ]; then \
        gunzip /usr/share/wordlists/rockyou.txt.gz; \
    fi

# ─── Metasploit ────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y metasploit-framework \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ─── Python tools (impacket, bloodhound, etc.) ─────────────────────────────────
RUN pip3 install --break-system-packages --no-cache-dir \
    bloodhound \
    pwntools \
    pycryptodome \
    paramiko \
    scapy

# ─── CrackMapExec / NetExec (new name: cme) ───────────────────────────────
# In newer Kali versions crackmapexec is renamed to netexec; create both variants
RUN apt-get update && apt-get install -y netexec 2>/dev/null || true \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/bin/netexec /usr/local/bin/cme 2>/dev/null || true \
    && ln -sf /usr/bin/netexec /usr/local/bin/crackmapexec 2>/dev/null || true

# ─── Evil-WinRM ────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y ruby ruby-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && gem install evil-winrm --no-document

# ─── Kerbrute ──────────────────────────────────────────────────────────────────
RUN curl -sL \
    https://github.com/ropnop/kerbrute/releases/latest/download/kerbrute_linux_amd64 \
    -o /usr/local/bin/kerbrute && chmod +x /usr/local/bin/kerbrute

# ─── Chisel (tunneling) ────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y chisel 2>/dev/null || \
    ( wget -q https://github.com/jpillora/chisel/releases/download/v1.10.1/chisel_1.10.1_linux_amd64.gz \
      -O /tmp/chisel.gz && gunzip /tmp/chisel.gz && mv /tmp/chisel /usr/local/bin/chisel \
      && chmod +x /usr/local/bin/chisel ) \
    ; apt-get clean && rm -rf /var/lib/apt/lists/*

# ─── Ligolo-ng ─────────────────────────────────────────────────────────────────
RUN mkdir -p /opt/ligolo && \
    curl -sL \
    https://github.com/nicocha30/ligolo-ng/releases/latest/download/proxy_linux_amd64 \
    -o /opt/ligolo/proxy && chmod +x /opt/ligolo/proxy

# ─── Responder ─────────────────────────────────────────────────────────────────
RUN git clone --depth 1 https://github.com/lgandx/Responder.git /opt/Responder \
    && pip3 install --break-system-packages netifaces 2>/dev/null || true

# ─── adPEAS ────────────────────────────────────────────────────────────────────
RUN git clone --depth 1 https://github.com/61106960/adPEAS.git /opt/adPEAS

# ─── PEASS-ng (linpeas / winpeas) ──────────────────────────────────────────────
RUN mkdir -p /opt/PEASS && \
    curl -sL https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh \
        -o /opt/PEASS/linpeas.sh && \
    curl -sL https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEAS.bat \
        -o /opt/PEASS/winPEAS.bat && \
    curl -sL https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEASx64.exe \
        -o /opt/PEASS/winPEASx64.exe && \
    chmod +x /opt/PEASS/linpeas.sh

# ─── pspy ──────────────────────────────────────────────────────────────────────
RUN curl -sL https://github.com/DominicBreuker/pspy/releases/latest/download/pspy64 \
    -o /opt/pspy64 && chmod +x /opt/pspy64

# ─── PowerSploit / PowerView ───────────────────────────────────────────────────
RUN git clone --depth 1 https://github.com/PowerShellMafia/PowerSploit.git /opt/PowerSploit

# ─── Symlinks & shell config ───────────────────────────────────────────────────
RUN ln -sf /opt/Responder/Responder.py /usr/local/bin/responder \
    && ln -sf /opt/PEASS/linpeas.sh /usr/local/bin/linpeas

RUN apt-get update && apt-get install -y bash-completion \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN cat >> /root/.bashrc << 'EOF'

# ─── History ──────────────────────────────────────────────────
export HISTFILE=/ctfdata/.bash_history   # history stored on host (persists)
export HISTSIZE=50000
export HISTFILESIZE=50000
export HISTTIMEFORMAT="%d/%m %T  "       # timestamp for each command
export HISTCONTROL=ignoredups:erasedups  # don't duplicate identical commands
# append to history, don't overwrite
shopt -s histappend                       # append to history, don't overwrite
# Save history after each command (not only on exit)
PROMPT_COMMAND="history -a; history -c; history -r; ${PROMPT_COMMAND}"

# ─── Autocomplete ─────────────────────────────────────────────
if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
fi
# Up/down arrows search by start of the entered command
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
# Tab — показывать варианты сразу, не пищать
bind 'set show-all-if-ambiguous on'
bind 'set completion-ignore-case on'
bind 'set colored-stats on'
bind 'set visible-stats on'
bind 'set mark-symlinked-directories on'
bind 'set colored-completion-prefix on'
bind 'set menu-complete-display-prefix on'

# ─── Path & env ───────────────────────────────────────────────
export PATH="$PATH:/opt/Responder:/opt/adPEAS:/opt/ligolo"
export WORDLISTS=/usr/share/wordlists
export SECLISTS=/usr/share/seclists
export ROCKYOU=/usr/share/wordlists/rockyou.txt

# ─── Aliases ──────────────────────────────────────────────────
alias ll="ls -la --color=auto"
alias la="ls -A --color=auto"
alias nmap-quick="nmap -T4 --open -oA /ctfdata/scans/quick"
alias nmap-full="nmap -sC -sV -p- -oA /ctfdata/scans/full"
alias nmap-udp="nmap -sU --top-ports 200 -oA /ctfdata/scans/udp"
alias ff="ffuf -w /usr/share/seclists/Discovery/Web-Content/raft-medium-files.txt -u"

# ─── Prompt ───────────────────────────────────────────────────
PS1="\[\033[01;31m\][HTB \$TARGET]\[\033[00m\] \[\033[01;34m\]\w\[\033[00m\] # "
[ -f /ctfdata/.target ] && source /ctfdata/.target
EOF

WORKDIR /ctfdata
CMD ["/bin/bash"]