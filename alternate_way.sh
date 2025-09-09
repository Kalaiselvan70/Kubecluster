#Ref: https://computingforgeeks.com/deploy-kubernetes-cluster-on-ubuntu-with-kubeadm/
# Ref: https://computingforgeeks.com/install-mirantis-cri-dockerd-as-docker-engine-shim-for-kubernetes/
# Ref: https://github.com/flannel-io/flannel
# Ref: https://github.com/containerd/containerd/discussions/8033
# Ref : https://www.nakivo.com/blog/install-kubernetes-ubuntu/
# Ref: https://www.learnlinux.tv/how-to-build-an-awesome-kubernetes-cluster-using-proxmox-virtual-environment/

# install 4 ubuntu VMs with Minimal installation
set up static IP

#upgrade repositories
sudo apt update
sudo apt upgrade

#install hypervisor agent depends on the host
sudo apt install open-vm-tools or sudo apt install qemu-guest-agent

#install nano and ping
sudo install nano
sudo apt install iputils-ping

#install cokpit
. /etc/os-release
sudo apt install -t ${VERSION_CODENAME}-backports cockpit

# update the hostame and ip on /etc/hosts keyfile
192.168.1.XX kube-p01
192.168.1.yy	kube-p02
192.168.1.zz	kube-p03

## Step 1 – Disable Swap and Enable IP Forwarding

#Verify and disable swap
sudo swapoff -a

# Disable Swap permanently
sudo nano /etc/fstab
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# enable IP Forwarding
sudo nano /etc/sysctl.conf
# net.ipv4.ip_forward = 1   # uncomment this line
sudo sysctl -p  # to apply conf changes


## Step 2 – Install Docker CE

# install prerequisite will allow apt to use packages over https
sudo apt install apt-transport-https ca-certificates curl software-properties-common

# Add the GPG key for official Docker repositories
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add the Docker repository to APT sources:
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# sudo apt update
apt-cache policy docker-ce # to make sure the installation is from docker repository

# Install and check the docker status
sudo apt install docker-ce
sudo systemctl status docker

# Executing the docker command without sudo by adding a user to docker group and apply the same
sudo usermod -aG docker ${USER}
su - ${USER}

## Step 3 – Add Kubernetes Repository

# Add K8s GPG key and repository
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/kubernetes-xenial.gpg
sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
sudo apt update -y


## Step 4 – Install Kubernetes Components (Kubectl, kubelet and kubeadm)

sudo apt-get install kubelet kubeadm kubectl -y

# update the cgroupdriver on all nodes
sudo nano /etc/docker/daemon.json

{ "exec-opts": ["native.cgroupdriver=systemd"],
"log-driver": "json-file",
"log-opts":
{ "max-size": "100m" },
"storage-driver": "overlay2"
}

# reload the systemd daemon and docker service
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl enable docker

## Step 5 – Initialize Kubernetes Master Node

# run the below command in master nodes
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# solution to fix the below issue
#container runtime is not running: output: time="2023-10-24T20:33:17Z" level=fatal msg="validate service connection:
#CRI v1 runtime API is not implemented for endpoint \"unix:///var/run/containerd/containerd.sock\": rpc error: code = Unimplemented desc = unknown service runtime.v1.RuntimeService"

sudo apt remove containerd
sudo apt update
sudo apt install containerd.io
sudo rm /etc/containerd/config.toml
sudo systemctl restart containerd

# run the below commands if we logged in as normal usermod
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


## Step 6 – Deploy a Pod Network

# run the below commands in Master nodes
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
