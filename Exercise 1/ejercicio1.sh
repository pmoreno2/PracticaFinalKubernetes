#!/bin/bash
#STEP 8: Creation of kind-config.yaml file
echo "kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: \"ingress-ready=true\"
  extraPortMappings:
  - containerPort: 80
    hostPort: 28080
    protocol: TCP
  - containerPort: 443
    hostPort: 18080
    protocol: TCP
#  - containerPort: 5432
#    hostPort: 28080
#    protocol: TCP	
- role: worker
  extraMounts:
  - hostPath: /tmp/worker1
    containerPath: /work
- role: worker
  extraMounts:
  - hostPath: /tmp/worker2
    containerPath: /work
- role: worker
  extraMounts:
  - hostPath: /tmp/worker3
    containerPath: /work">>kind-config.yaml
kind create cluster --name moreno --config kind-config.yaml
sleep 2

#STEP 9: Labels into nodes 
kubectl label nodes moreno-worker type=front
kubectl label nodes moreno-worker2 type=front
kubectl label nodes moreno-worker3 type=back

#STEP 10: Creation of images
docker pull jlaredo/formacion-web-server-amd64
docker pull jlaredo/formacion-postgresql-amd64
docker pull jlaredo/formacion-static-server-amd64

#STEP 11: Creation of namespaces
kubectl create namespace frontend
kubectl create namespace backend
sleep 2

#STEP 12: Ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
sleep 2

#STEP 13: Creation of files
   #Config files
echo "apiVersion: v1
kind: ConfigMap
metadata:
  name: cm
  namespace: frontend
data:
  DB_USER: \"formacion\"
  DB_HOSTNAME: \"Pedro Moreno\"">>configmap.yaml
echo "apiVersion: v1
kind: Secret
metadata:
  name: passwd
  namespace: frontend
data:
  DB_PASSWORD: S3ViZXJuZXRlcwo=
type: Opaque">>secret.yaml
kubectl apply -f configmap.yaml
sleep 2
kubectl apply -f secret.yaml
sleep 2
   #Volumed files
echo "apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
    - ReadOnlyMany
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /work">>pv.yaml
echo "apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc
#  namespace: backend
spec:
  resources:
    requests:
      storage: 1Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: \"\"">>pvc.yaml
kubectl apply -f pv.yaml
sleep 2
kubectl apply -f pvc.yaml
sleep 2
   #Service files
echo "apiVersion: v1
kind: Service
metadata:
  name: webservice
  namespace: frontend
spec:
  selector:
    app: webserver
  ports:
  - name: web
    port: 80
    protocol: TCP
    targetPort: 80
#  type: ClusterIP">> service-web.yaml
echo "apiVersion: v1
kind: Service
metadata:
  name: database
  namespace: backend
spec:
  selector:
    app: database
  ports:
  - name: database-port
    port: 5432
    protocol: TCP
    targetPort: 5432
#  type: ClusterIP">> service-db.yaml
echo "apiVersion: v1
kind: Service
metadata:
  name: static-server
  namespace: frontend
spec:
  selector:
    app: static-server
  ports:
  - name: static-web
    port: 80
    protocol: TCP
    targetPort: 80
#  type: ClusterIP">> service-ss.yaml
kubectl apply -f service-web.yaml
sleep 2
kubectl apply -f service-db.yaml
sleep 2
kubectl apply -f service-ss.yaml
sleep 2
   #Ingress files
echo "apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webserver
  namespace: frontend
spec:
  rules:
  - http:
      paths:
        - backend:
            service:
              name: webserver
              port:
                number: 80
          path: /
          pathType: Prefix">> ingress-web.yaml
sleep 2
echo "apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: static-server
  namespace: frontend
spec:
  rules:
  - http:
      paths:
        - backend:
            service:
              name: static-server
              port:
                number: 80
          path: /static
          pathType: Prefix">> ingress-ss.yaml
sleep 3
kubectl apply -f ingress-web.yaml
sleep 3
kubectl apply -f ingress-ss.yaml
sleep 3

#STEP 14: Creation of web server
#Web-->replicaset1.yaml
echo "apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: web
  namespace: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: webserver
  template:
    metadata:
      labels:
        app: webserver
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: type
                operator: In
                values:
                - front
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - webserver
            topologyKey: \"kubernetes.io/hostname\"
      containers:
      - name: web-server
        image: jlaredo/formacion-web-server-amd64
        envFrom:
          - configMapRef:
              name: cm
          - secretRef:
              name: passwd
        resources:
          requests:
            memory: 128M
            cpu: 0.1
          limits:
            memory: 256M
            cpu: 0.2
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 5">>replicaset1.yaml
kubectl apply -f replicaset1.yaml
sleep 2

#STEP 15: Creation of database
#Base de datos-->deployment.yaml
echo "apiVersion: apps/v1
kind: Deployment
metadata:
  name: database
  namespace: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: type
                operator: In
                values:
                - back
      containers:
        - name: database
          image: jlaredo/formacion-postgresql-amd64
          resources:
            requests:
              memory: 64M
              cpu: 0.1
            limits:
              memory: 128M
              cpu: 0.2
          ports:
            - containerPort: 5432
          livenessProbe:
            httpGet:
              path: /
              port: 5432
            initialDelaySeconds: 10
            periodSeconds: 5
          volumeMounts:
          - name: data
            mountPath: /var/lib/postgresql/data
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: pvc">>deployment.yaml
kubectl apply -f deployment.yaml
sleep 2

#STEP 16: Creation of content server
#Server contenidos-->replicaset2.yaml
echo "apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: static-server
  namespace: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: static-server
  template:
    metadata:
      labels:
        app: static-server
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: type
                operator: In
                values:
                - front
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - static-server
            topologyKey: \"kubernetes.io/hostname\"
      containers:
      - name: static-server
        image: jlaredo/formacion-static-server-amd64
        resources:
          requests:
            memory: 64M
            cpu: 0.1
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 5">>replicaset2.yaml
kubectl apply -f replicaset2.yaml
sleep 2

#STEP 17: testing
#Web
kubectl get pods --namespace=frontend -owide --namespace=frontend
#kubectl describe replicaset --namespace=frontend
kubectl get pods --namespace=backend -owide --namespace=backend
#kubectl describe deployment --namespace=backend
