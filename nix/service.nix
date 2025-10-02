{inputs, ...}:
{
  perSystem = {system, config, ...}:
    let
      pkgs = import inputs.nixpkgs {inherit system;};
      AppName = "table-config-apis";
      host = "0.0.0.0";
      port = "8700";
      version = "3.0.0";
      py = pkgs.python313Packages;
      TableConfigAPIS = py.buildPythonApplication {
        pname = "TableConfig";
        version = version;
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
      OCIContainer = pkgs.dockerTools.buildImage {
        name = AppName;
        tag = version;
        contents = [TableConfigAPIS];
        config = {
          ExposedPorts = {"${port}/tcp" = {};};
          Entrypoint = ["SERVE_TABLE_CONFIG_APIS"];
        };
      };
      K8Manifests = pkgs.writeTextFile {
        name = "${AppName}-manifest.yaml";
        text = ''
          apiVersion: apps/v1
          kind: Deployment
          metadata:
            name: ${AppName}-deployment
          spec:
            replicas: 1
            selector:
              matchLabels:
                app: ${AppName}
            template:
              metadata:
                labels:
                  app: ${AppName}
              spec:
                containers:
                  - name: ${AppName}-container
                    image: ${OCIContainer.name}:${version}
                ports:
                  - containerPort: ${port}
            ---
            apiVersion: v1
            kind: Service
          metadata:
            name: ${AppName}-service
          spec:
            type: LoadBalancer
            selector:
              app: ${AppName}
            ports:
              - protocol: TCP
                port: 80
                targetPort: ${port}
        '';
      };
      DeployAPIS = pkgs.pkgs.writeShellApplication {
        name = "deploy-${AppName}-to-kubernetes";
        runtimeInputs = with pkgs; [
          minikube
          kubectl
          docker
        ];
        text = ''
          minikube image load ${OCIContainer}
          kubectl apply -f ${K8Manifests}
          kubectl get all -l pp=${AppName}
        '';
      };
    in {
      packages.deployment = DeployAPIS;
      devShells.default = pkgs.mkShell {
        buildInputs = [
          config.packages.deployment
          pkgs.minikube
          pkgs.kubectl
          pkgs.docker
          py.flake8
        ];
      };
    };
}