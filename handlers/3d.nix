# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  nixpresso,
  openscad-unstable,
  imagemagick,
  writeText,
  runCommandNoCC,
  mesa,
  ffmpeg,
  parallel,
  lib,
}:
let
  inherit (builtins) head;
  inherit (lib) optionalString;
  inherit (nixpresso.lib)
    mkHandler
    handlers
    url
    ;

  frames =
    {
      code,
      frames ? 200,
      width ? 800,
      height ? 600,
    }:

    runCommandNoCC "frames"
      {
        buildInputs = [
          openscad-unstable
        ];

        env = {
          LIBGL_DRIVERS_PATH = "${mesa.drivers}/lib:${mesa.drivers}/lib/dri";
          __EGL_VENDOR_LIBRARY_FILENAMES = "${mesa.drivers}/share/glvnd/egl_vendor.d/50_mesa.json";
        };
      }
      ''
        export XDG_CACHE_HOME="$(mktemp -d)"
        mkdir -p $out

        openscad -o "$out/frame.png" \
                     --imgsize=${toString width},${toString height} \
                     --projection=perspective \
                     --animate ${toString frames} \
                     "${writeText "model.scad" code}"
      '';

  framesTransparent =
    attrs:
    runCommandNoCC "frames-transparent"
      {
        buildInputs = [
          imagemagick
          parallel
        ];
      }
      ''
        mkdir $out
        export out
        parallel --will-cite --halt now,fail=1 \
          magick "{}" \
            -fuzz 10% \
            -transparent '\#e6e6e6' \
            "$out/\$(basename {})" \
        ::: ${frames attrs}/*.png
      '';

  gif =
    {
      framerate ? 25,
      delay ? 1 / (10 * framerate),
      loop ? 0,
      ...
    }@attrs:
    runCommandNoCC "3d.gif"
      {
        buildInputs = [ imagemagick ];
      }
      ''
        magick convert \
          -delay ${toString delay} \
          -loop ${toString loop} \
          -dispose previous \
          "${framesTransparent attrs}/*.png" "$out"
      '';

  webm =
    {
      framerate ? 25,
      ...
    }@attrs:
    runCommandNoCC "3d.webm"
      {
        buildInputs = [ ffmpeg ];
      }
      ''
        ffmpeg \
          -framerate ${toString framerate} \
          -i "${framesTransparent attrs}/frame%05d.png" \
          -c:v libvpx-vp9 -pix_fmt yuva420p \
          -preset veryfast \
          $out
      '';
in
mkHandler
  {
    description = "Render a 3D animation with OpenSCAD";
  }
  (
    {
      query,
      path,
      meta,
      ...
    }:
    let
      defaultCode = ''
        rotate([45, 0, 360*$t])
          color("#586E75")
            text("Hello Nixpresso", halign="center", valign="center");
      '';
      code = head (query.code or [ defaultCode ]);
      format = head (query.format or [ "webm" ]);

      attrs = {
        inherit code;
      };

      videoQuery = url.encodeQueryString {
        inherit format code;
      };
    in
    if path == "/video" then
      if format == "webm" then
        {
          body = webm attrs;
          headers = {
            # "Content-Type" = "image/gif";
            "Content-Type" = "video/mp4";
          };
        }
      else
        {
          body = gif attrs;
          headers = {
            "Content-Type" = "image/gif";
          };
        }
    else
      handlers.html {
        title = meta.description;
        main = ''
          <p>
            This example renders an animated 3D text with OpenSCAD and
            converts it to a video format. The text is passed as a query
            parameter. The video is rendered in the background and
            displayed in a video element. The video is rendered as a
            WebM video or a GIF.
          </p>

          <section>
            <h2>Input</h2>
            <form>
              <label>OpenSCAD code
                <textarea class="editor language-scad" rows=10 name="code">${code}</textarea>
              </label>
              <label>Format
                <select name="format">
                  <option disabled>Format</option>
                  <option value="webm" ${optionalString (format == "webm") "selected"}>WebM</option>
                  <option value="gif" ${optionalString (format == "gif") "selected"}>GIF</option>
                </select>
              </label>
              <button type="submit" />Render</button>
            </form>
          </section>

          <section>
            <h2>Output</h2>
            <center>
              ${
                if format == "webm" then
                  ''<video src="video?${videoQuery}" autoplay muted />''
                else
                  ''<img src="video?${videoQuery}" />''
              }
            </center>
          </section>

          <section>
            <fieldset role="group">
              <button onclick="window.location = '/';"><span class="mdi mdi-arrow-left" /> Back</button>
              <button onclick="window.location = 'https://github.com/stv0g/Nixpresso/tree/main/handlers/3d';"><span class="mdi mdi-github"/> Code</button></a>
            </fieldset>
          </section>
        '';
      }
  )
