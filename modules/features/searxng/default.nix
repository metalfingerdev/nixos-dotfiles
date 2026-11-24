{ ... }:
{
  # Private metasearch at http://127.0.0.1:8888 (SearXNG's own defaults): what the island's Agent
  # (features/nilo-agent) and Crush search the web with.
  flake.modules.nixos.searxng = {
    services.searx = {
      enable = true;
      settings = {
        # Only reachable from this machine, so a fixed key is fine. SearXNG won't start with its default one.
        server.secret_key = "localhost-only-not-a-secret";
        # json is what both ask for.
        search.formats = [ "html" "json" ];
      };
    };
  };
}
