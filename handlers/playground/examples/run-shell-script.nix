{ writeShellApplication }:
writeShellApplication {
  name = "script";
  text = ''
    for i in $(seq 5); do
      echo "Step $i (some very long line for enforce buffer flushing)"
      sleep 0.1
    done
  '';
}
