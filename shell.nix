{ pkgs ? import <nixpkgs> { } }:

let
  myDpdk = (pkgs.dpdk.overrideAttrs (old: {
    version = "25.07";

    src = pkgs.fetchFromGitHub {
      owner = "CajuM";
      repo = "dpdk";
      rev = "vhost-no-csum";
      hash = "sha256-Ee4FBoKOXw0lKOkLm7oa7W67HyTKWd9eEWNrI1xgfkU=";
    };
  })).override {
    machine = "znver3";
  };

in
pkgs.mkShell {
  name = "linux-loc";
  packages = with pkgs; with pkgs.python3Packages; [
    myDpdk
    gdb
    matplotlib
    linuxPackages.perf
    qemu
  ];
}
