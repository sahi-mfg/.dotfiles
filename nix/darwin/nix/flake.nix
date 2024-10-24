{
  description = "Sahi's Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew }: 
  let
    configuration = { pkgs, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [ 
          pkgs.alacritty
          pkgs.neovim
        ];

        fonts.packages = [
          (pkgs.nerdfonts.override { fonts = ["JetBrainsMono"]; })
        ];

        homebrew = {
          enable = true;
          brews = [
             "mas"
            "eza"
            "zoxide"
            "zsh-autosuggestions"
            "zsh-syntax-highlighting"
            "powerlevel10k"
            "thefuck"
            "fzf"
            "bat"
            "docker"
            "docker-compose"
            "docker-completion"
          ]; 
          casks = [
            "the-unarchiver"
            "iina"
          ];
          masApps = {
            #"Yoink" = 457622435;
         };
          onActivation.cleanup = "zap";
          onActivation.autoUpdate = true;
          onActivation.upgrade = true;
        };

      system.defaults = {
        dock.autohide = true;
        dock.persistent-apps = [
          "System/Applications/Mail.app"
          "System/Applications/Calendar.app"
          "${pkgs.alacritty}/Applications/Alacritty.app"
        ]; 

        finder.FXPreferredViewStyle = "clmv";
        finder._FXSortFoldersFirst = true;
        NSGlobalDomain.AppleInterfaceStyle = "Dark";
        NSGlobalDomain.KeyRepeat = 2;
      };
      # Auto upgrade nix package and the daemon service.
      services.nix-daemon.enable = true;
      # nix.package = pkgs.nix;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh.enable = true;  # default shell on catalina
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 5;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in

  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#MacBook-Air-de-Mohamed-Francis-Sahi
    darwinConfigurations."MacBook-Air-de-Mohamed-Francis-Sahi" = nix-darwin.lib.darwinSystem {
      modules = [ 
        configuration 
        nix-homebrew.darwinModules.nix-homebrew 
        {
          nix-homebrew = {
            enable = true;
            # Apple Silicon Only
            enableRosetta = true;
            # User owning the homebrew prefix
            user = "sahi";
            autoMigrate = true;
          };
        }
      ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."MacBook-Air-de-Mohamed-Francis-Sahi".pkgs;
  };
}
