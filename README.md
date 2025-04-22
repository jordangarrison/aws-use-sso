# AWS SSO Profile Credential Exporter

A simple utility to export AWS SSO credentials to environment variables, packaged with Nix flakes.

## Description

This tool automates the process of:

1. Logging into AWS SSO with a specified profile
2. Exporting the credentials to a file
3. Setting up environment variables for AWS CLI access

## Quick Start with Devbox

This quick start guide shows how to use AWS SSO Profile with [Devbox](https://www.jetify.com/docs/devbox/) to create an isolated development environment with AWS credentials properly set up.

### 1. Set up Devbox

If you don't have Devbox installed yet, follow the [official installation guide](https://www.jetify.com/docs/devbox/quickstart/).

### 2. Add AWS SSO Profile to your Devbox project

#### For a project-specific installation

```sh
# Initialize devbox if you haven't already
devbox init

# Add the AWS SSO Profile tool
devbox add github:jordangarrison/aws-use-sso

# Or specify a version
devbox add github:jordangarrison/aws-use-sso/v1.0.0
```

#### For a global installation

```sh
# Create a global devbox configuration
mkdir -p ~/.config/devbox/global
cd ~/.config/devbox/global
devbox init
devbox add github:jordangarrison/aws-use-sso
```

### 3. Use AWS SSO Profile in your Devbox shell

```sh
# Start the devbox shell
devbox shell

# Log in with your AWS SSO profile
aws-use-sso-profile your-sso-profile-name

# Source the generated credentials file
source ~/.aws/sso-creds.sh
```

### 4. Launch tools with AWS credentials

Once you've sourced the credentials file, any application launched from that shell will inherit the AWS environment variables.

This is particularly useful for:

- Code editors: `code .` (VS Code) or `cursor .` (Cursor) etc...
- IDE: `idea .` (IntelliJ IDEA)
- AI coding agents/assistants, which will inherit your AWS credentials
- AWS CLI commands: `aws s3 ls`
- Terraform/CDK deployments

Example workflow:

```sh
# Start devbox shell
devbox shell

# Authenticate with AWS SSO
aws-use-sso-profile your-sso-profile-name

# Source the credentials
source ~/.aws/sso-creds.sh

# Launch Cursor with AWS credentials in the environment
cursor .

# Now Cursor (and any extensions/terminals and ai agents inside it) will have access to your AWS credentials
```

## Installation

### Using Nix Flakes (recommended)

This project is packaged as a Nix flake, making it easy to install in a reproducible way.

#### Prerequisites

- [Nix package manager](https://nixos.org/download.html) with flakes enabled

To enable flakes, add this to your `~/.config/nix/nix.conf`:

```sh
experimental-features = nix-command flakes
```

#### Install globally

```sh
# Install the package globally
nix profile install github:jordangarrison/aws-use-sso

# Or directly from a local clone
git clone https://github.com/jordangarrison/aws-use-sso.git
cd aws-use-sso
nix profile install .
```

#### Run without installing

```sh
# Run directly without installing
nix run github:jordangarrison/aws-use-sso -- your-sso-profile-name

# Or from a local clone
git clone https://github.com/jordangarrison/aws-use-sso.git
cd aws-use-sso
nix run . -- your-sso-profile-name
```

#### Development Shell

To enter a development environment with all dependencies:

```sh
# From a remote repository
nix develop github:jordangarrison/aws-use-sso

# Or from a local clone
git clone https://github.com/jordangarrison/aws-use-sso.git
cd aws-use-sso
nix develop
```

The development shell will automatically source your AWS credentials file if you have one.

#### Using with Devbox

You can add this tool to your [Devbox](https://www.jetify.com/devbox/) project:

```sh
# Add the flake from GitHub
devbox add github:jordangarrison/aws-use-sso

# Or add from a local clone
devbox add path:/path/to/aws-use-sso
```

Your `devbox.json` will be updated with a reference to the flake:

```json
{
  "packages": [
    "github:jordangarrison/aws-use-sso"
  ]
}
```

Then start a Devbox shell to use the tool:

```sh
devbox shell
```

To cache the flake for faster startup times:

```sh
devbox cache upload github:jordangarrison/aws-use-sso
```

#### Add to Your NixOS Configuration

You can add this tool to your NixOS configuration flake for a system-wide installation:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    aws-use-sso.url = "github:jordangarrison/aws-use-sso";
  };

  outputs = { self, nixpkgs, aws-use-sso, ... }: {
    nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux"; # or your system architecture
      modules = [
        # Your other modules...
        ({ pkgs, ... }: {
          environment.systemPackages = [
            aws-use-sso.packages.${pkgs.system}.default
          ];
        })
      ];
    };
  };
}
```

For home-manager users, you can add it to your home configuration:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    aws-use-sso.url = "github:jordangarrison/aws-use-sso";
  };

  outputs = { self, nixpkgs, home-manager, aws-use-sso, ... }: {
    homeConfigurations."your-username" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux; # or your system architecture
      modules = [
        # Your other modules...
        ({ pkgs, ... }: {
          home.packages = [
            aws-use-sso.packages.${pkgs.system}.default
          ];
        })
      ];
    };
  };
}
```

## Usage

```sh
aws-use-sso-profile <profile-name>
```

Where `<profile-name>` is the name of a valid AWS SSO profile configured in your `~/.aws/config` file.

## How it Works

1. The script logs you into AWS SSO using the specified profile
2. It exports the credentials to `~/.aws/sso-creds.sh`
3. It sources this file, setting the required AWS environment variables

After running the script, your shell will have the necessary AWS environment variables set to interact with AWS services.

## Requirements

- AWS CLI v2
- Configured AWS SSO profile(s)

## License

[MIT](LICENSE)
