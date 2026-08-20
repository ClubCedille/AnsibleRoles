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
    version: "0.1.0"
```

## Rôles disponibles

| Rôle      | Statut          | Auth                    | Suivi                                |
|-----------|-----------------|--------------------------|---------------------------------------|
| `apt`     | Fonctionnel      | BasicAuth (mirror direct) | Validé en live (PR serveur à venir)  |
| `nix`     | Squelette        | BasicAuth (prévu)         | `ClubCedille/k8s-shared#395`          |
| `dnf`     | Squelette        | mTLS (à valider)          | `ClubCedille/k8s-shared#394`          |
| `pacman`  | Squelette        | mTLS (à valider)          | `ClubCedille/k8s-shared#394`          |
| `pkg`     | Squelette        | mTLS (à valider)          | `ClubCedille/k8s-shared#394`          |

Les rôles squelettes (`nix`, `dnf`, `pacman`, `pkg`) échouent explicitement
(`ansible.builtin.fail`) si on les active (`pkgcache_<role>.enabled: true`)
avant qu'ils soient réellement implémentés — ils ne font rien par défaut
(`enabled: false`). Intégration Ansible globale suivie sur
`ClubCedille/k8s-shared#396`.

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
test live : proxy → 401 systématique, mirror direct → fonctionne. Ce
n'est pas une erreur de config côté serveur, c'est un choix imposé par le
comportement du client HTTPS d'apt (GnuTLS), qui ne gère pas non plus
fiablement l'auth par certificat client — d'où BasicAuth plutôt que mTLS
pour apt et Nix. Le rôle ne doit jamais être modifié pour utiliser
`Acquire::http::Proxy`.

### Identifiants

Ne jamais committer `pkgcache_apt.credentials.username` /
`.password` en clair. Ils doivent venir d'un vault, via `host_vars` ou
`group_vars`, par ex. :

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

Le rôle échoue explicitement (`assert`) si ces valeurs sont vides, et
marque la tâche de templating `no_log: true` pour ne jamais faire fuiter
les identifiants dans les logs Ansible. Les fichiers `.sources` générés
sont écrits en mode `0600` (`root:root`) puisqu'ils contiennent le mot de
passe en clair, comme le format `URIs:` mirror-direct l'exige.

### Variables principales

Voir `roles/apt/defaults/main.yaml`. Points clés :

- `pkgcache_apt.cache_host` : sous-domaine du cache (`apt-cache.pkg.etsmtl.club`).
- `pkgcache_apt.mirrors` : liste des mirrors à templater (origine, suites,
  composants, clé de signature).
- `pkgcache_apt.manage_default_sources` : si vrai (défaut), désactive
  (renomme en `.disabled-by-pkgcache`) les fichiers de sources par défaut
  (`ubuntu.sources`, `debian.sources`, `sources.list`) pour éviter les
  doublons avec les mirrors publics.

## Utilisation

```yaml
- name: Configurer le cache de paquets interne
  hosts: all
  roles:
    - cedille.pkgcache.apt
      when: ansible_os_family == "Debian"
```

## Vue d'ensemble

Chaque rôle suit la même logique de base :

1. valider que les identifiants/certificats nécessaires sont disponibles;
2. templater la configuration native du gestionnaire de paquets pour
   pointer vers le cache interne;
3. idempotence : ré-application sans effet de bord si rien n'a changé.

Détails serveur complets (topologie, runbook credentials, pattern exact de
`sources.list`) : `apps/pkg-cache/docs/credentials-runbook.md` dans
`ClubCedille/k8s-shared`.
