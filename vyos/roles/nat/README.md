# nat

Collection Ansible pour gérer la configuration NAT sur les équipements VyOS.

## Variables

- `nat_source_rules` : Liste des règles de source NAT (SNAT).
- `nat_destination_rules` : Liste des règles de destination NAT (DNAT).
- `nat_static_rules` : Liste des règles de NAT statique (1:1).

## Exemple

```yaml
- hosts: vyos
  roles:
    - role: nat
      vars:
        nat_source_rules:
          - rule_number: 100
            outbound_interface: eth0
            source_address: 192.168.0.0/24
            translation_address: masquerade
```
