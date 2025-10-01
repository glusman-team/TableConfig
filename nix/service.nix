{inputs, ...}:
{
  perSystem = {system, config, ...}:
    let
      pkgs = import inputs.nixpkgs {inherit system;};
      host = "0.0.0.0";
      port = "8700";
      py = pkgs.python313Packages;
      TableConfigAPI = py.buildPythonApplication {
        pname = "TableConfig";
        version = "3.0.0";
        src = ../.;
        pyproject = true;
        build-system = with py; [
          setuptools
        ];
        propagatedBuildInputs = with py; [
          pydantic
          uvicorn
          fastapi
          pyyaml
        ];
        nativeBuildInputs = [
          pkgs.makeWrapper
        ];
        makeWrapperArgs = [
          "--set TABLE_CONFIG_API_HOST ${host}"
          "--set TABLE_CONFIG_API_PORT ${port}"
        ];
        doCheck = false;
      };
    in {
      packages.default = TableConfigAPI;
      devShells.default = pkgs.mkShell {
        buildInputs = [
          config.packages.default
          py.flake8
        ];
      };
    };
}