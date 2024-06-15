{
  lib,
  python3,
  linkFarm,
  writers,
  writeTextFile,
  fetchFromGitHub,
  stdenv,
  models,
  customNodes,
  basePath ? "/var/lib/comfyui",
  inputPath ? "${basePath}/input",
  outputPath ? "${basePath}/output",
  tempPath ? "${basePath}/temp",
  userPath ? "${basePath}/user",
}: let
  mergeModelSets = import ./models/merge-sets.nix;

  # aggregate all custom nodes' dependencies
  dependencies = with builtins;
    lib.pipe customNodes [
      attrValues
      (map (v: v.dependencies))
      (foldl'
        ({
          pkgs,
          models,
        }: x: {
          pkgs = pkgs ++ (x.pkgs or []);
          models = mergeModelSets [models (x.models or {})];
        })
        {
          pkgs = [];
          models = {};
        })
    ];
  # create a derivation for our custom nodes
  customNodesDrv =
    lib.trivial.throwIfNot (lib.lists.all lib.isDerivation (builtins.attrValues customNodes)) ''
      `customNodes` should be a set of custom node derivations in the form of `{ my-node = «derivation»; ... }`
    ''
    (linkFarm "comfyui-custom-nodes" customNodes);
  # create a derivation for our models
  modelsDrv = with builtins; let
    inherit (lib.attrsets) concatMapAttrs;
    concatMapModels = f: concatMapAttrs (type: concatMapAttrs (f type));
    # create a flattened set from our nested model set;
    # attribute name is the file path to the model;
    # value is the store path of the fetched model.
    toNamePath = concatMapModels (type: _name: fetched: let
      # The structure is a bit convoluted so mistakes are easy to make but hard to find. Some helpful information may prove helpful.
      fetchedStr = "{ ${concatStringsSep " " (map (n: "${n} = «${fetched.type or typeOf fetched."${n}"}»;") (lib.attrNames fetched))} }";
      name =
        fetched.name
        or (throw ''
          no attribute "name" in `${type}.${_name} = ${fetchedStr}`
          Hint:
            "${type}" should be the model's type,
            "${_name}" should be the model's name, and
            `${type}.${_name}` should be a derivation.
          Tip: Make sure your models are defined inside their respecive type attribute and that the model set doesn't include other types of assets.
          The model set should look something like this: `{ checkpoints = { ... }; vae.sdxl_vae = «derivation»; ... }`
        '');
    in {
      "${type}/${name}" = fetched;
    });
  in
    linkFarm "comfyui-models" (toNamePath (mergeModelSets [models dependencies.models]));
  config-data = {
    comfyui = let
      modelsDir = "${basePath}/models";
    in {
      base_path = basePath;
      checkpoints = "${modelsDir}/checkpoints";
      clip = "${modelsDir}/clip";
      clip_vision = "${modelsDir}/clip_vision";
      configs = "${modelsDir}/configs";
      controlnet = "${modelsDir}/controlnet";
      embeddings = "${modelsDir}/embeddings";
      inpaint = "${modelsDir}/inpaint";
      ipadapter = "${modelsDir}/ipadapter";
      loras = "${modelsDir}/loras";
      upscale_models = "${modelsDir}/upscale_models";
      vae = "${modelsDir}/vae";
      vae_approx = "${modelsDir}/vae_approx";
    };
  };

  modelPathsFile = writeTextFile {
    name = "extra_model_paths.yaml";
    text = lib.generators.toYAML {} config-data;
  };

  pythonEnv = python3.withPackages (ps:
    with ps;
      [
        aiohttp
        einops
        kornia
        pillow
        psutil
        pyyaml
        safetensors
        scipy
        spandrel
        torch
        torchsde
        torchvision
        tqdm
        transformers
      ]
      ++ dependencies.pkgs);

  executable = writers.writeDashBin "comfyui" ''
    ${pythonEnv}/bin/python $out/comfyui \
      --input-directory ${inputPath} \
      --output-directory ${outputPath} \
      --extra-model-paths-config ${modelPathsFile} \
      --temp-directory ${tempPath} \
      "$@"
  '';
in
  stdenv.mkDerivation {
    pname = "comfyui";
    version = "unstable-2024-06-12";

    src = fetchFromGitHub {
      owner = "comfyanonymous";
      repo = "ComfyUI";
      rev = "605e64f6d3da44235498bf9103d7aab1c95ef211";
      hash = "sha256-JU3SC1mnhsD+eD5eAX0RsEu0zoSxq8DfgR2RxX5ttb0=";
    };

    installPhase = ''
      runHook preInstall
      echo "Preparing bin folder"
      mkdir -p $out/bin/
      echo "Copying comfyui files"
      # These copies everything over but test/ci/github directories.  But it's not
      # very future-proof.  This can lead to errors such as "ModuleNotFoundError:
      # No module named 'app'" when new directories get added (which has happened
      # at least once).  Investigate if we can just copy everything.
      cp -r $src/comfy $out/
      cp -r $src/comfy_extras $out/
      cp -r $src/app $out/
      cp -r $src/web $out/
      cp -r $src/*.py $out/
      mv $out/main.py $out/comfyui
      echo "Copying ${modelPathsFile} to $out"
      cp ${modelPathsFile} $out/extra_model_paths.yaml
      echo "Setting up custom nodes"
      ln -snf ${customNodesDrv} $out/custom_nodes
      echo "Symlinking models into installation dir for scripts that are unaware of extra_model_paths.yaml"
      ln -snf ${modelsDrv} $out/models
      echo "Copying executable script"
      cp ${executable}/bin/comfyui $out/bin/comfyui
      substituteInPlace $out/bin/comfyui --replace "\$out" "$out"
      echo "Patching python code..."
      # TODO: Evaluate if we can get rid of this on the latest version - there
      # seems to be a lot more arguments available now.
      substituteInPlace $out/folder_paths.py --replace "if not os.path.exists(input_directory):" "if False:"
      substituteInPlace $out/folder_paths.py --replace 'os.path.join(os.path.dirname(os.path.realpath(__file__)), "user")' '"${userPath}"'
      runHook postInstall
    '';

    meta = with lib; {
      homepage = "https://github.com/comfyanonymous/ComfyUI";
      description = "The most powerful and modular stable diffusion GUI with a graph/nodes interface.";
      license = licenses.gpl3;
      platforms = platforms.all;
    };
  }
