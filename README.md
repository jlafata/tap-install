# Unofficial TAP 1.1 installation guide 

***What's New: Script for the creation of additional developer namespaces for the OOTB Supply Chain with Testing and Scanning***

This installation guide should help you to install TAP 1.1 with wildcard certificates and [external-dns](https://github.com/kubernetes-sigs/external-dns) to a Kubernetes cluster.

It's always recommended to go through the official documentation in addition to this guide!
The scripts and commands in this guide were executed on an Amazon Linux 2 jumpbox. It's recommended to go through them step by step!

To also install the [Application Service Adapter for VMware Tanzu Application Platform public beta](https://tanzu.vmware.com/content/blog/application-service-adapter-for-vmware-tanzu-application-platform-2), you can follow the instructions [here](tas-adapter) after the installation of TAP.

### Resources
 - [1.1 documentation](https://docs.vmware.com/en/Tanzu-Application-Platform/1.1/tap/GUID-overview.html)

### Prerequisites 
- [Pivnet CLI](https://github.com/pivotal-cf/pivnet-cli#installing)
- A domain (configured in Route53 - Route53 need is relevant to lets encrypt cert management and external-dns )

##### local software
- yq version 4


## Provision a Kubernetes cluster

The scripts are currently only validated with GKE and AWS EKS, and Azure AKS!

### GKE
Follow these instructions to create a cluster
[GKE cluster creation](GKE/A_cluster_creation.md)

### AWS EKS
Follow these instructions to create a cluster
[AWS EKS cluster creation](EKS/A_cluster_creation.md)

### AKS Azure
Follow these instructions to create a cluster
[AKS Azure cluster creation](AKS/A_cluster_creation.md)

### Redhat Openshift on AWS (ROSA) 
Follow these instructions to create a cluster
[OpenShift cluster creation](openshift/A_create_cluster.md)

##### Security Context Constraints specific for openshift only
###### Create Security Context Constraints allowing specific runAsId's and permissions used by TAP  
```
kubectl apply -f openshift/scc-1.1.0-core
```
#### if you are installing the full profile, also run this
```
kubectl apply -f openshift/scc-1.1.0-full
```

## Prepare values.yaml ( if you haven't already )
Copy values-example.yaml to values.yaml and set configuration values
```
cp values-example.yaml values.yaml
```

You have to create two private projects in Harbor with the names configured in `project` and `project_workload` of your values.yaml (default: **tap**, **tap-wkld**).
For other registries you may have to change the format of the `kp_default_repository` and `ootb_supply_chain_testing_scanning.registry.repository` configuration values in `tap-values.yaml` 


## Install Cluster Essentials for VMware Tanzu

[Documentation](https://docs.vmware.com/en/Tanzu-Application-Platform/1.0/tap/GUID-install-general.html#tanzu-cluster-essentials)

The Cluster Essentials are already installed if you are operating a Tanzu Kubernetes Grid or Tanzu Community Edition cluster.
For other Kubernetes providers, follow the steps below. 

If you're running on a Linux box:
```
./install-cluster-essentials.sh linux
sudo install tanzu-cluster-essentials/kapp /usr/local/bin/kapp 
```

If you're running on a Mac:
```
./install-cluster-essentials.sh darwin
sudo install tanzu-cluster-essentials/kapp /usr/local/bin/kapp 
```

## Install Tanzu CLI
[Documentation](https://docs.vmware.com/en/Tanzu-Application-Platform/1.0/tap/GUID-install-general.html#install-or-update-the-tanzu-cli-and-plugins-7)
### Clean install
If you're running on a Linux box:
```
./install-cli.sh linux
```

If you're running on a Mac:
```
./install-cli.sh darwin
```
### Update Tanzu CLI 
[Documentation](https://docs.vmware.com/en/Tanzu-Application-Platform/1.0/tap/GUID-install-general.html#instructions-for-updating-tanzu-cli-that-was-installed-for-a-previous-release-of-tanzu-application-platform-10)
If the instructions don't work and the `tanzu version` output is not as expected (v0.11.1), you can delete the wrong CLI version 
with the following commands and do a clean install.
```
sudo rm /usr/local/bin/tanzu
## Remove config directories
rm -rf ~/.config/tanzu/   # current location
rm -rf ~/.tanzu/          # old location
## Remove plugins on macOS
rm -rf ~/Library/Application\ Support/tanzu-cli/*
## Remove plugins on Linux
rm -rf ~/.local/share/tanzu-cli/*
```

## Option 1 - Install TAP View profile only, the view profile currently assumes http protocol to the TAP-gui, it's the simplest install
```
./view-profile-install.sh
```

## Option 2 - Install TAP Full profile
[Documentation](https://docs.vmware.com/en/Tanzu-Application-Platform/1.0/tap/GUID-install.html)

Run one of the following installation scripts as appropriate for your cert requirements.
I prefer to use the self-signed install in the first install, in case you need to iterate over the installation a few times
the lets encrypt system has a rate limiter that causes the cert to not be generated if you run it > 5 times for the same domain key                                                                                                                      
```
./full-profile-self-signed-install.sh
```
or
```
./full-profile-letsencrypt-install.sh
```
or, though this one is currently untested, as of May 27, 2022
```
./full-profile-custom-ca-install.sh
```


## Set DNS records for tap-gui.<ingress-domain> as appropriate for your install
`kubectl get svc -n tanzu-system-ingress`

## validate httpproxy records 
##### important if you are using ClusterIP and httpproxy, letsencrypt certs and https protocol for ingress] 
kubectl get httpproxy -A


## if you installed the full profile, finish configuring the workload namespace 
`./configure-dev-space.sh dev-space`



## Tips
- You can update installation on updates in your values.yaml via 
    ```
    ytt -f tap-values.yaml -f values.yaml --ignore-unknown-comments > generated/tap-values.yaml
    tanzu package installed update tap --package-name tap.tanzu.vmware.com --version 1.1.0 --values-file generated/tap-values.yaml -n tap-install
    ```
- You can get a list of all the installed TAP packages via `tanzu package installed list -n tap-install` or `kubectl get PackageInstall -n tap-install` and have closer look at one of the installed packages via `kubectl describe PackageInstall <package-name> -n tap-install`
- To get a PackageInstallation reconcile immediately, you can use the [kctrl CLI](https://carvel.dev/kapp-controller/docs/v0.36.1/package-command/)
   ```
   kctrl package installed kick -i <package-installation-name> -n tap-install
   ```
   or the following script
   ```
   function reconcile-packageinstall() {
           TAPNS=tap-install
           kubectl -n $TAPNS patch packageinstalls.packaging.carvel.dev $1 --type='json' -p '[{"op": "add", "path": "/spec/paused", "value":true}]}}'
           kubectl -n $TAPNS patch packageinstalls.packaging.carvel.dev $1 --type='json' -p '[{"op": "add", "path": "/spec/paused", "value":false}]}}'
   }
   reconcile-packageinstall <package-installation-name>
   ```
## Create [additional] developer namespace
Currently there is no way to support multiple developer namespaces with the profile installation for the OOTB Supply Chain with Testing and Scanning.
The reason for that is that Custom Resources(CR) required for scanning (Grype) are, at this point, namespace-scoped instead of cluster-scoped. 

This scripts helps you to create additional developer namespaces with everything setup.
```
./create-additional-dev-space.sh <dev-ns>
```

result
```
12:44:47PM:  ^ Reconciling
12:44:51PM: fail: reconcile packageinstall/dev-space-grype (packaging.carvel.dev/v1alpha1) namespace: tap-install
12:44:51PM:  ^ Reconcile failed:  (message: Error (see .status.usefulErrorMessage for details))

kapp: Error: waiting on reconcile packageinstall/dev-space-grype (packaging.carvel.dev/v1alpha1) namespace: tap-install:
  Finished unsuccessfully (Reconcile failed:  (message: Error (see .status.usefulErrorMessage for details)))
```


```
kubectl describe packageinstall/dev-space-grype -n tap-install
```
```
Status:
  Conditions:
    Message:               Error (see .status.usefulErrorMessage for details)
    Status:                True
    Type:                  ReconcileFailed
  Friendly Description:    Reconcile failed: Error (see .status.usefulErrorMessage for details)
  Last Attempted Version:  1.1.0
  Observed Generation:     1
  Useful Error Message:    kapp: Error: Ownership errors:
- Resource 'scantemplate/private-image-scan-template (scanning.apps.tanzu.vmware.com/v1beta1) namespace: dev-space' is already associated with a different app 'grype-ctrl' namespace: tap-install (label 'kapp.k14s.io/app=1653842044992399855')
- Resource 'scantemplate/blob-source-scan-template (scanning.apps.tanzu.vmware.com/v1beta1) namespace: dev-space' is already associated with a different app 'grype-ctrl' namespace: tap-install (label 'kapp.k14s.io/app=1653842044992399855')
- Resource 'scantemplate/public-source-scan-template (scanning.apps.tanzu.vmware.com/v1beta1) namespace: dev-space' is already associated with a different app 'grype-ctrl' namespace: tap-install (label 'kapp.k14s.io/app=1653842044992399855')
- Resource 'scantemplate/public-image-scan-template (scanning.apps.tanzu.vmware.com/v1beta1) namespace: dev-space' is already associated with a different app 'grype-ctrl' namespace: tap-install (label 'kapp.k14s.io/app=1653842044992399855')
  Version:  1.1.0
```

The script will not create a Tekton CI pipeline or Scan Policy. See the [Usage](#usage) section on how to do this.

*Hint: With the following command, you can check whether your developer namespace contains the required CRs for scanning.*
```
kubectl get ScanTemplate -n <dev-ns>
```

## Delete additional developer namespace
Deletes all resources created via the `create-additional-dev-space.sh` script.
```
./delete-additional-dev-space.sh <dev-ns>
```

## Usage
[usage reference](README-USAGE.md)


## experimental - add identity provider to tap-gui
Create a provider as described here:

`https://backstage.io/docs/auth/github/provider`

OIDC Auth provider with pinniped:

`https://docs.google.com/document/d/1-q6Sphk_n5NC4k3ws6VMCCq8l2xDkUihY3jT2HuZeWM/edit?userstoinvite=bhale@vmware.com&actionButton=1#heading=h.yappl5s2rums`


Update tap-values & values.yaml to use the name of your provider, in the example I am using os-sandbox
reference:

`https://docs.vmware.com/en/Tanzu-Application-Platform/1.1/tap/GUID-tap-gui-auth.html`
