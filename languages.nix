{ pkgs, lib }:
{
  language = [
    {
      name = "nix";
      formatter = {
        command = "${lib.getExe pkgs.nixfmt-rfc-style}";
      };
      auto-format = true;
    }
  ];
}
