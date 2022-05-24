tanzu package installed delete tap -n tap-install

kubectl delete ns tap-install

kubectl delete ns external-dns

kubectl delete clusterrole/external-dns          

kubectl delete clusterrolebinding/external-dns-viewer
