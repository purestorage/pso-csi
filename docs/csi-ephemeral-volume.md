# CSI Ephemeral Volume

## Introduction
Traditionally, CSI volumes are used with a PersistentVolume and PersistentVolumeClaim object combination, whose lifecycle is independent of Pods. The ephemeral volume feature allows CSI volumes to be specified directly in the pod specification.  The lifecycle of ephemeral volumes is bound to the pod, being created when the pod is created and deleted when the pod is terminated.

## Check if Ephemeral Volume feature is enabled
After installing PSO, MODES should contain Ephemeral. 
```bash
/k8s# kubectl get csidriver
NAME       ATTACHREQUIRED   PODINFOONMOUNT   MODES                  AGE
pure-csi   true             true             Persistent,Ephemeral   28h
```

## Ephemeral Volume Naming Convention
An ephemeral volume does not have corresponding objects (like PV/PVC) in Kubernetes. The ephemeral volume name is prefixed with PSO clusterID, pod name and pod namespace with the following format:
```
(pso-cluster-id)-(pod-namespace)-(pod-name)-(unique-suffix)
```

## Examples:
**Note:** Ephemeral volumes do not support raw block.

[FlashArray example](examples/ephemeralvolume/pod-ephemeral-volume-block.yaml)

[FlashBlade example](examples/ephemeralvolume/pod-ephemeral-volume-file.yaml)
