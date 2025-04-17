# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

{ lib }:
let
  inherit (lib)
    isAttrs
    functionArgs
    isBool
    isFloat
    isInt
    isList
    isString
    toFunction
    unique
    ;

  /**
    Check if a value is JSON serializable.

    # Type

    ```
    isSerializable :: Any -> Bool
    ```

    # Arguments

    b
    : A value
  */
  isSerializable = b: isAttrs b || isList b || isString b || isBool b || isInt b || isFloat b;

  /**
    Check if a value is a functor.

    # Type

    ```
    isFunctor :: Any -> Bool
    ```

    # Arguments

    f
    : A value
  */
  isFunctor = f: f ? __functor;

  /**
    Convert a value to a functor.

    # Type

    ```
    toFunctor :: Any -> Functor
    ```

    # Arguments

    f
    : A value
  */
  toFunctor =
    f:
    if isFunctor f then
      f
    else
      let
        fn = toFunction f;
      in
      {
        __functor = _: fn;
        __functionArgs = functionArgs fn;
      };

  updateMeta =
    old: new:
    (
      old
      // new
      // {
        evalCacheIgnore = {
          headers = unique (old.evalCacheIgnore.headers or [ ] ++ new.evalCacheIgnore.headers or [ ]);
          args = unique (old.evalCacheIgnore.args or [ ] ++ new.evalCacheIgnore.args or [ ]);
        };
        pty = (old.pty or false) || (new.pty or false);
      }
    );

  updateHandler =
    old: new:
    let
      oldFct = toFunctor old;
      newFct = toFunctor new;

      oldArgs = functionArgs oldFct;
      newArgs = functionArgs newFct;

      oldMeta = oldFct.meta or { };
      newMeta = newFct.meta or { };
    in
    {
      __functor = newFct.__functor;
      __functionArgs = oldArgs // newArgs;

      meta = updateMeta oldMeta newMeta;
    };
in
{
  inherit
    isFunctor
    isSerializable
    toFunctor
    updateHandler
    updateMeta
    ;
}
