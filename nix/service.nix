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
      DockerContainer = pkgs.dockerTools.buildImage {
        name = AppName;
        tag = version;
        copyToRoot = pkgs.buildEnv {
          name = AppName;
          paths = [TableConfigAPIS];
        };
        config = {
          ExposedPorts = {"${port}/tcp" = {};};
          Entrypoint = ["SERVE_TABLE_CONFIG_APIS"];
        };
      };
      PolicyJSON = pkgs.writeText "policy.json" ''
        {
          "default": [
            {"type": "insecureAcceptAnything"}
          ]
        }
      '';
      RegistriesConf = pkgs.writeText "registries.conf" ''
        unqualified-search-registries = ["docker.io"]

        [[registry]]
        prefix = "docker.io"
        location = "registry-1.docker.io"
        blocked = false

        [[registry]]
        prefix = "quay.io"
        location = "quay.io"
        blocked = false

        [[registry]]
        prefix = "gcr.io"
        location = "gcr.io"
        blocked = false
      '';
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
                    image: ${DockerContainer.name}:${version}
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
          containers-common 
          minikube
          kubectl
          podman
        ];
        text = ''
          set -euo pipefail

          export XDG_RUNTIME_DIR="/run/user/$(id -u)"
          mkdir -p "$XDG_RUNTIME_DIR"

          minikube config set rootless true
          minikube start --driver=podman

          minikube image load ${DockerContainer} --transfer=registry
          kubectl apply -f ${K8Manifests}

          echo "kubectl get all -l pp=${AppName}"
        '';
      };
    in {
      packages.deployment = DeployAPIS;
      devShells.default = pkgs.mkShell {
        buildInputs = [
          config.packages.deployment
          pkgs.containers-common
          pkgs.minikube
          pkgs.kubectl
          pkgs.podman
          py.flake8
        ];
        shellHook = ''
          export XDG_CONFIG_HOME="$HOME/.config"
          mkdir -p "$XDG_CONFIG_HOME/containers"

          install -m 0644 ${PolicyJSON}
          install -m 0644 ${RegistriesConf}

          export XDG_RUNTIME_DIR="/run/user/$(id -u)"
          mkdir -p "$XDG_RUNTIME_DIR"

          echo "DEVSHELL CONFIGURED!"
        '';
      };
    };
}