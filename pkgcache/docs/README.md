# Collection pkgcache pour la flotte Cedille

Configure les gestionnaires de paquets natifs de chaque « saveur » Linux/BSD
de la flotte pour utiliser les caches/mirrors de paquets internes Cedille
(cluster `cedille-k8s-shared`, namespace `pkg-cache`, repo
`ClubCedille/k8s-shared`).

## Installation

```bash
ansible-galaxy collection install -r requirements.yml
```

```yaml
collections:
  - name: cedille.pkgcache
    version: "0.2.0"
```

## Rôles disponibles

Tous les backends serveur utilisent **BasicAuth** sur un sous-domaine dédié
— pas de mTLS nulle part (l'auth par certificat client s'est avérée peu
fiable côté clients, à commencer par apt/GnuTLS ; plutôt que de gérer deux
mécanismes d'auth différents selon la stack TLS de chaque gestionnaire de
paquets, tout est passé sur BasicAuth-en-URI uniformément).

| Rôle       | Statut                    | Sous-domaine cache                | Suivi                         |
|------------|---------------------------|-------------------------------------|--------------------------------|
| `apt`      | Fonctionnel, validé live  | `apt-cache.pkg.etsmtl.club`         | —                               |
| `dnf`      | Fonctionnel, validé live  | `dnf-cache.pkg.etsmtl.club`         | —                               |
| `pacman`   | Fonctionnel, validé live  | `pacman-cache.pkg.etsmtl.club`      | —                               |
| `nix`      | Fonctionnel, validé live  | `nix-cache.pkg.etsmtl.club`         | —                               |
| `pkg`      | Expérimental              | `freebsd-cache.pkg.etsmtl.club`     | non validé avec un vrai client pkg |
| `opnsense` | Expérimental              | `freebsd-cache.pkg.etsmtl.club`     | voir avertissement ci-dessous |

Intégration Ansible globale suivie sur `ClubCedille/k8s-shared#396`.

### ⚠️ Rôle `opnsense` — portée limitée

Il n'existe **aucun backend serveur dédié** au dépôt OPNsense lui-même
(`pkg.opnsense.org` : firmware, plugins, mises à jour du système). Ce rôle
pointe uniquement le **repo FreeBSD de base** d'un hôte OPNsense
(`/usr/local/etc/pkg/repos/FreeBSD.conf`) vers le cache `freebsd-pkg`
générique — il ne remplace ni ne touche au dépôt OPNsense proprement dit.
Comme le rôle `pkg`, il hérite de la mise en garde du runbook serveur :
validé seulement via `curl` (pas un vrai client `pkg`), à confirmer sur
une vraie machine avant tout déploiement flotte.

Contrairement au reste de la collection `cedille.opnsense` (100 % piloté
par API, `oxlorg.opnsense.*`), ce rôle utilise SSH + `become` classique,
car `oxlorg.opnsense` n'expose aucun module pour les repos pkg.

## Rôle `apt`

Configure apt en mode **mirror direct** : un fichier deb822
(`sources.list.d/pkgcache-<mirror>.sources`) par mirror, avec les
identifiants BasicAuth embarqués directement dans l'URI :

```
URIs: https://user:pass@apt-cache.pkg.etsmtl.club/<host-origine>/<path>
```

### ⚠️ Point critique — ne pas utiliser `Acquire::http::Proxy`

Le sidecar nginx du cache (`auth_basic`) attend les identifiants dans
l'URI (mirror direct). `Acquire::http::Proxy` fait passer les creds en
en-tête `Proxy-Authorization`, que `auth_basic` **ignore** — confirmé en
test live : proxy → 401 systématique, mirror direct → fonctionne. apt est
le seul gestionnaire de paquets de la flotte avec cette distinction
proxy/mirror ; dnf et pacman acceptent le BasicAuth-en-URI directement
sans ce piège. Le rôle ne doit jamais être modifié pour utiliser
`Acquire::http::Proxy`.

### Variables principales

Voir `roles/apt/defaults/main.yaml`. Points clés :

- `pkgcache_apt.cache_host` : sous-domaine du cache.
- `pkgcache_apt.mirrors` : liste des mirrors à templater (origine, suites,
  composants, clé de signature).
- `pkgcache_apt.manage_default_sources` : si vrai (défaut), désactive
  (renomme en `.disabled-by-pkgcache`) les fichiers de sources par défaut
  (`ubuntu.sources`, `debian.sources`, `sources.list`) pour éviter les
  doublons avec les mirrors publics.

## Rôle `dnf`

Un fichier `.repo` par entrée sous `/etc/yum.repos.d`, `baseurl` avec
credentials embarqués dans l'URI (fonctionne nativement, pas de piège
proxy/mirror comme apt). Le cache proxie `dl.fedoraproject.org`
path-for-path (`pub/fedora/...`), sans réécriture de layout.

## Rôle `pacman`

pacoloco sert les repos sous son propre chemin `/repo/archlinux/<repo>`.
Le rôle génère un mirrorlist unique (`/etc/pacman.d/pkgcache-mirrorlist`,
`$repo`/`$arch` littéraux substitués par pacman) et régénère entièrement
`/etc/pacman.conf` (backup automatique) avec chaque dépôt de
`pkgcache_pacman.repositories` pointé dessus via `Include`.

## Rôle `nix`

Ajoute un `extra-substituters` + `extra-trusted-public-keys` à
`/etc/nix/nix.conf` (bloc géré via marqueurs, le reste du fichier n'est
pas touché). Contrairement aux autres rôles, les identifiants ne sont
**pas** embarqués dans l'URI ni dans `nix.conf` (qui reste world-readable)
mais dans un fichier `netrc-file` dédié (`/etc/nix/netrc-pkgcache`, mode
`0600`) — mécanisme natif de Nix pour l'auth HTTP sans exposer les creds
dans la config principale.

`trusted-public-keys` reste la clé de `cache.nixos.org` : ce cache est un
proxy transparent devant `cache.nixos.org`, il ne re-signe rien — ne
jamais la remplacer par une clé maison.

## Rôle `pkg` (FreeBSD)

⚠️ **Expérimental** : validé côté serveur uniquement via `curl` (requêtes
`meta.conf`/`packagesite.pkg` propres), pas avec un vrai client `pkg` — le
runbook serveur note explicitement ce risque (une lib cliente qui marche
avec `curl` ne garantit pas un comportement identique dans le vrai
gestionnaire de paquets, comme ça a été le cas pour l'hypothèse mTLS
initiale d'apt). À valider sur une vraie machine FreeBSD avant usage
flotte.

Réécrit `/etc/pkg/repos/FreeBSD.conf` (réutilise le nom de repo standard
`FreeBSD`, c'est ce qui permet d'écraser le repo de base sans repo
additionnel à activer séparément) :

```
FreeBSD: {
  url: "pkg+https://user:pass@freebsd-cache.pkg.etsmtl.club/${ABI}/latest",
  mirror_type: "srv",
  signature_type: "fingerprints",
  fingerprints: "/usr/share/keys/pkg",
  enabled: yes
}
```

## Identifiants — tous les rôles

Ne jamais committer `pkgcache_<role>.credentials.username` / `.password`
en clair. Ils doivent venir d'un vault, via `host_vars` ou `group_vars`,
par ex. pour apt :

```yaml
# group_vars/all/vault.yml (chiffré avec ansible-vault)
vault_pkgcache_apt_username: "fleet"
vault_pkgcache_apt_password: "..."
```

```yaml
# group_vars/all/pkgcache.yml
pkgcache_apt:
  credentials:
    username: "{{ vault_pkgcache_apt_username }}"
    password: "{{ vault_pkgcache_apt_password }}"
```

Même pattern pour `pkgcache_dnf`, `pkgcache_pacman`, `pkgcache_nix`,
`pkgcache_pkg`, `pkgcache_opnsense` — chaque flavor a son propre secret
côté serveur (rotation indépendante, voir credentials-runbook.md), donc
des variables vault distinctes par rôle.

Chaque rôle échoue explicitement (`assert`) si ses identifiants sont
vides, et marque sa tâche de templating `no_log: true` pour ne jamais
faire fuiter les creds dans les logs Ansible. Les fichiers générés
contenant des secrets en clair sont écrits en mode `0600`.

## Utilisation

```yaml
- name: Configurer le cache de paquets interne
  hosts: all
  roles:
    - role: cedille.pkgcache.apt
      when: ansible_distribution in ["Ubuntu", "Debian"]
    - role: cedille.pkgcache.dnf
      when: ansible_distribution == "Fedora"
    - role: cedille.pkgcache.pacman
      when: ansible_distribution == "Archlinux"
    - role: cedille.pkgcache.nix
      when: pkgcache_nix_hosts | default(false)
```

## Vue d'ensemble

Chaque rôle suit la même logique de base :

1. valider que les identifiants nécessaires sont disponibles (`assert`);
2. templater la configuration native du gestionnaire de paquets pour
   pointer vers le cache interne (`no_log: true`, fichiers `0600` quand
   ils contiennent des secrets);
3. idempotence : ré-application sans effet de bord si rien n'a changé.

Détails serveur complets (topologie, runbook credentials, patterns exacts
par flavor) : `apps/pkg-cache/docs/credentials-runbook.md` dans
`ClubCedille/k8s-shared`.
