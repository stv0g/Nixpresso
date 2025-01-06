#!/usr/bin/env -S nix eval --arg count 2 --raw --option sandbox relaxed jsonInput --file
#!/usr/bin/env -S nix build --arg count 2 --print-build-logs --option sandbox relaxed output --file
#!/usr/bin/env -S nix run --arg count 2 handler --file
{
  count ? 5,
}:
let
  pkgs = import <nixpkgs> { };
  inherit (pkgs) lib;

  handler = pkgs.writeScriptBin "handle" ''
    echo "Hello World"

    echo "Stdin: $(cat)";

    echo "MYENV = ${builtins.getEnv "MYENV"}" 

    ${lib.getExe pkgs.curl} icanhazip.com

    for i in $(seq ${builtins.toString count}); do
      echo $i
      sleep 1
    done
  '';

  zipper = pkgs.writeScriptBin "zip" ''
    ${lib.getExe pkgs.gnutar} -cz -f - ${pkgs.hello}/bin/hello ${handler}
  '';

  drv =
    pkgs.runCommand "test"
      {
        __noChroot = true;
        passthru.test = 1234;

        outputs = [
          "out"
          "body"
          "headers"
        ];
      }
      ''
        mkdir $out

        ${lib.getExe handler} > $body <<< "${builtins.readFile "/dev/stdin"}"

        echo "Content-length: 1234" >> $headers
      '';
in
{
  output = builtins.readFile "${drv.body}";
  jsonInput =
    let
      input = builtins.readFile "/dev/stdin";
      json = builtins.fromJSON input;

      jsonModified = json // {
        inherit count;
      };
    in
    builtins.toJSON jsonModified;
  inherit drv handler zipper;
}
