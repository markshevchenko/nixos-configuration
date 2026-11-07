{ config, pkgs, lib, unstablePkgs, ... }:

{
  home-manager.useGlobalPkgs = true;
  home-manager.users.mark = { pkgs, ... }:
  let
  openIDEEnv = pkgs.buildFHSEnv {
    name = "openide";
    targetPkgs = pkgs: with pkgs; [
      glibc
      zlib
      stdenv.cc.cc.lib
    ];
    runScript = pkgs.writeShellScript "run-openide" ''
      export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath [
        pkgs.libX11
        pkgs.libXext
        pkgs.libXi
        pkgs.libXrender
        pkgs.libXtst
        pkgs.libXxf86vm
        pkgs.gtk3
        pkgs.glibc
        pkgs.freetype
        pkgs.fontconfig
      ]}:$LD_LIBRARY_PATH
      exec /home/mark/openide/bin/openide "$@"
    '';
  };

  # nixpkgs unstable packages 3.25.9. 3.27.22 is the current Cursor stable release.
  cursorVersion = "3.27.22";
  code-cursor = pkgs.code-cursor.overrideAttrs (old: {
    version = cursorVersion;
    name = "cursor-${cursorVersion}";
    src = pkgs.appimageTools.extract {
      pname = "cursor";
      version = cursorVersion;
      src = pkgs.fetchurl {
        url = "https://downloads.cursor.com/production/b1aa50cb6db84fd3e8c808259cb172ea73425c1f/linux/x64/Cursor-${cursorVersion}-x86_64.AppImage";
        hash = "sha256-TbL+Na4ZIwHdWzQjedCgQavb3W2QKe/ggwCM/aoC+A4=";
      };
    };
    sourceRoot = "cursor-${cursorVersion}-extracted/usr/share/cursor";
  });
  in
  {
    home = {
      username = "mark";
      homeDirectory = "/home/mark";
      packages = with pkgs; [
        firefox
        chromium
        code-cursor
        telegram-desktop
        vlc
        inkscape
        libreoffice-qt6
        obs-studio
        kdiff3
        gimp-with-plugins
        traceroute
        tcpdump
        bind.dnsutils
        claude-code
        openIDEEnv
      ] ++ [
        (writeShellScriptBin "claude-aitunnel" ''
          export ANTHROPIC_BASE_URL="https://api.aitunnel.ru"
          export ANTHROPIC_AUTH_TOKEN="$(cat ${config.sops.secrets.aitunnel-token.path})"
          export ANTHROPIC_API_KEY=""
          exec ${pkgs.claude-code}/bin/claude "$@"        '')
      ] ++ lib.optionals config.services.desktopManager.plasma6.enable [
        kdePackages.kcharselect
      ];

      # This value determines the Home Manager release that your configuration is
      # compatible with. This helps avoid breakage when a new Home Manager release
      # introduces backwards incompatible changes.
      #
      # You should not change this value, even if you update Home Manager. If you do
      # want to update the value, then make sure to first check the Home Manager
      # release notes.
      stateVersion = "25.11"; # Please read the comment before changing.
    };

    programs.vscode = {
      enable = true;
      profiles.default = {
        extensions = with pkgs.vscode-extensions; [
          anthropic.claude-code
          bbenoist.nix
          docker.docker
          golang.go
          ionide.ionide-fsharp
          mhutchie.git-graph
          ms-vscode.remote-explorer
          ms-vscode-remote.remote-ssh
          ms-vscode-remote.remote-ssh-edit
          ms-vsliveshare.vsliveshare
          ocamllabs.ocaml-platform
          rust-lang.rust-analyzer
          streetsidesoftware.code-spell-checker
          tomoki1207.pdf
          vadimcn.vscode-lldb
          ms-vscode.cpptools
          ms-vscode.cpptools-extension-pack
          ms-vscode.makefile-tools
        ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          {
            name = "insert-unicode";
            publisher = "brunnerh";
            version = "0.15.1";
            sha256 = "sha256-RHsq7JmlC+4zGSbDdovCZpjpSW+DvcmYnuz9f6F/N4g=";
          }
          {
            name = "code-spell-checker-russian";
            publisher = "streetsidesoftware";
            version = "2.2.4";
            sha256 = "sha256-Vn/Vu502A9qPVHfnJ3CZUXcM2knIIG6bJHce0r72Rv0=";
          }
          {
            name = "bison-flex-lang";
            publisher = "theodevelop";
            version = "1.5.3";
            sha256 = "sha256-5OkiUb16vhkJDox4fB0TU8ABwy2XNsKHM3vH5Q5KKEI=";
          }
          {
            name = "opencode";
            publisher = "sst-dev";
            version = "1.0.0";
            sha256 = "sha256-3eyBWrmkpIGzUeHqKXmWaIpEPZrALLIbfZtCPOMV4MQ=";
          }
        ];
        # Optional: configure user settings declaratively
        userSettings = {
          "cSpell.language" = "en,ru";
          "chat.disableAIFeatures" = true;
          "claudeCode.claudeProcessWrapper" = "/home/mark/.nix-profile/bin/claude-aitunnel";
          "claudeCode.preferredLocation" = "panel";
          "editor.bracketPairColorization.enabled" = false;
          "editor.fontSize" = 14;
          "git.blame.editorDecoration.enabled" = true;
          "git.confirmSync" = false;
          "git.enableSmartCommit" = true;
          "git.mergeEditor" = true;
          "gopls" = {
            "ui.semanticTokens" = true;
          };
          "makefile.configureOnOpen" = false;
          "mcpServers" = {};
          "window.zoomLevel" = 1.4;
          "workbench.editor.enablePreview" = false;
          "workbench.colorTheme" = "Visual Studio Dark";
          "C_Cpp.default.compilerPath" = "/run/current-system/sw/bin/gcc";
          "C_Cpp.default.intelliSenseMode" = "linux-gcc-x64";
          "C_Cpp.default.cStandard" = "c17";
          "C_Cpp.default.includePath" = [
            "/run/current-system/sw/include"
            "${pkgs.glibc.dev}/include"
          ];
          "clangd.path" = "/run/current-system/sw/bin/clangd";
        };
      };
    };

    programs.opencode = {
      enable = true;
      enableMcpIntegration = true;
      package = unstablePkgs.opencode; # 2.x
      settings = {
        model = "opencode/deepseek-v4.1-flash-free";
        agents = {
          explore = {
            model = "opencode/deepseek-v4.1-flash-free";
          };
          general = {
            model = "aitunnel/qwen3.7-plus";
          };
          reviewer = {
            description = "Reviews changes for correctness and regressions";
            mode = "subagent";
            model = "aitunnel/glm-5.3";
            permissions = [
              { action = "edit"; resource = "*"; effect = "deny"; }
              { action = "shell"; resource = "*"; effect = "deny"; }
            ];
          };
          lead = {
            description = "Decomposes an epic issue into issues and a work plan for each issue";
            mode = "subagent";
            model = "aitunnel/glm-5.3";
            permissions = [
              { action = "edit"; resource = "*"; effect = "deny"; }
              { action = "shell"; resource = "*"; effect = "deny"; }
            ];
          };
          analyst = {
            description = "Turns a brief issue description into use cases";
            mode = "subagent";
            model = "aitunnel/qwen3.7-plus";
            permissions = [
              { action = "edit"; resource = "*"; effect = "deny"; }
              { action = "shell"; resource = "*"; effect = "deny"; }
            ];
          };
          tester = {
            description = "Generates test cases";
            mode = "subagent";
            model = "aitunnel/glm-5.3-flash";
            permissions = [
              { action = "edit"; resource = "*"; effect = "deny"; }
              { action = "shell"; resource = "*"; effect = "deny"; }
            ];
          };
          coder = {
            description = "Writes code and unit and integration tests from a test case list";
            mode = "subagent";
            model = "aitunnel/deepseek-v4.1-flash";
            permissions = [
              { action = "edit"; resource = "*"; effect = "allow"; }
              { action = "shell"; resource = "*"; effect = "allow"; }
            ];
          };
        };
        providers = {
          aitunnel = {
            name = "AITUNNEL";
            env = [ "AITUNNEL_API_KEY" ];
            package = "@opencode/ai/providers/openai-compatible";
            settings = {
              baseURL = "https://api.aitunnel.ru/v1";
              apiKey = "{file:${config.sops.secrets.aitunnel-opencode-token.path}}";
            };
            models = {
              "deepseek-v4.1-flash" = {
                name = "DeepSeek V4.1 Flash";
                limit = { context = 1048576; output = 384000; };
                capabilities = {
                  tools = true;
                  input = [ "text" "image" ];
                  output = [ "text" ];
                  reasoning = { supported = true; effort = [ "low" "medium" "high" ]; };
                };
              };
              "glm-5.3" = {
                name = "GLM 5.3";
                limit = { context = 1048576; output = 131072; };
                capabilities = {
                  tools = true;
                  input = [ "text" ];
                  output = [ "text" ];
                  reasoning = { supported = true; effort = [ "low" "medium" "high" ]; };
                };
              };
              "glm-5.3-flash" = {
                name = "GLM 5.3 Flash";
                limit = { context = 1048576; output = 131072; };
                capabilities = {
                  tools = true;
                  input = [ "text" "image" ];
                  output = [ "text" ];
                  reasoning = { supported = true; effort = [ "low" "medium" "high" ]; };
                };
              };
              "qwen3.7-plus" = {
                name = "Qwen 3.7 Plus";
                limit = { context = 1000000; output = 65536; };
                capabilities = {
                  tools = true;
                  input = [ "text" "image" ];
                  output = [ "text" ];
                  reasoning = { supported = true; effort = [ "low" "medium" "high" ]; };
                };
              };
            };
          };
        };
      };
    };
  };
}
