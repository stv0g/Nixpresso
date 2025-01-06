# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  self,
  pkgs,
  testers,
}:
testers.runNixOSTest {
  name = "nixpresso";

  nodes = {
    host1 = {
      imports = [ self.nixosModules.nixpresso ];

      services.nixpresso = {
        enable = true;

        settings = {
          # We must use non-Flake handler here to avoid fetching
          # Flake inputs over the network which wont work in the sandbox.
          handler = "default";
          verbose = 10;
          extraArgs = [
            "--"
            "--arg"
            "nixpkgs"
            "${pkgs.path}"
            "--file"
            "${self}/handlers"
          ];

          allowedModes = [
            "run"
          ];
        };
      };

      # Make sure the Nixpresso handler does not need to fetch from the binary cache.
      environment.systemPackages = with pkgs; [
        cowsay
      ];

      systemd.services.nixpresso = {
        environment = {
          NIX_PATH = "nixpkgs=${self.inputs.nixpkgs}";
        };
      };

      nix.settings.experimental-features = "nix-command flakes";
    };
  };

  testScript = ''
    start_all()

    host1.wait_for_unit("nixpresso.service", timeout=30)
    host1.wait_for_open_port(8080, timeout=30)
    out = host1.succeed("curl -sv http://[::]:8080/run-command")

    expect = """ _______________________
    < Hello from Nixpresso! >
     -----------------------
            \\   ^__^
             \\  (oo)\\_______
                (__)\\       )\\/\\
                    ||----w |
                    ||     ||
    """

    assert out == expect
  '';
}
