SHELL := /bin/bash

# Usage examples:
#   make syntax-check-all
#   make syntax-check-all COLLECTION=cisco-3850
#   make syntax-check PLAYBOOK=cisco-3850/playbooks/bootstrap_platform.yaml
#   make syntax-check PLAYBOOK=bootstrap_platform
#   make syntax-check-bootstrap_platform
#   make syntax-check-collection COLLECTION=cisco-3850

ANSIBLE ?= ansible-playbook
COLLECTION ?=
PLAYBOOK ?= 
INVENTORY ?=
ROLES_PATH ?=
ROOT := $(CURDIR)

.PHONY: help list-playbooks syntax-check syntax-check-all syntax-check-collection

help:
	@echo "Targets disponibles:"
	@echo "  list-playbooks                         Liste tous les playbooks detectes"
	@echo "  syntax-check PLAYBOOK=<path|name>     Syntax check d'un playbook"
	@echo "  syntax-check-all                       Syntax check de tous les playbooks"
	@echo "  syntax-check-collection COLLECTION=<name>  Syntax check d'une collection"
	@echo "  syntax-check-<name>                    Raccourci pour PLAYBOOK=<name>"
	@echo ""
	@echo "Variables optionnelles:"
	@echo "  COLLECTION=<name>   ex: cisco-3850"
	@echo "  INVENTORY=<path>    inventory optionnel"
	@echo "  ROLES_PATH=<path>   override ANSIBLE_ROLES_PATH"
	@echo "  ANSIBLE=<bin>       override ansible-playbook"

list-playbooks:
	@set -euo pipefail; \
	mapfile -t playbooks < <(find . -mindepth 2 -maxdepth 3 -type f \( -path "./*/playbooks/*.yaml" -o -path "./*/playbooks/*.yml" \) | sed 's#^\./##' | sort); \
	if [[ $${#playbooks[@]} -eq 0 ]]; then \
		echo "Aucun playbook detecte."; \
		exit 0; \
	fi; \
	printf '%s\n' "$${playbooks[@]}"

syntax-check:
	@set -euo pipefail; \
	ansible_bin="$(ANSIBLE)"; \
	if [[ -z "$$ansible_bin" ]]; then ansible_bin="ansible-playbook"; fi; \
	if [[ -z "$(PLAYBOOK)" ]]; then \
		echo "PLAYBOOK est requis (path complet ou nom court)."; \
		exit 1; \
	fi; \
	mapfile -t all_playbooks < <(find . -mindepth 2 -maxdepth 3 -type f \( -path "./*/playbooks/*.yaml" -o -path "./*/playbooks/*.yml" \) | sed 's#^\./##' | sort); \
	if [[ $${#all_playbooks[@]} -eq 0 ]]; then \
		echo "Aucun playbook detecte."; \
		exit 1; \
	fi; \
	target="$(PLAYBOOK)"; \
	resolved=""; \
	if [[ -f "$$target" ]]; then \
		resolved="$$target"; \
	elif [[ -f "$$target.yaml" ]]; then \
		resolved="$$target.yaml"; \
	elif [[ -f "$$target.yml" ]]; then \
		resolved="$$target.yml"; \
	else \
		if [[ "$$target" != *.yaml && "$$target" != *.yml ]]; then \
			target_name="$$target.yaml"; \
		else \
			target_name="$${target##*/}"; \
		fi; \
		mapfile -t matches < <(printf '%s\n' "$${all_playbooks[@]}" | awk -v n="$$target_name" '$$0 ~ ("/" n "$$")'); \
		if [[ $${#matches[@]} -eq 1 ]]; then \
			resolved="$${matches[0]}"; \
		elif [[ $${#matches[@]} -gt 1 ]]; then \
			echo "Playbook ambigu ($$target). Candidats:"; \
			printf '  - %s\n' "$${matches[@]}"; \
			exit 1; \
		else \
			echo "Playbook introuvable: $$target"; \
			exit 1; \
		fi; \
	fi; \
	collection="$${resolved%%/*}"; \
	roles_path="$(ROLES_PATH)"; \
	if [[ -z "$$roles_path" ]]; then \
		roles_path="$(ROOT)/$$collection:$(ROOT)/$$collection/roles:$(ROOT)"; \
	fi; \
	ansible_cfg="$(ROOT)/ansible.cfg"; \
	if [[ -f "$(ROOT)/$$collection/ansible.cfg" ]]; then \
		ansible_cfg="$(ROOT)/$$collection/ansible.cfg"; \
	fi; \
	echo "[syntax-check] $$resolved"; \
	if [[ -n "$(INVENTORY)" ]]; then \
		ANSIBLE_CONFIG="$$ansible_cfg" ANSIBLE_ROLES_PATH="$$roles_path" "$$ansible_bin" --syntax-check "$$resolved" -i "$(INVENTORY)"; \
	else \
		ANSIBLE_CONFIG="$$ansible_cfg" ANSIBLE_ROLES_PATH="$$roles_path" "$$ansible_bin" --syntax-check "$$resolved"; \
	fi

syntax-check-all:
	@set -euo pipefail; \
	ansible_bin="$(ANSIBLE)"; \
	if [[ -z "$$ansible_bin" ]]; then ansible_bin="ansible-playbook"; fi; \
	mapfile -t playbooks < <(find . -mindepth 2 -maxdepth 3 -type f \( -path "./*/playbooks/*.yaml" -o -path "./*/playbooks/*.yml" \) | sed 's#^\./##' | sort); \
	if [[ -n "$(COLLECTION)" ]]; then \
		mapfile -t playbooks < <(printf '%s\n' "$${playbooks[@]}" | awk -v c="$(COLLECTION)" '$$0 ~ ("^" c "/playbooks/")'); \
	fi; \
	if [[ $${#playbooks[@]} -eq 0 ]]; then \
		echo "Aucun playbook detecte pour la selection demandee."; \
		exit 1; \
	fi; \
	for pb in "$${playbooks[@]}"; do \
		collection="$${pb%%/*}"; \
		roles_path="$(ROLES_PATH)"; \
		if [[ -z "$$roles_path" ]]; then \
			roles_path="$(ROOT)/$$collection:$(ROOT)/$$collection/roles:$(ROOT)"; \
		fi; \
		ansible_cfg="$(ROOT)/ansible.cfg"; \
		if [[ -f "$(ROOT)/$$collection/ansible.cfg" ]]; then \
			ansible_cfg="$(ROOT)/$$collection/ansible.cfg"; \
		fi; \
		echo "[syntax-check] $$pb"; \
		if [[ -n "$(INVENTORY)" ]]; then \
			ANSIBLE_CONFIG="$$ansible_cfg" ANSIBLE_ROLES_PATH="$$roles_path" "$$ansible_bin" --syntax-check "$$pb" -i "$(INVENTORY)"; \
		else \
			ANSIBLE_CONFIG="$$ansible_cfg" ANSIBLE_ROLES_PATH="$$roles_path" "$$ansible_bin" --syntax-check "$$pb"; \
		fi; \
	done

syntax-check-collection:
	@if [[ -z "$(COLLECTION)" ]]; then \
		echo "COLLECTION est requise (ex: make syntax-check-collection COLLECTION=cisco-3850)"; \
		exit 1; \
	fi
	@$(MAKE) --no-print-directory syntax-check-all COLLECTION=$(COLLECTION)

syntax-check-%:
	@$(MAKE) --no-print-directory syntax-check PLAYBOOK=$*
