#STEP 1: Installation
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
#STEP 2: Getting Nginx chart from Bitnami
helm install exercise2 oci://registry-1.docker.io/bitnamicharts/nginx
sleep 10
#STEP 3: Revision and pods
helm list
kubectl get pods
#STEP 4: Getting helm configuration file
helm show values oci://registry-1.docker.io/bitnamicharts/nginx > values.yaml
#STEP 5: Example of helm configuration file with Nginx and wrong version
 sed -i 's/tag: 1.25.4-debian-12-r3/tag: 1000000.25.4-debian-12-r3/g' values.yaml
#STEP 6: Updating chart from modified config file
helm upgrade --install -f values.yaml exercise2 oci://registry-1.docker.io/bitnamicharts/nginx
sleep 10
#STEP 7: Wrong results
helm list
kubectl get pods
#STEP 8: Rollback to revision 1
helm rollback exercise2 1
sleep 10
#STEP 9: Restablished results from revision 1
helm list
kubectl get pods