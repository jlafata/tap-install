There is an [issue](https://jira.eng.vmware.com/browse/TANZUSC-821) with GKE Zonal type clusters during the installation where the cluster is overloaded even if there are enough resources available and it goes several times into a repair state / requests to the Kubernetes API timeout because Zonal clusters have a single control plane in a single zone. You have to wait for some time until every sub-package is in `ReconcileSucceeded` state.
For a better experience it's **recommended to switch to a Regional type cluster**.

With the following commands, you can provision a Regional type cluster with the [gcloud CLI](https://cloud.google.com/sdk/docs/install).
```
REGION=europe-west3
CLUSTER_ZONE="$REGION-a"
CLUSTER_VERSION=$(gcloud container get-server-config --format="yaml(defaultClusterVersion)" --region $REGION | awk '/defaultClusterVersion:/ {print $2}')
gcloud beta container clusters create tap --region $REGION --cluster-version $CLUSTER_VERSION --machine-type "e2-standard-2" --num-nodes "4" --node-locations $CLUSTER_ZONE --enable-pod-security-policy
gcloud container clusters get-credentials tap --region $REGION
```
Configure Pod Security Policies so that Tanzu Application Platform controller pods can run as root.
```
kubectl create clusterrolebinding tap-psp-rolebinding --group=system:authenticated --clusterrole=gce:podsecuritypolicy:privileged
```