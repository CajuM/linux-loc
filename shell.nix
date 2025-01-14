{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  packages = with pkgs; [
    nixfmt-rfc-style
    (python312.withPackages (
      ps: with ps; [
        matplotlib
        numpy
        pandas
      ]
    ))
  ];
}
