# Cisco 3850 Day-0 Bootstrap

Ce dossier contient le premier jet d'implémentation Day-0 pour des switches Cisco 3850 non configurés.

## Rôles

- `pnp_server`: valide les données Day-0, rend les profils IOS (fichiers `.cfg`), génère le `device-map.yaml` et publie les artefacts sur HTTP via nginx.
- `config`: applique la configuration Day-1 complète depuis les host vars.

## Flux

1. Exécuter le playbook `playbooks/bootstrap_platform.yaml` sur l'hôte `bootstrap_server`.
2. Les switches récupèrent leur profil Day-0 (mécanisme PnP côté Cisco).
3. Exécuter `playbooks/bootstrap_apply_day1.yaml` sur les hôtes `cisco_bootstrapped`.

## Variables minimales à fournir dans l'inventaire

Par hôte switch (host vars), fournir au minimum:

```yaml
serial: "FOC1234X0YZ"
mac: "aa:bb:cc:dd:ee:ff"            # optionnel si serial présent
profile: "sw-core-01"               # optionnel, défaut: nom d'hôte
hostname: "sw-core-01"              # optionnel, défaut: nom d'hôte

admin_password: "change-me"         # requis pour pnp_server (Day-0) et Day-1
mgmt_default_gateway: "10.0.0.1"    # optionnel
```

`admin_password` est requis pour la génération Day-0 gérée par `pnp_server` et pour Day-1.

Variables globales utiles:

```yaml
pnp_server_day0_site_domain_name: "example.local"
pnp_server_day0_site_name_servers:
  - "10.0.0.53"
pnp_server_day0_site_ntp_servers:
  - "10.0.0.123"
```

Variables de pilotage de groupe (optionnelles):

```yaml
pnp_server_day0_profiles_source_group: cisco_bootstrapped
pnp_server_day0_devices_source_group: cisco_bootstrapped
```

Notes de compatibilité:

- `pnp_server_day0_profiles` reste supporté comme override explicite.
- `pnp_server_day0_devices` reste supporté comme override explicite.

## Notes

- L'identification visée est `serial` prioritaire, avec `mac` en secours.
- Le profil Day-0 est volontairement minimal pour limiter le risque opérationnel.
- Le durcissement complet reste géré par le rôle `config` en Day-1.
