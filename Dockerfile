FROM kalilinux/kali-rolling

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color

RUN apt-get update && apt-get install -y --no-install-recommends \
    \
    # Network & scanning
    nmap masscan netcat-traditional \
    curl wget dnsutils whois traceroute tcpdump \
    iproute2 iputils-ping net-tools \
    \
    # Web
    gobuster ffuf nikto whatweb dirb wfuzz sqlmap \
    \
    # Password attacks
    hydra john hashcat \
    \
    # Windows / AD
    netexec smbclient smbmap ldap-utils krb5-user \
    \
    # Pivoting
    openvpn proxychains4 socat \
    \
    # Python
    python3 python3-pip python3-venv \
    \
    # Ruby (for evil-winrm)
    ruby ruby-dev \
    \
    # Shell & utils
    bash-completion vim tmux git jq \
    zip unzip p7zip-full \
    file xxd binwalk exiftool steghide \
    gcc g++ make \
    \
    # Wordlists
    wordlists seclists \
    \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Unpack rockyou in the same context (already downloaded above)
RUN [ -f /usr/share/wordlists/rockyou.txt.gz ] \
    && gunzip /usr/share/wordlists/rockyou.txt.gz || true

# ─── Evil-WinRM ────────────────────────────────────────────────────────────────
RUN gem install evil-winrm --no-document \
    && rm -rf /root/.gem/ruby/*/cache/*

# ─── Python tools ──────────────────────────────────────────────────────────────
RUN pip3 install --break-system-packages --no-cache-dir \
    bloodhound pwntools pycryptodome paramiko scapy

# ─── Kerbrute ──────────────────────────────────────────────────────────────────
RUN curl -sL \
    https://github.com/ropnop/kerbrute/releases/latest/download/kerbrute_linux_amd64 \
    -o /usr/local/bin/kerbrute \
    && chmod +x /usr/local/bin/kerbrute

# ─── Chisel ────────────────────────────────────────────────────────────────────
RUN wget -q \
    https://github.com/jpillora/chisel/releases/download/v1.10.1/chisel_1.10.1_linux_amd64.gz \
    -O /tmp/chisel.gz \
    && gunzip /tmp/chisel.gz \
    && mv /tmp/chisel /usr/local/bin/chisel \
    && chmod +x /usr/local/bin/chisel

# ─── Ligolo-ng ─────────────────────────────────────────────────────────────────
RUN mkdir -p /opt/ligolo \
    && curl -sL \
    https://github.com/nicocha30/ligolo-ng/releases/latest/download/proxy_linux_amd64 \
    -o /opt/ligolo/proxy \
    && chmod +x /opt/ligolo/proxy

# ─── Responder ─────────────────────────────────────────────────────────────────
RUN git clone --depth 1 https://github.com/lgandx/Responder.git /opt/Responder \
    && pip3 install --break-system-packages --no-cache-dir netifaces 2>/dev/null || true \
    && rm -rf /opt/Responder/.git

# ─── adPEAS ────────────────────────────────────────────────────────────────────
RUN git clone --depth 1 https://github.com/61106960/adPEAS.git /opt/adPEAS \
    && rm -rf /opt/adPEAS/.git

# ─── PEASS-ng ──────────────────────────────────────────────────────────────────
RUN mkdir -p /opt/PEASS \
    && curl -sL https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh \
        -o /opt/PEASS/linpeas.sh \
    && curl -sL https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEAS.bat \
        -o /opt/PEASS/winPEAS.bat \
    && curl -sL https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEASx64.exe \
        -o /opt/PEASS/winPEASx64.exe \
    && chmod +x /opt/PEASS/linpeas.sh

# ─── pspy ──────────────────────────────────────────────────────────────────────
RUN curl -sL https://github.com/DominicBreuker/pspy/releases/latest/download/pspy64 \
    -o /opt/pspy64 \
    && chmod +x /opt/pspy64

# ─── PowerSploit ───────────────────────────────────────────────────────────────
RUN git clone --depth 1 https://github.com/PowerShellMafia/PowerSploit.git /opt/PowerSploit \
    && rm -rf /opt/PowerSploit/.git

# ─── Symlinks ──────────────────────────────────────────────────────────────────
RUN ln -sf /opt/Responder/Responder.py /usr/local/bin/responder \
    && ln -sf /opt/PEASS/linpeas.sh /usr/local/bin/linpeas \
    && ln -sf /usr/bin/netexec /usr/local/bin/cme 2>/dev/null || true \
    && ln -sf /usr/bin/netexec /usr/local/bin/crackmapexec 2>/dev/null || true

# ─── Shell config ──────────────────────────────────────────────────────────────
RUN cat >> /root/.bashrc << 'EOF'

# ─── History ──────────────────────────────────────────────────
export HISTFILE=/ctfdata/.bash_history
export HISTSIZE=50000
export HISTFILESIZE=50000
export HISTTIMEFORMAT="%d/%m %T  "
export HISTCONTROL=ignoredups:erasedups
shopt -s histappend
PROMPT_COMMAND="history -a; history -c; history -r; ${PROMPT_COMMAND}"

# ─── Autocomplete ─────────────────────────────────────────────
if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
fi
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
bind 'set show-all-if-ambiguous on'
bind 'set completion-ignore-case on'
bind 'set colored-stats on'
bind 'set colored-completion-prefix on'

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