{
  lib,
  system,
  bash,
  curl,
}:
{
  url,
  hash,
  hashAlgo ? "md5",
  name ? lib.strings.sanitizeDerivationName (builtins.baseNameOf url),
}:
derivation {
  inherit name system;
  outputHash = hash;
  outputHashAlgo = hashAlgo;
  outputHashMode = "flat";
  builder = "${bash}/bin/bash";
  args = [
    "-c"
    ''
      ${curl}/bin/curl -L '${url}' -o "$out"
    ''
  ];
}
