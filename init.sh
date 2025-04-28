#!/bin/sh

KUSER="$1"
KROLE="$2"
KNS="$3"

echo "---"
echo "Create work directory"
echo "---"
mkdir -v "$KUSER"

echo "---"
echo "Generate rsa 4096 key"
echo "---"
openssl genrsa -out "$KUSER"/user.key 4096

echo "---"
echo "Generate certificate request"
echo "---"
openssl req -new -key "$KUSER"/user.key -out "$KUSER"/user.csr -subj "/CN=$KUSER"

echo "---"
echo "Create CertificateSigningRequest"
echo "---"
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: "$KUSER"
spec:
  request: $(base64 < "$KUSER"/user.csr | tr -d "\n")
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400000
  usages:
  - client auth
EOF

echo "---"
echo "Approve CSR"
echo "---"
kubectl certificate approve "$KUSER"

echo "---"
echo "Copy approved certificate to file"
echo "---"
kubectl get csr "$KUSER" -o jsonpath='{.status.certificate}' | base64 -d > "$KUSER"/user.crt

echo "---"
echo "Copy base kubeconfig.yaml in work directory"
echo "---"
cp -v kubeconfig.yaml "$KUSER"/kubeconfig.yaml

echo "---"
echo "Place certificate and key in kubeconfig.yaml"
echo "---"
kubectl config set-credentials "$KUSER" \
	--client-certificate="$KUSER"/user.crt \
	--client-key="$KUSER"/user.key \
	--embed-certs=true \
	--kubeconfig="$KUSER"/kubeconfig.yaml

echo "---"
echo "Set context and user in kubeconfig.yaml"
echo "---"
kubectl config set-context default \
	--cluster=default \
	--kubeconfig="$KUSER"/kubeconfig.yaml \
	--user="$KUSER"

echo "---"
echo "Check kubeconig.yaml is working fine"
echo "---"
KUBECONFIG="$KUSER/kubeconfig.yaml" kubectl --context default auth whoami

echo "---"
echo "Create Role" 
echo "---"
kubectl -n "$KNS" create role "$KROLE" \
	--output=yaml \
	--resource=deploy \
	--resource=pods \
	--verb=get > \
	"$KUSER"/Role.yaml

echo "---"
echo "Create RoleBinding"
echo "---"
kubectl -n "$KNS" create rolebinding "$KUSER" \
	--output=yaml \
	--role="$KROLE" \
	--user="$KUSER" > \
	"$KUSER"/RoleBinding.yaml

echo "---"
echo "Clean up"
echo "---"
rm -v ./"$KUSER"/user.*
