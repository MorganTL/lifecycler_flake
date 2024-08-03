{
  description = "tetrs";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    naersk.url = "github:nix-community/naersk";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      naersk,
      rust-overlay,
    }:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ (import rust-overlay) ];
      };

      rust = pkgs.rust-bin.stable."1.80.0".default.override {
        extensions = [ "rust-src" ];
        targets = [ ];
      };

      nsk = pkgs.callPackage naersk {
        cargo = rust;
        rustc = rust;
      };

      lifecycler = nsk.buildPackage {
        # one of the dependencies of lifecycler doens't have Cargo.lock file
        # naersk is one of the builder that directly download dependencies binary from cargo.io 
        # Thus, bypassing the missing Cargo.lock problem
        src = pkgs.fetchFromGitHub {
          owner = "cxreiff";
          repo = "lifecycler";
          rev = "992413a7fb79031149db67fb91c35d5a0a94540e";
          hash = "sha256-tonM2xTCAB3BviXeA/4zNJUw2JoHtKKUpQT/q427gBc=";
        };

        nativeBuildInputs = with pkgs; [
          alsa-lib
          pkg-config
          systemdLibs
          libinput
          wayland
          wayland-protocols
        ];
      };
    in
    {
      packages.x86_64-linux.default = lifecycler;

      devShell.x86_64-linux = pkgs.mkShell rec {
        name = "lifecycler";
        buildInputs = [
          lifecycler
          pkgs.libGL
          pkgs.libxkbcommon
        ];
        # winit(egui) is having trouble running on nixos
        # see https://github.com/rust-windowing/winit/issues/493
        # solution: https://github.com/emilk/egui/discussions/1587#discussioncomment-2698470
        LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath buildInputs}";
      };
    };
}
