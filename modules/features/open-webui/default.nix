{ ... }:
{
  # ChatGPT-style UI for Ollama at http://127.0.0.1:8080 (the module's defaults; it finds Ollama on its
  # default port by itself). The first account you create is the admin.
  flake.modules.nixos.open-webui = {
    services.open-webui = {
      enable = true;
      environment = {
        # Document search (RAG) with the local embedding model.
        RAG_EMBEDDING_ENGINE = "ollama";
        RAG_EMBEDDING_MODEL = "nomic-embed-text";

        # Web search through the local SearXNG.
        ENABLE_WEB_SEARCH = "True";
        WEB_SEARCH_ENGINE = "searxng";
        SEARXNG_QUERY_URL = "http://127.0.0.1:8888/search?q=<query>";

        # The module's default environment is just these three, and setting any replaces it.
        ANONYMIZED_TELEMETRY = "False";
        DO_NOT_TRACK = "True";
        SCARF_NO_ANALYTICS = "True";
      };
    };
  };
}
