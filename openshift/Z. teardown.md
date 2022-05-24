

### delete dev namespace
`./delete-additional-dev-space.sh dev-space`

### delete cluster
`export CLUSTER_ID=1samvqb6k32h9ptd2bvjepgr0d1hnai0`

`./rosa delete cluster  --cluster $CLUSTER_ID --yes`

`./rosa delete operator-roles --mode auto --yes --cluster $CLUSTER_ID`
```
    I: Successfully deleted the operator roles
```
	
`./rosa delete oidc-provider --mode auto --yes --cluster $CLUSTER_ID`
```
    I: Successfully deleted the OIDC provider arn:aws:iam::806421138648:oidc-provider/rh-oidc.s3.us-east-1.amazonaws.com/1r7u06dmh45q617icjrvkhhgt9bprm0d
```