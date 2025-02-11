# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{
  nixpresso,
  ffmpeg,
  runCommandNoCC,
  fetchurl,
  writeText,
}:
let
  inherit (builtins) head;
  inherit (nixpresso.lib)
    mkHandler
    ;

  font = fetchurl {
    url = "https://fonts.gstatic.com/s/leaguegothic/v11/qFdR35CBi4tvBz81xy7WG7ep-BQAY7Krj7feObpH_-am.ttf";
    hash = "sha256-1dATMWY0Fhd/vwo6yeQFhhqFFbmrehTvpOdtXX/t2jQ=";
  };
in
mkHandler
  {
    description = "Generate and render STL files for 3D printing";
  }
  (
    {
      query,
      ...
    }:
    let
      defaultText = ''
        A long time ago in a galaxy far, far away...

        It is a dark time for the
        Rebellion. Although the Death
        Star has been destroyed,
        Imperial troops have driven the
        Rebel forces from their hidden
        base and pursued them across
        the galaxy.

        Evading the dreaded Imperial
        Starfleet, a group of freedom
        fighters led by Luke Skywalker
        has established a new secret
        base on the remote ice world
        of Hoth.

        The evil lord Darth Vader,
        obsessed with finding young
        Skywalker, has dispatched
        thousands of remote probes into
        the far reaches of space....
      '';

      text = head (query.text or [ defaultText ]);
      textFile = writeText "text" text;
    in
    {
      body = runCommandNoCC "movie-crawl.mp4" { } ''
        ${ffmpeg}/bin/ffmpeg \
          -y \
          -f lavfi \
          -i nullsrc=s=1920x1080 \
          -vf 'drawbox=t=fill,drawtext=${font}:textfile=${textFile}:x=(w-text_w)/2:y=h-50*t:fontsize=75:fontcolor=0xb89801,drawbox,perspective=525:285:1395:285:-900:H:W+900:H:sense=destination,drawbox=0:0:1920:108:t=fill,drawbox=0:1080-108:1920:108:t=fill' \
          -t 70 \
          $out
      '';
      headers = {
        "Content-Type" = "video/mp4";
      };
    }
  )
