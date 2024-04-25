{ lib
, python3
, linkFarm
, writers
, writeTextFile
, fetchFromGitHub
, stdenv
, symlinkJoin
, config
, modelsPath ? "/var/lib/comfyui/models"
, inputPath ? "/var/lib/comfyui/input"
, outputPath ? "/var/lib/comfyui/output"
, tempPath ? "/var/lib/comfyui/temp"
, userPath ? "/var/lib/comfyui/user"
, customNodes ? []
, models ? {
    checkpoints = {};
    clip = {};
    clip_vision = {};
    configs = {};
    controlnet = {};
    embeddings = {};
    upscale_models = {};
    vae = {};
    vae_approx = {};
  }
}:

let

  config-data = {
    comfyui = {
      base_path = modelsPath;
      checkpoints = "${modelsPath}/checkpoints";
      clip = "${modelsPath}/clip";
      clip_vision = "${modelsPath}/clip_vision";
      configs = "${modelsPath}/configs";
      controlnet = "${modelsPath}/controlnet";
      embeddings = "${modelsPath}/embeddings";
      loras = "${modelsPath}/loras";
      upscale_models= "${modelsPath}/upscale_models";
      vae = "${modelsPath}/vae";
      vae_approx = "${modelsPath}/vae_approx";
    };
  };

  modelPathsFile = writeTextFile {
    name = "extra_model_paths.yaml";
    text = (lib.generators.toYAML {} config-data);
  };

  pythonEnv = (python3.withPackages (ps: with ps; [
    torch
    # torchsde
    torchvision
    # torchaudio
    transformers
    safetensors
    accelerate
    torchsde
    aiohttp
    einops
    kornia
    pyyaml
    pillow
    scipy
    psutil
    tqdm
  ] ++ (builtins.concatMap (node: node.dependencies) customNodes)));

  executable = writers.writeDashBin "comfyui" ''
    cd $out && \
    ${pythonEnv}/bin/python comfyui \
      --input-directory ${inputPath} \
      --output-directory ${outputPath} \
      --extra-model-paths-config ${modelPathsFile} \
      --temp-directory ${tempPath} \
      "$@"
  '';

  customNodesCollection = (
    linkFarm "comfyui-custom-nodes" (builtins.map (pkg: { name = pkg.pname; path = pkg; }) customNodes)
  );
in stdenv.mkDerivation rec {
  pname = "comfyui";
  version = "unstable-2024-04-15";

  src = fetchFromGitHub {
    owner = "comfyanonymous";
    repo = "ComfyUI";
    rev = "45ec1cbe963055798765645c4f727122a7d3e35e";
    hash = "sha256-oK+PwAJdvItK1NaRRJMNI4Oh/g4jNt1M5gWfXEy3C9g=";
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
    echo "Setting up input and output folders"
    ln -s ${inputPath} $out/input
    ln -s ${outputPath} $out/output
    mkdir -p $out/${tempPath}
    echo "Setting up custom nodes"
    ln -snf ${customNodesCollection} $out/custom_nodes
    echo "Copying executable script"
    cp ${executable}/bin/comfyui $out/bin/comfyui
    substituteInPlace $out/bin/comfyui --replace "\$out" "$out"
    echo "Patching python code..."
    # TODO: Evaluate if we can get rid of this on the latest version - there
    # seems to be a lot more arguments available now.
    substituteInPlace $out/folder_paths.py --replace "if not os.path.exists(input_directory):" "if False:"
    substituteInPlace $out/nodes.py --replace "os.listdir(custom_node_path)" "os.listdir(os.path.realpath(custom_node_path))"
    substituteInPlace $out/folder_paths.py --replace 'os.path.join(os.path.dirname(os.path.realpath(__file__)), "user")' '"${userPath}"'
    runHook postInstall
  '';

  # outputs = ["" "extra_model_paths.yaml" "inputs" "outputs"];

  meta = with lib; {
    homepage = "https://github.com/comfyanonymous/ComfyUI";
    description = "The most powerful and modular stable diffusion GUI with a graph/nodes interface.";
    license = licenses.gpl3;
    platforms = platforms.all;
    maintainers = with maintainers; [ fazo96 ];
  };
}
