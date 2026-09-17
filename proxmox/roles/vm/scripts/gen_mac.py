#!/usr/bin/env python3
"""Génère une adresse MAC aléatoire sous l'OUI Proxmox (BC:24:11).

Utilisée par cedille.proxmox.vm (create_vm.yaml) depuis la version 2.0.0,
qui exige un champ `mac` explicite sur chaque entrée de vm_net/vm_nets
(une MAC générée par Proxmox à la création n'est pas déclarative/auditable
depuis Ansible seul).

Usage :
    scripts/gen_mac.py
    make gen-mac          (target fourni par le repo appelant, ex. AnsibleInfra)
"""

import random
import sys

PROXMOX_OUI = (0xBC, 0x24, 0x11)


def generate_mac() -> str:
    suffix = (random.randint(0, 255) for _ in range(3))
    return ":".join(f"{b:02X}" for b in (*PROXMOX_OUI, *suffix))


if __name__ == "__main__":
    print(generate_mac())
    sys.exit(0)
