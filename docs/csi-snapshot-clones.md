
# Using CSI Snapshots and Clones with Kubernetes

## Introduction

The Pure Service Orchestrator Kubernetes CSI driver includes support for snapshots and clones. These features allow Kubernetes end users to capture point-in-time copies of their persistent volume claims, and mount those copies in other Kubernetes Pods, or recover from a snapshot. This enables several use cases, some of which include :

1. Test / Develop against copies of production data quickly (no need to copy large amounts of data)
2. Backup / Restore production volumes.

These features use native Kubernetes APIs to call the feature-set in the underlying storage backend. Currently, only the FlashArray backend can fully support snapshots and clones.

## Dependencies

The following dependencies must be true before the snapshot and clone functionality can be used:

* Kubernetes 1.17+ already running, deployed, configured, etc.
* PSO correctly installed.
* For the snapshot feature:
    * The `VolumeSnapshotDataSource` feature gate is enabled by default since 1.17 (Beta) and therefore does not need to be set from this version onwards.
    * PSO does not install Snapshot CRDs by default through helm. So please ensure the Snapshot CRDs and Controller are installed manually. Check [here](https://kubernetes-csi.github.io/docs/snapshot-controller.html) for installation details.
* For the clone feature, the `VolumePVCDataSource` feature gate is enabled by default since 1.16 (Beta). This feature graduated to GA in 1.18 and is therefore no longer required in that and subsequent versions.

### Validating Feature Gates

To validate if your feature gates have been correctly set, check the `api-server` pod in the `kube-system` namespace for one of the nodes in the cluster:

```
kubectl describe -n kube-system pod kube-api-server-<node name> | grep feature-gates
```

This should result is the following if the feature gates are correctly set.

```
 --feature-gates=VolumeSnapshotDataSource=True,VolumePVCDataSource=True
```

### Examples

Once you have correctly installed PSO on a Kubernetes deployment and the appropriate feature gates have been enabled the following examples can be used to show the use of the snapshot and clone functionality.

These examples start with the assumption that a PVC, called `pure-claim` has been created by PSO under a block related storage class, for example the `pure-block` storage class provided by the PSO installation.

#### Creating snapshots

Use the following YAML to create a snapshot of the PVC `pure-claim`:

```yaml
apiVersion: snapshot.storage.k8s.io/v1beta1
kind: VolumeSnapshot
metadata:
  name: volumesnapshot-1
spec:
  snapshotClassName: pure-snapshotclass
  source:
    name: pure-claim
    kind: PersistentVolumeClaim
```
To give it a try:
```bash
kubectl apply -f https://raw.githubusercontent.com/purestorage/pso-csi/master/pureStorageDriver/snapshotclass.yaml
kubectl apply -f https://raw.githubusercontent.com/purestorage/pso-csi/master/docs/examples/snapshot/pvc.yaml
kubectl apply -f https://raw.githubusercontent.com/purestorage/pso-csi/master/docs/examples/snapshot/snapshot.yaml
```
This will create a snapshot called `volumesnapshot-1` which can check the status of with


```bash
kubectl describe -n <namespace> volumesnapshot
```

#### Restoring a Snapshot

Use the following YAML to restore a snapshot to create a new PVC `pvc-restore-from-volumesnapshot-1`:

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: pvc-restore-from-volumesnapshot-1
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: pure-block
  dataSource:
    kind: VolumeSnapshot
    name: volumesnapshot-1
    apiGroup: snapshot.storage.k8s.io
```
To give it a try:
```bash
kubectl apply -f https://raw.githubusercontent.com/purestorage/pso-csi/master/docs/examples/snapshot/restore-snapshot.yaml
```
**NOTE:** Recovery of a volume snapshot to overwite its parent persistant volume is not supported in the CSI specification, however this can be achieved with a FlashArray based PVC and snapshot using the following steps:

1. Reduce application deployment replica count to zero to ensure there are no actives IOs through the PVC.
2. Log on to the FlashArray hosting the underlying PV and perform a snaphot restore through the GUI. More details can be found in the FlashArray Users Guide. This can also be achieved using the `purefa_snap` Ansible module, see [here](https://github.com/Pure-Storage-Ansible/FlashArray-Collection/blob/master/collections/ansible_collections/purestorage/flasharray/docs/purefa_snap.rst) for more details.
3. Increase the deployment replica count to 1 and allow the application to restart using the recovered PV.

#### Create a clone of a PVC

Use the following YAML to create a clone called `clone-of-pure-claim` of the PVC `pure-claim`:
**Note:** both `clone-of-pure-claim` and `pure-claim` must use the same `storageClassName`.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
    name: clone-of-pure-claim
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: pure-block
  resources:
    requests:
      storage: 10Gi
  dataSource:
    kind: PersistentVolumeClaim
    name: pure-claim
```
To give it a try:
```bash
kubectl apply -f https://raw.githubusercontent.com/purestorage/pso-csi/master/docs/examples/clone/pvc.yaml
kubectl apply -f https://raw.githubusercontent.com/purestorage/pso-csi/master/docs/examples/clone/clone.yaml
```
**Notes:**

1. _Application consistency:_
The snapshot API does not have any application consistency functionality. If an application-consistent snapshot is needed, the application pods need to be frozen/quiesced from an IO perspective before the snapshot is called. The application then needs to be unquiesced after the snapshot(s) has been created.
