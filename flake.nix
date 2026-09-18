{
  description = "Environnement de dev pour AnsibleRoles (Ansible + Molecule/Docker)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            python3
            git
            gnumake
            openssh
            sshpass
            docker-client # client uniquement : le daemon docker doit tourner sur l'hôte
          ];

          shellHook = ''
            # Crée/rafraîchit le venv (ansible-core, molecule, molecule-plugins[docker],
            # ansible-lint, yamllint) depuis requirements-dev.txt.
            if [ ! -d .venv ] || [ requirements-dev.txt -nt .venv/.deps-installed ]; then
              echo "[flake] (ré)installation du venv depuis requirements-dev.txt..."
              python3 -m venv .venv
              .venv/bin/pip install --upgrade pip >/dev/null
              .venv/bin/pip install -r requirements-dev.txt
              touch .venv/.deps-installed
            fi
            source .venv/bin/activate

            if ! docker info >/dev/null 2>&1; then
              echo "[flake] Attention: docker n'est pas accessible (daemon down ou permissions) — molecule ne fonctionnera pas." >&2
            fi
          '';
        };
      });
}
