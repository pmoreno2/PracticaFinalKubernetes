#!/bin/bash
#STEP 8: Creation of kind-config.yaml file
kind create cluster --name moreno --config kind-config.yaml

#STEP 9: Labels into nodes 
kubectl label nodes moreno-worker type=front
kubectl label nodes moreno-worker2 type=front
kubectl label nodes moreno-worker3 type=back

#STEP 10: Creation of namespaces
kubectl create namespace frontend
kubectl create namespace backend

#STEP 11: Creation of files
   #Config files
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml

   #Volumed files
kubectl apply -f pv.yaml
kubectl apply -f pvc.yaml

#STEP 12: Service files
   #Service files
kubectl apply -f service-web.yaml
kubectl apply -f service-db.yaml
kubectl apply -f service-ss.yaml

#STEP 13: Ingress files
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission
kubectl apply -f ingress.yaml

#STEP 14: Creation of web server
#Web-->replicaset1.yaml
kubectl apply -f replicaset1.yaml

#STEP 15: Creation of database
#Base de datos-->deployment.yaml
kubectl apply -f deployment.yaml

#STEP 16: Creation of content server
#Server contenidos-->replicaset2.yaml
kubectl apply -f replicaset2.yaml


#STEP 17: testing
#Web
kubectl get pods --namespace=frontend -owide --namespace=frontend
#kubectl describe replicaset --namespace=frontend
kubectl get pods --namespace=backend -owide --namespace=backend
#kubectl describe deployment --namespace=backend
