let
  functorArgs = f: f.__functionArgs or (functionArgs (f.__functor f));
  functionArgs = f: if f ? __functor then functorArgs f else builtins.functionArgs f;
in
handler:
{
  expectedArgs = functionArgs handler;
  pure = !builtins ? currentSystem;
  inherit (builtins) nixPath;
}
// handler.meta or { }
