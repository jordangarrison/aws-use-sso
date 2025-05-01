{
  description = "Script to export AWS SSO credentials to environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "aws-use-sso";
          version = "1.0.1";
          src = ./.;

          installPhase = ''
            mkdir -p $out/bin
            cp aws-use-sso-profile.sh $out/bin/aws-use-sso
            chmod +x $out/bin/aws-use-sso
          '';

          buildInputs = [ pkgs.bash pkgs.awscli2 ];
        };

        apps.default = flake-utils.lib.mkApp {
          drv = self.packages.${system}.default;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.awscli2
            pkgs.bash
          ];

          shellHook = ''
            if [ -f ~/.aws/sso-creds.sh ]; then
              source ~/.aws/sso-creds.sh
            fi
          '';
        };
      });
}
