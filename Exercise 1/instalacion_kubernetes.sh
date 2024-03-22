#!/bin/bash
#STEP 1: General tools
#apt update
#apt upgrade
sudo apt install -y curl
sudo apt install -y ssh

#STEP 2: Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl

#STEP 3: Install Docker
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
apt-cache policy docker-ce
sudo apt install -y docker-ce
sudo usermod -aG docker ${USER}
#sudo usermod -aG docker pedro

#STEP 4: Install Go
wget https://go.dev/dl/go1.19.3.linux-arm64.tar.gz
tar xvf go1.19.3.linux-arm64.tar.gz 
sleep 5
sudo mv go/ /usr/local/bin/
PATH=$PATH:/usr/local/bin/go/bin/

#STEP 5: Install Kind
sudo apt-get install -y golang
go install sigs.k8s.io/kind@v0.17.0
sudo mv go/bin/kind /usr/local/bin/go/bin

#STEP 6: Make persistent alias and Kind access
sudo echo "#Persistent alias for kbectl">>~/.bashrc
sudo echo "alias k=\"kubectl\"">>~/.bashrc
sudo echo "#Persistent variable for program Kind">>~/.bashrc
sudo echo "export PATH=\$PATH:/usr/local/bin/go/bin">>~/.bashrc

#STEP 7: testing tools
docker -v
kind version
kubectl version
sudo shutdown -r 0