{ ... }:
{
  # Local LLMs. Ollama listens on 127.0.0.1:11434 only. Try it with `ollama run qwen3.5:2b`.
  # The GTX 1650 has 4 GB of VRAM: stay at ~3B parameters or smaller, or it spills into RAM and crawls.
  flake.modules.nixos.ollama = { pkgs, ... }: {
    services.ollama = {
      enable = true;
      package = pkgs.ollama-cuda;
      # Pulled on the first start, then kept. Add more tags here (check size against 4 GB of VRAM).
      loadModels = [
        "qwen3.5:2b"         # chat, ~3.5 GB loaded
        "nomic-embed-text"   # embeddings, for Open WebUI's document search
      ];
      # Ollama's default is 4k below 24 GB of VRAM, and an agent's prompt (tools, files) fills that at once.
      # 8k fits the 1650's 4 GB with a 2B model; a bigger window needs more VRAM.
      environmentVariables.OLLAMA_CONTEXT_LENGTH = "8192";
    };

    # cache.nixos.org does not carry CUDA packages (unfree), so without this they are compiled
    # from source (hours). Rebuild once after adding it, then it is used. Source: wiki.nixos.org/wiki/CUDA
    nix.settings = {
      substituters = [ "https://cache.nixos-cuda.org" ];
      trusted-public-keys = [ "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=" ];
    };
  };
}
