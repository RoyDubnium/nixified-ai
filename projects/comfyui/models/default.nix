{ lib
, fetchurl
}:

let
  fetchModel = import ./fetch-model.nix { inherit lib fetchurl; };
in {
  checkpoints = {
    realisticVisionV51_v51VAE = (fetchModel {
      format = "safetensors";
      url = "https://huggingface.co/lllyasviel/fav_models/resolve/main/fav/realisticVisionV51_v51VAE.safetensors";
      sha256 = "sha256-FQEsU49QPOLr/CyFR7Jox1zNr/eigdtVOZlA/x1w4h0=";
    });
    DreamShaper_8_pruned = (fetchModel {
      format = "safetensors";
      url = "https://huggingface.co/Lykon/DreamShaper/resolve/main/DreamShaper_8_pruned.safetensors";
      sha256 = "sha256-h521I8MNO5AXFD1WcFAV4VostWKHYsEdCG/tlTir1/0=";
    });
    juggernautXL_version6Rundiffusion = (fetchModel {
      format = "safetensors";
      url = "https://huggingface.co/lllyasviel/fav_models/resolve/main/fav/juggernautXL_version6Rundiffusion.safetensors";
      sha256 = "sha256-H+bH7FTHhgQM2rx7TolyAGnZcJaSLiDQHxPndkQStH8=";
    });
  };
  inpaint = {
    MAT_Places512_G_fp16 = (fetchModel {
      format = "safetensors";
      url = "https://huggingface.co/Acly/MAT/resolve/main/MAT_Places512_G_fp16.safetensors";
      sha256 = "sha256-MJ3Wzm4EA03EtrFce9KkhE0VjgPrKhOeDsprNm5AwN4=";
    });
    fooocus_inpaint_head = (fetchModel {
      format = "pth";
      url = "https://huggingface.co/lllyasviel/fooocus_inpaint/resolve/main/fooocus_inpaint_head.pth";
      sha256 = "sha256-Mvf4OODG2PE0N7qEEed6RojXei4034hX5O9NUfa5dpI=";
    });
    "inpaint_v26.fooocus" = (fetchModel {
      format = "patch";
      url = "https://huggingface.co/lllyasviel/fooocus_inpaint/resolve/main/inpaint_v26.fooocus.patch";
      sha256 = "sha256-+GV6AlEE4i1w+cBgY12OjCGW9DOHGi9o3ECr0hcfDVk=";
    });
  };
  clip = {};
  # this is a bit ugly, but it works when you need to put something in a subdirectory
  "clip_vision/sd1.5" = {
    model = (fetchModel {
      format = "safetensors";
      url = "https://huggingface.co/h94/IP-Adapter/resolve/main/models/image_encoder/model.safetensors?download=true";
      sha256 = "sha256-bKlmfaHKngsPdeRrsDD34BH0T4bL+41aNlkPzXUHsDA=";
    });
  };
  configs = {};
  controlnet = {
    control_v11p_sd15_inpaint_fp16 = (fetchModel {
      format = "safetensors";
      url = "https://huggingface.co/comfyanonymous/ControlNet-v1-1_fp16_safetensors/resolve/main/control_v11p_sd15_inpaint_fp16.safetensors";
      sha256 = "sha256-Z3pP41Ht7NQM0NfMIQqGhrWdTlUgcxfxIxnvdGp6Wok=";
    });
    control_lora_rank128_v11f1e_sd15_tile_fp16 = (fetchModel {
      format = "safetensors";
      url = "https://huggingface.co/comfyanonymous/ControlNet-v1-1_fp16_safetensors/resolve/main/control_lora_rank128_v11f1e_sd15_tile_fp16.safetensors";
      sha256 = "sha256-zsADaemc/tHOyX4RJM8yIN96meRTVOqh4zUMSF5lFU8=";
    });
  };
  ipadapter = {
    ip-adapter_sd15 = (fetchModel {
      format = "safetensors";
      url = "https://huggingface.co/h94/IP-Adapter/resolve/main/models/ip-adapter_sd15.safetensors";
      sha256 = "sha256-KJtF8W0EPQv1QuRYMflx3Nqr4YtlbxHobZ37p+nuM2k=";
    });
    ip-adapter_sdxl_vit-h = (fetchModel {
      format = "safetensors";
      url = "https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/ip-adapter_sdxl_vit-h.safetensors";
      sha256 = "sha256-6/BdkYNIrsersCpens73fgquppFKXE6hP1DUXrFoGDE=";
    });
  };
  embeddings = {};
  loras = {
    lcm-lora-sdv1-5 = (fetchModel {
      format = "safetensors";
      url = "https://huggingface.co/latent-consistency/lcm-lora-sdv1-5/resolve/main/pytorch_lora_weights.safetensors?download=true";
      sha256 = "sha256-j5DYQOB1/1iKWOIsZYbirppveSKZbuZkmn8BByMzr+Q=";
    });
    lcm-lora-sdxl = (fetchModel {
      format = "safetensors";
      url = "https://huggingface.co/latent-consistency/lcm-lora-sdxl/resolve/main/pytorch_lora_weights.safetensors?download=true";
      sha256 = "sha256-p2TmhZtuBAR812HAj/DO6WQTqOAEyfB3B1MM13axkUE=";
    });
  };
  upscale_models = {
    "4x_NMKD-Superscale-SP_178000_G" = (fetchModel {
      url = "https://huggingface.co/gemasai/4x_NMKD-Superscale-SP_178000_G/resolve/main/4x_NMKD-Superscale-SP_178000_G.pth";
      format = "pth";
      sha256 = "sha256-HRsAeP5xRG4EadjU31npa6qA2DzaYA1oI31lWDCCG8w=";
    });
    OmniSR_X2_DIV2K = (fetchModel {
      url = "https://huggingface.co/Acly/Omni-SR/resolve/main/OmniSR_X2_DIV2K.safetensors";
      format = "safetensors";
      sha256 = "sha256-eUCPwjIDvxYfqpV8SmAsxAUh7SI1py2Xa9nTdeZkRhE=";
    });
    OmniSR_X3_DIV2K = (fetchModel {
      url = "https://huggingface.co/Acly/Omni-SR/resolve/main/OmniSR_X3_DIV2K.safetensors";
      format = "safetensors";
      sha256 = "sha256-T7C2j8MU95jS3c8fPSJTBFuj2VnYua4nDFqZufhi7hI=";
    });
    OmniSR_X4_DIV2K = (fetchModel {
      url = "https://huggingface.co/Acly/Omni-SR/resolve/main/OmniSR_X4_DIV2K.safetensors";
      format = "safetensors";
      sha256 = "sha256-3/JeTtOSy1y+U02SDikgY6BVXfkoHFTF7DIUkKKlmDI=";
    });
  };
  vae = {};
  vae_approx = {};
}

