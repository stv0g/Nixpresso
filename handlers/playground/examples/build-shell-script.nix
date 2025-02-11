{ runCommand }:
runCommand "script" { } ''
  for i in $(seq 100); do
    echo "Step $i (some very long line for enforce buffer flushing)"
    sleep 0.01
  done

  touch $out
''
