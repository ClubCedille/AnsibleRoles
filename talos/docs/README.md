# Collection Talos pour la maintenance mécanique des clusters Omni

## Vue d'ensemble

La collection `cedille.talos` regroupe les rôles nécessaires pour mettre à
jour Talos et Kubernetes sur des clusters gérés par Omni
(`cedille.na-west-1.omni.siderolabs.io` pour k8s-shared et
k8s-cedille-production-v2 — voir mémoire `project_omni_two_instances`, pas
`omni.etsmtl.club` qui gère uniquement k8s-poc).

Volontairement **purement mécanique** : ces rôles ne décident jamais eux-mêmes
qu'un node peut être cordonné/upgradé — ils vérifient une précondition
d'état et échouent explicitement si elle n'est pas remplie, plutôt que de
deviner. Vider les workloads stuck sur un node reste une action manuelle de
l'opérateur (voir runbook plus bas) : pas de RBAC pods/eviction dans cette
collection, uniquement get/list/patch sur `nodes`.

## Rôles disponibles

- `cordon` — cordonne ou décordonne un node (`talos_cordon_state:
  cordoned|uncordoned`), via un kubeconfig éphémère obtenu du service account
  Omni (`omnictl kubeconfig --service-account`, groupe RBAC scopé, TTL court).
  Aucun kubeconfig stocké.
- `update_talos` — upgrade Talos OS sur **un seul node** (`talosctl upgrade`
  est par nature une opération par-machine). Échoue si le node n'est pas
  cordonné, ou déjà à la version cible.
- `update_k8s` — upgrade Kubernetes sur **le cluster entier**
  (`talosctl upgrade-k8s` orchestre lui-même control-plane + kubelets, pas de
  notion "par node"). Échoue si un seul node du cluster n'est pas encore à la
  version Talos attendue.

## Prérequis — bootstrap one-shot par cluster

### 1. Service account Omni

Un seul SA pour les deux clusters (même instance Omni cloud) :

```bash
omnictl config context cedille-shared
omnictl serviceaccount create omni-github-actions --use-user-role=false --role Operator --ttl 8760h
```

`Operator`, pas `Admin` — suffisant pour modifier les ressources `Cluster` et
lire les `MachineStatus`, sans les droits d'administration Omni (gestion des
users/SA). La clé produite est `talos_omni_service_account_key`, à vaulter
dans AnsibleInfra et à ne **jamais** confondre avec le SA `omni-ansible`
existant (breaking-glass Admin de l'instance self-hébergée, cluster k8s-poc
uniquement — voir `AnsibleInfra/docs/omni-saml-auth.md`).

### 2. RBAC K8s scopé (une fois par cluster)

Le rôle `cordon` s'identifie avec le groupe `cedille:talos-cordon` (variable
`talos_cordon_k8s_group`) — ce groupe doit déjà être lié à un ClusterRole
minimal dans chaque cluster cible avant le premier run :

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cedille-talos-cordon
rules:
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["get", "list", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cedille-talos-cordon
subjects:
  - kind: Group
    name: cedille:talos-cordon
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cedille-talos-cordon
  apiGroup: rbac.authorization.k8s.io
```

À appliquer manuellement (`kubectl apply -f ...`) avec un accès admin
existant, une seule fois par cluster — pas géré par cette collection.

## Runbook opérateur — upgrade d'un cluster

Répéter les étapes 1 à 4 pour **chaque node**, puis lancer l'étape 5 une fois
pour tout le cluster :

```bash
make omni/cordon-node LIMIT=k8s-shared-worker-0
# vider manuellement les workloads stuck sur ce node (kubectl)
make omni/update-talos LIMIT=k8s-shared-worker-0 EXTRA_VARS="talos_target_version=1.13.8 talos_schematic_id=..."
make omni/uncordon-node LIMIT=k8s-shared-worker-0
# ... répéter pour chaque node du cluster ...
make omni/update-k8s EXTRA_VARS="talos_target_kubernetes_version=1.34.1 talos_expected_version=1.13.8"
```

Chaque target échoue explicitement (pas de résultat silencieux ni de
supposition) si l'état constaté ne correspond pas à ce que l'étape attend —
c'est le signal pour intervenir manuellement puis relancer la même commande.

## À vérifier avant le premier run réel

Le parsing de `omnictl get machinestatus -o yaml` (adresse IP, version Talos
installée, label de rôle control-plane) dans `update_talos` et `update_k8s`
est un best-effort écrit sans accès direct à une sortie réelle (clé Omni
expirée + mismatch de version `omnictl` au moment de l'écriture, voir mémoire
`project_talos_collection_github_sa`). Chaque task de parsing échoue avec la
sortie brute en cas d'échec plutôt que de deviner — utiliser ce message pour
ajuster les regex si le format observé diffère.
