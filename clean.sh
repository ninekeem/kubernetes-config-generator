#!/bin/sh

KUSER="$1"
KROLE="$2"
KNS="$3"

rm -vfr ./"$KUSER"
kubectl delete csr "$KUSER"
kubectl -n "$KNS" delete role "$KROLE"
kubectl -n "$KNS" delete rolebinding "$KUSER"
