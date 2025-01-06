# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{ lib }:
let
  inherit (builtins) unsafeGetAttrPos;
  inherit (lib)
    attrNames
    filterAttrs
    functionArgs
    head
    intersectAttrs
    isFunction
    ;
in
{
  callWith =
    autoArgs: fn: args:
    let
      f = if isFunction fn then fn else import fn;
      fargs = functionArgs f;

      # All arguments that will be passed to the function
      # This includes automatic ones and ones passed explicitly
      allArgs = intersectAttrs fargs autoArgs // args;

      # A list of argument names that the function requires, but
      # wouldn't be passed to it
      missingArgs =
        # Filter out arguments that have a default value
        (
          filterAttrs (_: value: !value)
            # Filter out arguments that would be passed
            (removeAttrs fargs (attrNames allArgs))
        );

      errorForArg =
        arg:
        let
          attrPos = unsafeGetAttrPos arg fargs;
          loc = "${attrPos.file}:${toString attrPos.line}:${toString attrPos.column}";
        in
        # loc' can be removed once lib/minver.nix is >2.3.4, since that includes
        # https://github.com/NixOS/nix/pull/3468 which makes loc be non-null
        "Function called without required argument \"${arg}\" at ${loc}";

      # Only show the error for the first missing argument
      error = errorForArg (head (attrNames missingArgs));

    in
    if missingArgs == { } then
      f allArgs

    # This needs to be an abort so it can't be caught with `builtins.tryEval`,
    # which is used by nix-env and ofborg to filter out packages that don't evaluate.
    # This way we're forced to fix such errors in Nixpkgs,
    # which is especially relevant with allowAliases = false
    else
      abort error;
}
