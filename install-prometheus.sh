#!/bin/bash
# install-prometheus.sh

# Function to check if kubectl can access a cluster
check_kubernetes_access() {
    if kubectl get nodes &>/dev/null; then
        echo "Kubernetes cluster is accessible"
        return 0
    else
        echo "No Kubernetes cluster found"
        return 1
    fi
}

# Function to create kind cluster if needed
create_kind_cluster() {
    if ! command -v kind &>/dev/null; then
        echo "Kind is not installed. Please install kind first."
        exit 1
    fi

    cat <<EOF | kind create cluster --name kind-prometheus --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraMounts:
  - hostPath: ./prometheus-data
    containerPath: /prometheus-data
EOF
    
    echo "Kind cluster 'kind-prometheus' created"
}

# Check for existing cluster, create kind cluster if needed
if ! check_kubernetes_access; then
    echo "Creating kind cluster..."
    create_kind_cluster
fi

# Create namespace
kubectl create namespace prometheus

# Create persistent volume and claim
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: prometheus-pv
  namespace: prometheus
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
  hostPath:
    path: /prometheus-data
EOF

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: prometheus-pvc
  namespace: prometheus
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: standard
EOF

# Create ConfigMap for Prometheus config
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: prometheus
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      evaluation_interval: 15s
    scrape_configs:
      - job_name: 'prometheus'
        static_configs:
          - targets: ['localhost:9090']
      - job_name: 'kubernetes-service-endpoints'
        kubernetes_sd_configs:
          - role: endpoints
        relabel_configs:
          - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
            action: keep
            regex: true
EOF

# Create RBAC rules for Prometheus
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus
rules:
- apiGroups: [""]
  resources:
  - nodes
  - nodes/proxy
  - services
  - endpoints
  - pods
  verbs: ["get", "list", "watch"]
- apiGroups:
  - extensions
  resources:
  - ingresses
  verbs: ["get", "list", "watch"]
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
  namespace: prometheus
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus
subjects:
- kind: ServiceAccount
  name: prometheus
  namespace: prometheus
EOF

# Create Prometheus deployment with updated security context
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: prometheus
  labels:
    app: prometheus
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      securityContext:
        fsGroup: 65534
        runAsUser: 65534
        runAsGroup: 65534
        runAsNonRoot: true
      serviceAccountName: prometheus
      containers:
      - name: prometheus
        image: prom/prometheus:v2.44.0
        args:
          - "--config.file=/etc/prometheus/prometheus.yml"
          - "--storage.tsdb.path=/prometheus"
          - "--storage.tsdb.retention.time=15d"
        ports:
        - containerPort: 9090
        volumeMounts:
        - name: prometheus-config
          mountPath: /etc/prometheus/
        - name: prometheus-storage
          mountPath: /prometheus
      volumes:
      - name: prometheus-config
        configMap:
          name: prometheus-config
      - name: prometheus-storage
        persistentVolumeClaim:
          claimName: prometheus-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus
  namespace: prometheus
spec:
  selector:
    app: prometheus
  ports:
  - port: 9090
    targetPort: 9090
  type: ClusterIP
EOF

echo "Prometheus deployment complete!"
echo "To access Prometheus UI, run: kubectl port-forward -n prometheus svc/prometheus 9090:9090"
echo "Then visit: http://localhost:9090"
