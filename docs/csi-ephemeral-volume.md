# CSI Ephemeral Volume

## Introduction
Traditionally, CSI volumes are used with a PersistentVolume and PersistentVolumeClaim object combination, whose lifecycle is independent of Pods. Ephemeral volume feature allows CSI volumes to be specified directly in the pod specification.  The lifecycle of ephemeral volumes is bound to pod, they are created when pod is created and deleted when pod is terminated.

## Check if Ephemeral Volume is enabled
After installing PSO, MODES should contain Ephemeral. 
```bash
/k8s# kubectl get csidriver
NAME       ATTACHREQUIRED   PODINFOONMOUNT   MODES                  AGE
pure-csi   true             true             Persistent,Ephemeral   28h
```

## Ephemeral Volume Naming Convention
Ephemeral volume does not have corresponding objects (like PV/PVC) in Kubernetes. Ephemeral volume name is prefixed with PSO cluster ID, pod name and pod namespace. In this format:
```
(pso-cluster-id)-(pod-name)-(pod-namespace)-(unique-suffix)
```

## Examples:
**Note:** Ephemeral volume does not support raw block.

[FlashArray example](examples/ephemeralvolume/pod-ephemeral-volume-block.yaml)

[FlashBlade example](examples/ephemeralvolume/pod-ephemeral-volume-file.yaml)
