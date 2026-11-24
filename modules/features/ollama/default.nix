{ ... }:
{
  # Local LLMs. Ollama listens on 127.0.0.1:11434 only. Try it with `ollama run qwen3.5:2b`.
  # The GTX 1650 has 4 GB of VRAM: stay at ~3B parameters or smaller, or it spills into RAM and crawls.
  flake.modules.nixos.ollama = { pkgs, ... }: {
    # cache.nixos.org carries no CUDA (unfree): the NixOS CUDA team's cache does (wiki.nixos.org/wiki/CUDA).
    # A rebuild only uses the caches the running system already knows, so the one that adds this would
    # compile every GPU generation (hours, and out of RAM). Give it the cache that once:
    #   sudo nixos-rebuild switch --flake .#omen \
    #     --option extra-substituters https://cache.nixos-cuda.org \
    #     --option extra-trusted-public-keys cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=
    nix.settings = {
      substituters = [ "https://cache.nixos-cuda.org" ];
      trusted-public-keys = [ "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=" ];
    };

    services.ollama = {
      enable = true;
      # As nixpkgs builds it, so it comes from the cache above. Only for the GTX 1650 (cudaArches =
      # [ "sm_75" ]) would run the same and take less disk, but no cache has that: it would compile
      # here after every nixpkgs update.
      package = pkgs.ollama-cuda;
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
