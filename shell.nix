{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  name = "linux-loc";
  packages = with pkgs.python3Packages; [
    matplotlib
    pkgs.qemu
  ];
}
