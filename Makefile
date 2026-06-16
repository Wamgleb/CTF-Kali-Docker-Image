# ─────────────────────────────────────────────────────────────
#  HTB / CTF Docker Environment — Makefile
#  Usage: make <target>
# ─────────────────────────────────────────────────────────────

IMAGE    := kali-ctf-env
# Folder on the host, mounted to /ctfdata inside the container
WORKDIR  := $(PWD)/ctfdata
CONTAINER:= ctf-box

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
new-machine:  ## Create folder for a new machine: make new-machine NAME=Forest
	@[ -n "$(NAME)" ] || (echo "Usage: make new-machine NAME=<machine>" && exit 1)
	mkdir -p $(WORKDIR)/$(NAME)/scans $(WORKDIR)/$(NAME)/loot $(WORKDIR)/$(NAME)/exploit $(WORKDIR)/$(NAME)/notes
	@echo "Created: $(WORKDIR)/$(NAME)/{scans,loot,exploit,notes}"
	@echo "# $(NAME)" > $(WORKDIR)/$(NAME)/notes/notes.md
	@echo "## IP\n\n## Recon\n\n## Foothold\n\n## PrivEsc\n\n## Flags\n" \
	    >> $(WORKDIR)/$(NAME)/notes/notes.md

.PHONY: set-target
set-target:  ## Write target IP: make set-target IP=10.10.11.x
	@[ -n "$(IP)" ] || (echo "Usage: make set-target IP=<ip>" && exit 1)
	@echo "export TARGET=$(IP)" > $(WORKDIR)/.target
	@echo "TARGET set to $(IP)"

# ─── Lifecycle ────────────────────────────────────────────────

.PHONY: stop
stop:  ## Stop the container (data is preserved)
	docker stop $(CONTAINER)

.PHONY: rm
rm: stop  ## Remove the container (image and /ctfdata folder remain)
	docker rm $(CONTAINER)

.PHONY: clean
clean: rm  ## Remove container + image
	docker rmi $(IMAGE)

# ─── Utilities ────────────────────────────────────────────────

.PHONY: shell
shell:  ## Open an additional shell in the running container
	docker exec -it $(CONTAINER) /bin/bash

.PHONY: dirs
dirs:  ## Create base structure ~/ctfdata
	mkdir -p $(WORKDIR)/scans $(WORKDIR)/loot $(WORKDIR)/exploit $(WORKDIR)/notes $(WORKDIR)/vpn
	@echo "CTF workdir ready: $(WORKDIR)"

.PHONY: vpn
vpn:  ## Connect VPN from inside container: make vpn FILE=htb.ovpn
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

# ─── Help ─────────────────────────────────────────────────────

.PHONY: help
help:  ## Show this help
	@echo ""
	@echo "  CTF Docker Environment"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	    | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36mmake %-16s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "  Workdir: $(WORKDIR)"
	@echo "  Image:   $(IMAGE)"
	@echo "  Container: $(CONTAINER)"
	@echo ""