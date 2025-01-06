# In pure evaluation moed, we pass the Nixpkgs package set as an argument.
{ pkgs }: pkgs.hello.meta
