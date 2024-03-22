#Installation
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
#Getting Nginx chart from Bitnami
helm install Exercise2 oci://registry-1.docker.io/bitnamicharts/nginx
#Revision and pods
helm list
kubectl get pods
#Getting helm configuration file
helm show values oci://registry-1.docker.io/bitnamicharts/nginx > values.yaml
#Example of helm configuration file with Nginx and wrong version
 #-->values2.yaml
#Updating chart from modified config file
helm upgrade --install -f values.yaml Exercise2 oci://registry-1.docker.io/bitnamicharts/nginx
#Wrong results
helm list
kubectl get pods
#Rollback to revision 1
helm rollback Exercise2 1
#Restablished results from revision 1
helm list
kubectl get pods