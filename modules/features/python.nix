{ ... }:
{
  flake.modules.homeManager.python = { pkgs, ... }: {
    home.packages = [
      (pkgs.python3.withPackages (ps: with ps; [
        pandas
        numpy
        scikit-learn
        xgboost
        shap
        lime
        streamlit
        joblib
        matplotlib
      ]))
    ];
  };
}