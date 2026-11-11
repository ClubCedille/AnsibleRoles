# CS2 Ansible collection for Lan ETS

This collection prepares Linux game hosts for Auto Tournament's CS2 Server
Manager (`csm`). The Auto Tournament application and PostgreSQL remain deployed
separately.

## Roles

- `csm_host`: creates the unprivileged CSM account, installs the pinned CSM
  release, runs `csm setup-host`, and selects instance mode.
- `csm_machine_link`: links one host with a short-lived Auto Tournament machine
  code and installs the CSM agent. The role never writes the code to disk or
  Ansible logs.

## Deployment

The VM count is the number of hosts in the `[cs2]` group in
`AnsibleInfra/inventories/lanets/hosts.ini` (currently 10). Each VM is sized at
16 vCPU, 32 GiB RAM, and a 150 GiB disk. The target is four CSM servers per VM,
so the current inventory has capacity for 40 servers. To change the VM count,
run `python3 inventories/lanets/host_vars/autogenerate.py --count N` from the
`AnsibleInfra` repository; it updates the `[cs2]` host list and generates the
matching VM metadata, removing generated numbered host files above `N`. Counts
are limited to 1–99 by the current IP scheme; the separate demo host file is
preserved.

1. Create the VMs with the `cs2-create-vm.yaml` playbook.
2. Run `cs2-server.yaml` to prepare all CSM hosts.
3. Run `cs2-csm-link.yaml` separately for each VM with `--limit <host>`. Enter
   the Auto Tournament URL and that VM's unused one-time machine code when
   prompted.
4. In Auto Tournament, create four servers on each machine and cap automatic
   scaling at four per machine. The platform owns server creation and lifecycle.

Use `cs2-csm-status.yaml` to read the local CSM status. CSM instance mode needs
Linux 5.11 or newer, and each running game server still needs its own CPU and
RAM. The machine-link code is single-use and expires; never commit it to
inventory. Platform-linked CSM mode does not need Steam GSLTs or RCON passwords.
The SSH connection password reuses the encrypted `vm_password`; the Ansible
Vault password is still required when creating or connecting to VMs. The pinned
CSM version and its architecture-specific SHA-256 checksums are kept together
in the `csm_host` role defaults.
