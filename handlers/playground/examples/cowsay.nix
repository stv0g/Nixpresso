{ writeShellApplication, cowsay }:
writeShellApplication {
  name = "cowsay";
  runtimeInputs = [ cowsay ];
  text = ''
    cowsay "$TEXT"
  '';
}
