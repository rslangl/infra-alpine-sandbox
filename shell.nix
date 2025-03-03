{ pkgs ? import ./nixpkgs.nix }:

  let tools = with pkgs; [
    docker
    ansible
  ];

  in pkgs.mkShell {
    packages = tools;
    inputsFrom = with pkgs; tools;

    shellHook = ''
      DOCKER_PID=""
      CONTAINER_IP=""

      trap 'echo "Cleanup in progres..."; sudo docker stop $(sudo docker ps -a -q); sudo docker rm -vf $(sudo docker ps -a -q); sudo docker rmi -f $(sudo docker images -aq); kill $DOCKER_PID; sed -i '2s/.*/CONTAINER/' inventory; echo "Cleanup completed!"' EXIT

      ssh-keygen -t rsa -b 4096 -f ssh/ssh -N "" -q

      echo "Starting Docker daemon..."
      sudo nohup dockerd > /tmp/dockerd.log 2>&1 &
      DOCKER_PID=$!
      sleep 1
      echo "Done!"

      echo "Building Docker image..."
      sudo docker build -t alpine:local .
      sleep 1
      echo "Done!"


      echo "Launching Docker container..."
      sudo docker run --name target -d alpine:local --name target
      CONTAINER_IP=$(sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' target)
      echo "Done!"

      sed -i "s/CONTAINER/$CONTAINER_IP/" inventory
      '';
  }
