{ ... }:
{
  # Local LLMs. Ollama listens on 127.0.0.1:11434 only. Try it with `ollama run qwen3.5:2b`.
  # The GTX 1650 has 4 GB of VRAM: stay at ~3B parameters or smaller, or it spills into RAM and crawls.
  flake.modules.nixos.ollama = { pkgs, ... }: {
    services.ollama = {
      enable = true;
      # Built from source (no third-party CUDA cache), so only for omen's GTX 1650 (Turing, sm_75): the
      # default compiles every GPU generation, which takes hours and runs out of RAM. Another card needs
      # its own compute capability here (developer.nvidia.com/cuda-gpus: 8.6 is "sm_86").
      package = pkgs.ollama-cuda.override { cudaArches = [ "sm_75" ]; };
      # Pulled on the first start, then kept. Add more tags here (check size against 4 GB of VRAM).
      loadModels = [
        "qwen3.5:2b"         # chat, ~3.5 GB loaded
      ];
      # The list is the whole truth: a model dropped from it (or pulled by hand) is deleted.
      syncModels = true;
      # Ollama's default is 4k below 24 GB of VRAM, and an agent's prompt (tools, files) fills that at once.
      # 8k fits the 1650's 4 GB with a 2B model; a bigger window needs more VRAM.
      environmentVariables.OLLAMA_CONTEXT_LENGTH = "8192";
    };
  };
}
