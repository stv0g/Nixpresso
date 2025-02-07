{
  description = "Run cowsay";
  mode = "run";
  subPath = "bin/cowsay";
  env = {
    TEXT = "Hello, Nixpresso!";
  };
}
