# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

# Stripped version of: https://github.com/NixOS/nix/blob/e27d8049298a75dd1f6b27f6aeec16125ccf97a8/docker.nix
{
  lib,
  pkgs,
  dockerTools,
  runCommand,
  system,
  self,
}:
let
  users =
    {
      root = {
        uid = 0;
        shell = "${pkgs.dash}/bin/dash";
        home = "/root";
        gid = 0;
        groups = [ "root" ];
        description = "System administrator";
      };

      nobody = {
        uid = 65534;
        shell = "${pkgs.dash}/bin/dash";
        home = "/var/empty";
        gid = 65534;
        groups = [ "nobody" ];
        description = "Unprivileged account (don't use!)";
      };

    }
    // lib.listToAttrs (
      map (n: {
        name = "nixbld${toString n}";
        value = {
          uid = 30000 + n;
          gid = 30000;
          groups = [ "nixbld" ];
          description = "Nix build user ${toString n}";
        };
      }) (lib.lists.range 1 32)
    );

  groups = {
    root.gid = 0;
    nixbld.gid = 30000;
    nobody.gid = 65534;
  };

  userToPasswd = (
    k:
    {
      uid,
      gid ? 65534,
      home ? "/var/empty",
      description ? "",
      shell ? "/bin/false",
      groups ? [ ],
    }:
    "${k}:x:${toString uid}:${toString gid}:${description}:${home}:${shell}"
  );
  passwdContents = (lib.concatStringsSep "\n" (lib.attrValues (lib.mapAttrs userToPasswd users)));

  userToShadow = k: { ... }: "${k}:!:1::::::";
  shadowContents = (lib.concatStringsSep "\n" (lib.attrValues (lib.mapAttrs userToShadow users)));

  # Map groups to members
  # {
  #   group = [ "user1" "user2" ];
  # }
  groupMemberMap = (
    let
      # Create a flat list of user/group mappings
      mappings = (
        builtins.foldl' (
          acc: user:
          let
            groups = users.${user}.groups or [ ];
          in
          acc ++ map (group: { inherit user group; }) groups
        ) [ ] (lib.attrNames users)
      );
    in
    (builtins.foldl' (
      acc: v: acc // { ${v.group} = acc.${v.group} or [ ] ++ [ v.user ]; }
    ) { } mappings)
  );

  groupToGroup =
    k:
    { gid }:
    let
      members = groupMemberMap.${k} or [ ];
    in
    "${k}:x:${toString gid}:${lib.concatStringsSep "," members}";
  groupContents = (lib.concatStringsSep "\n" (lib.attrValues (lib.mapAttrs groupToGroup groups)));

  nixConf = {
    sandbox = "false";
    build-users-group = "nixbld";
    trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  nixConfContents =
    (lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        n: v:
        let
          vStr = if builtins.isList v then lib.concatStringsSep " " v else v;
        in
        "${n} = ${vStr}"
      ) nixConf
    ))
    + "\n";

  baseSystem =
    runCommand "base-system"
      {
        inherit
          passwdContents
          groupContents
          shadowContents
          nixConfContents
          ;
        passAsFile = [
          "passwdContents"
          "groupContents"
          "shadowContents"
          "nixConfContents"
        ];
        allowSubstitutes = false;
        preferLocalBuild = true;
      }
      (''
        env
        set -x
        mkdir -p $out/usr $out/tmp $out/var/tmp $out/etc/nix $out/nix/var/nix/gcroots

        cat $passwdContentsPath > $out/etc/passwd
        echo "" >> $out/etc/passwd

        cat $groupContentsPath > $out/etc/group
        echo "" >> $out/etc/group

        cat $shadowContentsPath > $out/etc/shadow
        echo "" >> $out/etc/shadow

        cat $nixConfContentsPath > $out/etc/nix/nix.conf
      '');
in
dockerTools.streamLayeredImage {
  name = "nixpresso";
  tag = "latest";

  contents = [ baseSystem ];

  fakeRootCommands = ''
    chmod 1777 tmp
    chmod 1777 var/tmp
  '';

  config = {
    Entrypoint = [ "${pkgs.nixpresso}/bin/nixpresso" ];
    Cmd = [ "path:${self}#handlers.${system}.default" ];
    Env = [
      "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "GIT_SSL_CAINFO=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    ];
  };
}
