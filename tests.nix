# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

[
  {
    arguments = {
      path = "/test";
      tls = null;
      uri = "/";
    };
    name = "Test 1";
    results = {
      body = "<!DOCTYPE html>\n<html data-theme=\"light\" lang=\"en\">\n  <head>\n    <title>Error</title>\n    <meta charset=\"utf-8\" />\n    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />\n    \n    <link rel=\"stylesheet\" href=\"/assets/bundle.css\" rel=\"stylesheet\">\n    <link rel=\"icon\" href=\"/assets/images/nixpresso-favicon.svg\" sizes=\"32x32\" type=\"image/svg+xml\" />\n    <link rel=\"apple-touch-icon\" href=\"/assets/images/nixpresso-icon.svg\" type=\"image/svg+xml\" />\n\n    \n  </head>\n  <body class=\"line-numbers\">\n    <header>\n      <h1><a href=\"/\"><img class=\"logo\" src=\"/assets/images/nixpresso-icon.svg\" /></a>Error</h1>\n    </header>\n\n    <main>\n      <h2>Method Not Allowed (405)</h2>\n<p><p>Please pass some JSON encoded payload via a <tt>POST</tt> request:<p>\n<section>\n  <h3>Example</h3>\n  <code>curl -v http://example.com/ -d '{\"some\": \"value\"}'</code>\n</section></p>\n\n    </main>\n\n    <footer>\n      <p>Powered by <a href=\"https://github.com/stv0g/nixpresso\">Nixpresso</a> developed by <a href=\"https://github.com/stv0g\">@stv0g</a> &middot; <a href=\"https://liberapay.com/stv0g/donate\"><img alt=\"Donate using Liberapay\" src=\"/assets/images/donate.svg\" /></a></p>\n\n    </footer>\n\n    <script type=\"module\" src=\"/assets/bundle.js\"></script>\n\n    \n  </body>\n</html>";
      headers = {
        Cache-Control = [ "public, max-age=86400, must-revalidate" ];
        Content-Type = [ "text/html; charset=utf-8" ];
        ETag = [ "4f07c44f0c87138f1728589ee9373c8e5ac3969977d67c9e1ac93ea7d2ef23d6" ];
        Nix = [ "type=string, mode=serve, system=aarch64-linux" ];
      };
      mode = "serve";
      output = "out";
      status = 405;
      type = "string";
    };
  }
]
