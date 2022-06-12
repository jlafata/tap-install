---
###
### security context constraints required to install the accelerator-controller-manager
###
kind: SecurityContextConstraints
apiVersion: security.openshift.io/v1
metadata:
  name: accelerator-scc

###
### values needed for the security context of the accelerator-controller-manager-scc
###

runAsUser:
  type: MustRunAs
  uid: 1000
fsGroup:
  type: RunAsAny

###
### required values in a security context 
###
allowHostDirVolumePlugin: false
allowHostIPC: false
allowHostNetwork: false
allowHostPID: false
allowHostPorts: false
allowPrivilegedContainer: false
readOnlyRootFilesystem: false
seLinuxContext:
  type: MustRunAs

###
### make sure this is only used by the accelerator-controller-manager service account
###
users:
  - system:serviceaccount:accelerator-system:accelerator-controller-manager
---
###
### role for binding serviceaccount to constraint
###
### reference for binding serviceaccount to constraint
### https://docs.openshift.com/container-platform/4.6/authentication/managing-security-context-constraints.html#role-based-access-to-ssc_configuring-internal-oauth
###
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: accelerator-scc-role
  namespace: accelerator-system
rules:
  - apiGroups:
      - security.openshift.io
    resourceNames:
      - accelerator-scc
    resources:
      - securitycontextconstraints
    verbs:
      - use
---
###
### role binding for binding serviceaccount to constraint
###
apiVersion: rbac.authorization.k8s.io/v1
# This role binding grants "accelerator" service accounts membership to Role accelerator-role
kind: RoleBinding
metadata:
  name: accelerator-scc-role-binding
  namespace: accelerator-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: accelerator-scc-role
subjects:
  - kind: ServiceAccount
    namespace: accelerator-system
    name: accelerator-controller-manager
  - kind: ServiceAccount
    namespace: accelerator-system
    name: accelerator-server
  - kind: ServiceAccount
    namespace: accelerator-system
    name: accelerator-engine