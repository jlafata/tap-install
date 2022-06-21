# Usage   
[Back to README.md](README.md)
[Documentation](https://docs.vmware.com/en/Tanzu-Application-Platform/1.0/tap/GUID-getting-started.html)

Save the configured developer namespace to an env variable via
```
DEVELOPER_NAMESPACE=$(cat values.yaml  | grep developer_namespace | awk '/developer_namespace:/ {print $2}')
```

Create a Tekton CI pipeline that runs the unit-tests via
```
kubectl apply -f demo/tekton-pipeline.yaml -n $DEVELOPER_NAMESPACE
```

Create a scan policy via
```
kubectl apply -f demo/scan-policy.yaml -n $DEVELOPER_NAMESPACE
```

Create a workload via
```
tanzu apps workload create tanzu-java-web-app -n $DEVELOPER_NAMESPACE \
--git-repo https://github.com/tsalm-pivotal/tap-tanzu-java-web-app \
--git-branch main \
--type web \
--label apps.tanzu.vmware.com/has-tests=true \
--label app.kubernetes.io/part-of=tanzu-java-web-app \
--yes
```

Have a look at the logs and created resources via the following commands
```
tanzu apps workload tail tanzu-java-web-app -n $DEVELOPER_NAMESPACE --since 10m --timestamp
kubectl get workload,gitrepository,sourcescan,pipelinerun,images.kpack,imagescan,podintent,app,services.serving -n $DEVELOPER_NAMESPACE
tanzu apps workload get tanzu-java-web-app -n $DEVELOPER_NAMESPACE
```

## Debug app workload
[Debug app workload](README-debug-app-deploy.md)

### Tips
- [kubectl tree](https://github.com/ahmetb/kubectl-tree) is great [krew](https://krew.sigs.k8s.io) plugin to explore ownership relationships between Kubernetes objects. Here is an example for the created Workload:
```
kubectl tree workload tanzu-java-web-app -n $DEVELOPER_NAMESPACE
NAMESPACE  NAME                                                  READY    REASON               AGE
dev-space  Workload/tanzu-java-web-app                           True     Ready                5m51s
dev-space  ├─ConfigMap/tanzu-java-web-app                        -                             3m6s
dev-space  ├─Deliverable/tanzu-java-web-app                      Unknown  ConditionNotMet      5m43s
dev-space  │ ├─App/tanzu-java-web-app                            -                             2m34s
dev-space  │ └─ImageRepository/tanzu-java-web-app-delivery       True                          5m39s
dev-space  ├─GitRepository/tanzu-java-web-app                    True     GitOperationSucceed  5m47s
dev-space  ├─Image/tanzu-java-web-app                            True                          4m51s
dev-space  │ ├─Build/tanzu-java-web-app-build-1                  -                             4m51s
dev-space  │ │ └─Pod/tanzu-java-web-app-build-1-build-pod        False    PodCompleted         4m50s
dev-space  │ ├─PersistentVolumeClaim/tanzu-java-web-app-cache    -                             4m51s
dev-space  │ └─SourceResolver/tanzu-java-web-app-source          True                          4m51s
dev-space  ├─ImageScan/tanzu-java-web-app                        -                             3m46s
dev-space  │ └─Job/scan-tanzu-java-web-appzgfvv                  -                             3m46s
dev-space  │   └─Pod/scan-tanzu-java-web-appzgfvv-fjf4g          False    PodCompleted         3m46s
dev-space  ├─PodIntent/tanzu-java-web-app                        True                          3m10s
dev-space  ├─Runnable/tanzu-java-web-app                         True     Ready                5m43s
dev-space  │ └─PipelineRun/tanzu-java-web-app-kx2ff              -                             5m39s
dev-space  │   └─TaskRun/tanzu-java-web-app-kx2ff-test           -                             5m39s
dev-space  │     └─Pod/tanzu-java-web-app-kx2ff-test-pod         False    PodCompleted         5m39s
dev-space  ├─Runnable/tanzu-java-web-app-config-writer           True     Ready                3m6s
dev-space  │ └─TaskRun/tanzu-java-web-app-config-writer-7hfr6    -                             3m3s
dev-space  │   └─Pod/tanzu-java-web-app-config-writer-7hfr6-pod  False    PodCompleted         3m3s
dev-space  └─SourceScan/tanzu-java-web-app                       -                             5m7s
dev-space    └─Job/scan-tanzu-java-web-appmbg65                  -                             5m7s
dev-space      └─Pod/scan-tanzu-java-web-appmbg65-b8k9k          False    PodCompleted         5m7s
```
- If the `mvnw` executable in your workload's repository doesn't have executable permissions(`chmod +x mvnw`) the Tektok pipeline will fail with a `./mvnw: Permission denied` error. To fix this for all java Maven workloads, this is done in the `demo/tekton-pipeline.yaml`.

### Query for vulnerabilities
[Documentation](https://docs.vmware.com/en/Tanzu-Application-Platform/1.1/tap/GUID-scst-store-query_data.html)
Run the following command
```
kubectl describe imagescans tanzu-java-web-app -n $DEVELOPER_NAMESPACE
```
or query the metrics store with the insight CLI. [Documentation](https://docs.vmware.com/en/Tanzu-Application-Platform/1.1/tap/GUID-cli-plugins-insight-cli-overview.html)
```
export METADATA_STORE_ACCESS_TOKEN=$(kubectl get secrets -n metadata-store -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='metadata-store-read-write-client')].data.token}" | base64 -d)
export INGRESS_DOMAIN=$(cat values.yaml | grep ingress -A 3 | awk '/domain:/ {print $2}')

tanzu insight config set-target https://metadata-store.${INGRESS_DOMAIN} --access-token=$METADATA_STORE_ACCESS_TOKEN
EXAMPLE_DIGEST=$(kubectl get kservice tanzu-java-web-app -n $DEVELOPER_NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].image}' | awk -F @ '{ print $2 }')
tanzu insight image get --digest $EXAMPLE_DIGEST --format json
tanzu insight image packages --digest $EXAMPLE_DIGEST --format json
tanzu insight image vulnerabilities --digest $EXAMPLE_DIGEST --format json
```

[Back to README.md](README.md)


`describe pod/tanzu-java-web-app-fhpfq-test-pod -n dev-space | grep scc`

```
              openshift.io/scc: restricted
```

```
pod security context
    securityContext:
      capabilities:
        drop:
        - KILL
        - MKNOD
        - SETGID
        - SETUID
      runAsUser: 1009290000
```      
      
`kubectl describe runnable.carto.run/tanzu-java-web-app -n dev-space`           
```
Name:         tanzu-java-web-app
Namespace:    dev-space
Labels:       app.kubernetes.io/component=test
              app.kubernetes.io/part-of=tanzu-java-web-app
              apps.tanzu.vmware.com/has-tests=true
              apps.tanzu.vmware.com/workload-type=web
              carto.run/cluster-template-name=testing-pipeline
              carto.run/resource-name=source-tester
              carto.run/supply-chain-name=source-test-scan-to-url
              carto.run/template-kind=ClusterSourceTemplate
              carto.run/workload-name=tanzu-java-web-app
              carto.run/workload-namespace=dev-space
Annotations:  <none>
API Version:  carto.run/v1alpha1
Kind:         Runnable
Metadata:
  Creation Timestamp:  2022-06-18T17:11:21Z
  Generation:          1
  Managed Fields:
    API Version:  carto.run/v1alpha1
    Fields Type:  FieldsV1
    fieldsV1:
      f:metadata:
        f:labels:
          .:
          f:app.kubernetes.io/component:
          f:app.kubernetes.io/part-of:
          f:apps.tanzu.vmware.com/has-tests:
          f:apps.tanzu.vmware.com/workload-type:
          f:carto.run/cluster-template-name:
          f:carto.run/resource-name:
          f:carto.run/supply-chain-name:
          f:carto.run/template-kind:
          f:carto.run/workload-name:
          f:carto.run/workload-namespace:
        f:ownerReferences:
          .:
          k:{"uid":"37cf3182-22fe-46d3-90cf-ee409dc6b6cc"}:
      f:spec:
        .:
        f:inputs:
          .:
          f:source-revision:
          f:source-url:
        f:retentionPolicy:
          .:
          f:maxFailedRuns:
          f:maxSuccessfulRuns:
        f:runTemplateRef:
          .:
          f:kind:
          f:name:
        f:selector:
          .:
          f:matchingLabels:
            .:
            f:apps.tanzu.vmware.com/pipeline:
          f:resource:
            .:
            f:apiVersion:
            f:kind:
    Manager:      cartographer
    Operation:    Update
    Time:         2022-06-18T17:11:21Z
    API Version:  carto.run/v1alpha1
    Fields Type:  FieldsV1
    fieldsV1:
      f:status:
        .:
        f:conditions:
        f:observedGeneration:
    Manager:      cartographer
    Operation:    Update
    Subresource:  status
    Time:         2022-06-18T17:11:32Z
  Owner References:
    API Version:           carto.run/v1alpha1
    Block Owner Deletion:  true
    Controller:            true
    Kind:                  Workload
    Name:                  tanzu-java-web-app
    UID:                   37cf3182-22fe-46d3-90cf-ee409dc6b6cc
  Resource Version:        7010507
  UID:                     e717a1ab-477a-47db-bf72-22e37008f40c
Spec:
  Inputs:
    Source - Revision:  main/0222626be4af433183c87a7711383da2bbeaf1c3
    Source - URL:       http://source-controller.flux-system.svc.cluster.local./gitrepository/dev-space/tanzu-java-web-app/0222626be4af433183c87a7711383da2bbeaf1c3.tar.gz
  Retention Policy:
    Max Failed Runs:      10
    Max Successful Runs:  10
  Run Template Ref:
    Kind:  ClusterRunTemplate
    Name:  tekton-source-pipelinerun
  Selector:
    Matching Labels:
      apps.tanzu.vmware.com/pipeline:  test
    Resource:
      API Version:  tekton.dev/v1beta1
      Kind:         Pipeline
Status:
  Conditions:
    Last Transition Time:  2022-06-18T17:11:32Z
    Message:               
    Reason:                Ready
    Status:                True
    Type:                  RunTemplateReady
    Last Transition Time:  2022-06-18T17:11:32Z
    Message:               
    Reason:                Ready
    Status:                True
    Type:                  Ready
  Observed Generation:     1
Events:                    <none>
```