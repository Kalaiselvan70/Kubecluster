
#!/bin/bash
#
# Setup for Control Plane (Master) servers

set -euxo pipefail

NODENAME=$(hostname -s)
POD_CIDR="192.168.0.0/16"
MASTER_PRIVATE_IP="<replace with the ip of master node>"

# Pull required images

sudo kubeadm config images pull

# Initialize kubeadm

sudo kubeadm init --pod-network-cidr="$POD_CIDR" --node-name "$NODENAME" --apiserver-advertise-address="$MASTER_PRIVATE_IP" --control-plane-endpoint="$MASTER_PRIVATE_IP":6443 --ignore-preflight-errors Swap

# Join Worker nodes to the cluster from  the output when we initialize kubeadm Run on worker nodes
#sudo kubeadm join k8s-master-01:6443 --token <your-token> --discovery-token-ca-cert-hash sha256:<your-hash>

# Configure kubeconfig

mkdir -p "$HOME"/.kube
sudo cp -i /etc/kubernetes/admin.conf "$HOME"/.kube/config
sudo chown "$(id -u)":"$(id -g)" "$HOME"/.kube/config

# Install Claico Network Plugin Network 

kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

kubectl get pods -n kube-system -w
kubectl get nodes  # Ensure all nodes are Ready

