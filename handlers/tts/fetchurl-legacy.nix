{
  lib,
  system,
  bash,
  curl,
  cacert,
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
  args = [ ./fetchurl-legacy.sh ];

  PATH = "${curl}/bin";

  inherit url;

  SSL_CERT_FILE =
    if (hash == "" || hash == lib.fakeSha256 || hash == lib.fakeSha512 || hash == lib.fakeHash) then
      "${cacert}/etc/ssl/certs/ca-bundle.crt"
    else
      "/no-cert-file.crt";

}
