# kubernetes-config-generator
Based on https://kubernetes.io/docs/tasks/tls/certificate-issue-client-csr/

## How to use
You should have rights to work with cerificates, roles and rolebindings

Just `./init.sh <user> <role> <namespace>`

## Cleanup
To delete user, run `./clean.sh <user> <role> <namespace>`
