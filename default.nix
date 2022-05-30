{ 
  nixpkgs ? import (builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/haskell-updates.tar.gz") {},
  haskell-tools ? import (builtins.fetchTarball "https://github.com/danwdart/haskell-tools/archive/master.tar.gz") {},
  compiler ? "ghc902"
} :
let
  gitignore = nixpkgs.nix-gitignore.gitignoreSourcePure [ ./.gitignore ];
  tools = haskell-tools compiler;
  lib = nixpkgs.pkgs.haskell.lib;
  myHaskellPackages = nixpkgs.pkgs.haskell.packages.${compiler}.override {
    overrides = self: super: rec {
      # monoidal-containers = self.callCabal2nix "monoidal-containers "
      reflex-gloss = lib.dontHaddock (self.callCabal2nix "reflex-gloss" (gitignore ./.) {});
    };
  };
  shell = myHaskellPackages.shellFor {
    packages = p: [
      p.reflex-gloss
    ];
    shellHook = ''
      gen-hie > hie.yaml
      for i in $(find -type f | grep -v dist-newstyle); do krank $i; done
      doctest src lib
      cabal update
    '';
    buildInputs = tools.defaultBuildTools;
    withHoogle = false;
  };
  exe = lib.justStaticExecutables (myHaskellPackages.reflex-gloss);
in
{
  inherit shell;
  inherit exe;
  inherit myHaskellPackages;
  reflex-gloss = myHaskellPackages.reflex-gloss;
}

