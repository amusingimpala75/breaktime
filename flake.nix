{
  description = "breaktime dev flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (
    {
      lib,
      ...
    }: {
      systems = lib.platforms.darwin;
      perSystem =
        {
          pkgs,
          self',
          ...
        }:
        {
          packages.default = pkgs.stdenvNoCC.mkDerivation {
            name = "breaktime";
            version = "0.1.0";

            src = lib.cleanSource ./.;

            buildInputs = with pkgs; [
              zig
              apple-sdk
            ];

            buildPhase = ''
              zig build
            '';

            installPhase = ''
              mkdir -p $out/bin
              cp zig-out/bin/breaktime $out/bin/
            '';
          };
          devShells.default = pkgs.mkShell {
            inputsFrom = [ self'.packages.default ];
          };
        };
  });
}
