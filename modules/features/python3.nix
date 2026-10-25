{ ... }:
{
  flake.modules.homeManager.python3 = { pkgs, ... }: {
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