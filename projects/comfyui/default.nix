{
  config,
  lib,
  ...
}: let
  l = lib // config.flake.lib;
  inherit (config.flake) overlays;
in {
  perSystem = {
    config,
    pkgs,
    lib,
    ...
  }: let
    commonOverlays = [
      # TODO: identify what we actually need
      (l.overlays.callManyPackages [
        ../../packages/mediapipe
        ../../packages/spandrel
      ])
      # what gives us a python with the overlays actually applied
      overlays.python-pythonFinal
    ];

    python3Variants = {
      amd = l.overlays.applyOverlays pkgs.python3Packages (commonOverlays
        ++ [
          overlays.python-torchRocm
        ]);
      nvidia = l.overlays.applyOverlays pkgs.python3Packages (commonOverlays
        ++ [
          # FIXME: temporary standin for practical purposes.
          # They're prebuilt and come with cuda support.
          (final: prev: {
            torch = prev.torch-bin;
            torchvision = prev.torchvision-bin;
          })
          # use this when things stabilise and we feel ready to build the whole thing
          # overlays.python-torchCuda
        ]);
    };

    models = import ./models;

    # we require a python3 with an appropriately overriden package set depending on GPU
    mkComfyUIVariant = python3: args:
      pkgs.callPackage ./package.nix ({inherit python3;} // args);

    # everything here needs to be parametrised over gpu vendor
    legacyPkgs = vendor: let
      customNodes = import ./custom-nodes {
        inherit models;
        inherit (pkgs) stdenv fetchFromGitHub unzip;
        python3Packages = python3Variants."${vendor}";
      };
    in {
      inherit customNodes models;
      # takes a list of model sets and merges them
      mergeModelSets = import ./models/merge-sets.nix;
      # subset of `models` used by Krita plugin
      kritaModels = import ./models/krita-ai-plugin.nix models;
      # subset of `customNodes` used by Krita plugin
      kritaCustomNodes = import ./custom-nodes/krita-ai-plugin.nix customNodes;
    };
    amd = legacyPkgs "amd";
    nvidia = legacyPkgs "nvidia";
  in {
    legacyPackages.comfyui = {inherit amd nvidia;};

    packages = rec {
      comfyui-amd = mkComfyUIVariant python3Variants.amd.python {
        customNodes = {};
        models = {};
      };
      comfyui-nvidia = mkComfyUIVariant python3Variants.nvidia.python {
        customNodes = {};
        models = {};
      };
      krita-comfyui-server-amd = with amd;
        comfyui-amd.override {
          models = kritaModels.full;
          customNodes = kritaCustomNodes;
        };
      krita-comfyui-server-amd-minimal = with amd;
        comfyui-amd.override {
          models = kritaModels.required;
          customNodes = kritaCustomNodes;
        };
      krita-comfyui-server-nvidia = with nvidia;
        comfyui-nvidia.override {
          models = kritaModels.full;
          customNodes = kritaCustomNodes;
        };
      krita-comfyui-server-nvidia-minimal = with nvidia;
        comfyui-nvidia.override {
          models = kritaModels.required;
          customNodes = kritaCustomNodes;
        };
    };
  };
}
