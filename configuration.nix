# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

let
  # release-26.05, 2026-10-24
  home-manager = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/24f2190587513b9c2f73db112a17844ae912d965.tar.gz";
    sha256 = "0z9ivs49j8n7r20kbyh86x59fl3izd90407djz678jfmwvp65pyp";
  };

  # master, 2026-10-26. Отдельной ветки release-26.05 у sops-nix нет.
  sops-nix = builtins.fetchTarball {
    url = "https://github.com/Mic92/sops-nix/archive/60182817ee048ac94b4c68ea76d5ef2e8aac730d.tar.gz";
    sha256 = "0fk81bs1c8c3p8ab3152a4hw6qjqkcdli6pw1ndyd56c74fliwk3";
  };
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./home.nix
      "${home-manager}/nixos"
      "${sops-nix}/modules/sops"
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  networking = {
    hostName = "marklab";
    domain = "local";

    nameservers = [
      "77.88.8.8"
      "77.88.8.1"
      "8.8.8.8"
      "8.8.4.4"
    ];

    #wireless.enable = true;  # Enables wireless support via wpa_supplicant.

    # Configure network proxy if necessary
    #proxy.default = "http://user:password@proxy:port/";
    #proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    # Enable networking
    networkmanager = {
      enable = true;
      # dns = "systemd-resolved";
      dns = "none";
    };
  };

  # services.resolved = {
  #   enable = true;
  #   settings = {
  #     Resolve = {
  #       Domains = [ "~." ];
  #       FallbackDns = [ "8.8.8.8" "8.8.4.4" ];
  #       DNSSEC = "allow-downgrade";
  #     };
  #   };
  # };

  # Set your time zone.
  time.timeZone = "Europe/Moscow";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ru_RU.UTF-8";
    LC_IDENTIFICATION = "ru_RU.UTF-8";
    LC_MEASUREMENT = "ru_RU.UTF-8";
    LC_MONETARY = "ru_RU.UTF-8";
    LC_NAME = "ru_RU.UTF-8";
    LC_NUMERIC = "ru_RU.UTF-8";
    LC_PAPER = "ru_RU.UTF-8";
    LC_TELEPHONE = "ru_RU.UTF-8";
    LC_TIME = "ru_RU.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  # Configure keymap in X11
  services.xserver = {
    xkb.layout = "us";
    xkb.variant = "";
  };

  # Enable the KDE Desktop Environment.
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Enable automatic login for the user.
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "mark";

  # How to automatically unlock kwallet at start up?
  # https://discourse.nixos.org/t/how-to-automatically-unlock-kwallet-at-start-up/61308
  security.pam = lib.mkIf config.services.desktopManager.plasma6.enable {
    # If enabled, pam_wallet will attempt to automatically unlock the user’s default KDE wallet upon login.
    # If the user has no wallet named “kdewallet”, or the login password does not match their wallet password,
    # KDE will prompt separately after login.
    services.mark.kwallet = {
      enable = true;
      package = pkgs.kdePackages.kwallet-pam;
    };
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  #services.xserver.libinput.enable = true;

  virtualisation.docker = { 
    enable = true;
    autoPrune.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.mark = {
    isNormalUser = true;
    description = "Mark Shevchenko";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
  };

  programs.nix-ld.enable = true;
  programs.nix-ld.package = pkgs.nix-ld;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    zlib
    icu
    openssl
    curl
  ];

  # programs.amnezia-vpn.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # sops
  sops = {
    defaultSopsFile = ./secrets/secrets.yaml;
    # Will not be copied to /nix/store:
    age.keyFile = "/etc/age/identity.key";

    secrets = {
      aitunnel-token = {
        owner = "mark";
      };

      "openvpn/wb/ca" = {
        owner = "root";
      };

      "openvpn/wb/cert" = {
        owner = "root";
      };

      "openvpn/wb/key" = {
        owner = "root";
      };

      "openvpn/wb/tls-crypt" = {
        owner = "root";
      };

      "openvpn/wb/askpass" = {
        owner = "root";
      };
    };
  };

  # Enable Polkit
  security.polkit.enable = true;
  
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    docker-compose
    git
    openvpn3
    update-systemd-resolved
    age
    sops
    distrobox
  ];

  # services.resolved = {
  #   enable = true;
  # };

  # OpenVPN
  programs.openvpn3.enable = true;
  services.openvpn.servers = {
    wb = {
      config = ''
        client
        dev tun
        tun-mtu 1372
        proto udp
        remote openvpn.wb.ru 1194
        resolv-retry 10
        nobind
        persist-key
        persist-tun
        ca ${config.sops.secrets."openvpn/wb/ca".path}
        cert ${config.sops.secrets."openvpn/wb/cert".path}
        key ${config.sops.secrets."openvpn/wb/key".path}
        tls-crypt ${config.sops.secrets."openvpn/wb/tls-crypt".path}
        askpass ${config.sops.secrets."openvpn/wb/askpass".path}
        remote-cert-tls server
        key-direction 1
        cipher AES-256-GCM
        auth SHA256
        verb 4
        push-peer-info
        setenv FRIENDLY_NAME "WB VPN"
      '';


      # dhcp-option DOMAIN-ROUTE .
      # script-security 2
      # setenv PATH /run/current-system/sw/bin:/etc/profiles/per-user/root/current-system/profile/bin
      # up ${pkgs.update-systemd-resolved}/libexec/openvpn/update-systemd-resolved
      # down ${pkgs.update-systemd-resolved}/libexec/openvpn/update-systemd-resolved
      # up-restart
      # down-pre

      updateResolvConf = true;
      autoStart = false;
    };
  };

  # Ministry of Digital Development root (public) certificate
  security.pki.certificates = [
    ''
    -----BEGIN CERTIFICATE-----
    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
    NLWh
    -----END CERTIFICATE-----
    ''
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  #networking.firewall.allowedUDPPorts = [ 51820 ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
