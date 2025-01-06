{ query, ... }@request:
let
  pkgs = import <nixpkgs> { };
  inherit (pkgs) lib;
  inherit (lib) toInt;
  inherit (builtins) toString getEnv head;

  count = head (query.count or [ "5" ]);

  myScript = pkgs.writeScriptBin "handle" ''
    echo "Hello World"
    echo "Time: $(date)"
    echo "Stdin: $(cat)"   ;

    echo "MYENV = ${getEnv "MYENV"}" 

    ${lib.getExe pkgs.curl} icanhazip.com

    for i in $(seq ${count}); do
      echo $i
      sleep 1
    done
  '';

  cacheKey = if query ? uncached then builtins.currentTime else 0;
in
{
  status = 200;
  headers = {
    "Content-type" = [ "text/text" ];
  };

  body =
    pkgs.runCommand "test"
      {
        __noChroot = true;
        env = {
          inherit cacheKey;
        };
      }
      ''
        ${lib.getExe myScript} >> $out
      '';
  path = true;
}
