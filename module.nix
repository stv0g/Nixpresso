# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{ self }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    escapeShellArgs
    getExe
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    types
    ;

  cfg = config.services.nixpresso;
in
{
  options = {
    services.nixpresso = {
      enable = mkEnableOption "Nixpresso HTTP server";

      package = mkPackageOption pkgs "nixpresso" { };

      settings = {

        handler = mkOption {
          description = "Nix 'installable' (a Flake reference or attribute) Nix function to handle requests.";
          type = types.str;
          example = "github:stv0g/nixpresso";
        };

        debug = mkOption {
          description = "Enable debug logging.";
          type = types.nullOr types.bool;
          example = true;
          default = null;
        };

        evalCache = mkOption {
          description = "Enable evaluation caching.";
          type = types.nullOr types.bool;
          example = true;
          default = null;
        };

        verbose = mkOption {
          description = "Verbosity level.";
          type = types.nullOr types.int;
          example = 10;
          default = null;
        };

        listenAddress = mkOption {
          description = "Listen address.";
          type = types.str;
          default = ":8080";
        };

        allowedModes = mkOption {
          description = "Allowed response modes.";
          type = types.listOf (
            types.enum [
              "serve"
              "log"
              "derivation"
              "run"
            ]
          );
          default = [ ];
        };

        allowedTypes = mkOption {
          description = "Allowed response types.";
          type = types.listOf (
            types.enum [
              "path"
              "derivation"
              "string"
            ]
          );
          default = [ ];
        };

        allowedPaths = mkOption {
          description = "Allowed paths from which content can be served or executed.";
          type = types.listOf types.path;
          example = [
            "/nix/store"
            "/home/jovyan/share/"
          ];
          default = [ ];
        };

        allowStore = mkOption {
          description = "Allow serving or executing content from the Nix store.";
          type = types.nullOr types.bool;
          default = null;
        };

        tls = {
          certificateFile = mkOption {
            description = "Path to the TLS certificate file.";
            type = types.nullOr types.path;
            example = "/var/nixpresso/cert.pem";
            default = null;
          };

          keyFile = mkOption {
            description = "Path to the TLS private key file.";
            type = types.nullOr types.path;
            example = "/var/nixpresso/key.pem";
            default = null;
          };
        };

        timeouts = {
          read = mkOption {
            description = ''
              Maximum duration for reading the entire request, including the body.
                          
              A zero or negative value means there will be no timeout.
            '';

            type = types.nullOr types.str;
            example = "5m";
            default = null;
          };

          write = mkOption {
            description = ''
              Maximum duration before timing out writes of the response.
                          
              It is reset whenever a new request's header is read.
            '';

            type = types.nullOr types.str;
            example = "5m";
            default = null;
          };

          request = mkOption {
            description = ''
              Maximum duration for the entire request (evaluation, building and running).
                          
              A zero or negative value means there will be no timeout.
            '';

            type = types.nullOr types.str;
            example = "10m";
            default = null;
          };

          eval = mkOption {
            description = ''
              Maximum duration for the evaluation phase.
                          
              A zero or negative value means there will be no timeout.
            '';

            type = types.nullOr types.str;
            example = "5m";
            default = null;
          };

          build = mkOption {
            description = ''
              Maximum duration for the build phase.
                          
              A zero or negative value means there will be no timeout.
            '';

            type = types.nullOr types.str;
            example = "5m";
            default = null;
          };

          run = mkOption {
            description = ''
              Maximum duration for the run phase.
                          
              A zero or negative value means there will be no timeout.
            '';

            type = types.nullOr types.str;
            example = "5m";
            default = null;
          };
        };

        maxSizes = {
          request = mkOption {
            description = ''
              Maximum number of bytes the server will read from the request body.

              A request will be aborted if the client attempts to send more data than this limit.
            '';

            type = types.nullOr types.int;
            default = null;
          };

          response = mkOption {
            description = ''
              Maximum number of bytes the server will read from the response body.

              A request will be aborted if the handler attempts to send more data than this limit.
            '';

            type = types.nullOr types.int;
            default = null;
          };
        };

        extraArgs = mkOption {
          description = ''
            Extra arguments to pass to Nixpresso.
          '';

          type = types.listOf types.str;
          default = [ ];
        };
      };
    };
  };

  config = mkIf cfg.enable {
    nixpkgs.overlays = [
      self.overlays.${pkgs.system}.default
    ];

    systemd.services = {
      nixpresso = {
        wants = [ "network.target" ];
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        description = "Nixpresso HTTP server";
        environment = {
          XDG_CACHE_HOME = "/var/cache/nixpresso";
        };
        serviceConfig = {
          Type = "simple";
          Restart = "on-failure";
          RestartSec = 15;
          ExecStart =
            with cfg.settings;
            (escapeShellArgs (
              [
                (getExe cfg.package)
                handler
              ]
              ++ (lib.cli.toGNUCommandLine { } {
                listen = listenAddress;
                eval-cache = evalCache;
                verbose = verbose;
                debug = debug;
                tls-cert = tls.certificateFile;
                tls-key = tls.keyFile;
                max-read-time = timeouts.read;
                max-write-time = timeouts.write;
                max-request-time = timeouts.request;
                max-eval-time = timeouts.eval;
                max-build-time = timeouts.build;
                max-run-time = timeouts.run;
                max-request-bytes = maxSizes.request;
                max-response-bytes = maxSizes.response;
                allow-mode = allowedModes;
                allow-type = allowedTypes;
                allow-path = allowedPaths;
                allow-store = allowStore;
              })
              ++ cfg.settings.extraArgs
            ));

          DynamicUser = true;
          UMask = "0007";
          CapabilityBoundingSet = "";
          NoNewPrivileges = true;
          BindPaths = "/nix/";

          # Sandboxing
          ProtectSystem = "strict";
          ProtectHome = true;
          CacheDirectory = "nixpresso";
          PrivateTmp = true;
          PrivateDevices = true;
          PrivateUsers = true;
          ProtectHostname = true;
          ProtectClock = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectKernelLogs = true;
          ProtectControlGroups = true;
          RestrictAddressFamilies = [ "AF_INET AF_INET6 AF_UNIX" ];
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          PrivateMounts = true;
          SystemCallArchitectures = "native";
          SystemCallFilter = "~@clock @privileged @cpu-emulation @debug @keyring @module @mount @obsolete @raw-io @reboot @setuid @swap";
        };
      };
    };
  };
}
