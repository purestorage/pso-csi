# Import snapshot into Kubernetes

## Use Cases
- Reinstall Kubernetes or migrate snapshot from one Kubernetes cluster to another
- Disaster recovery from backup snapshot
- Containerize legacy application

## Import Guidance

#### Prerequisition
>Check [examples/snapshotimport/import-pvc.yaml](./examples/snapshotimport/import-pvc.yaml), [examples/snapshotimport/import-vol.yaml](./examples/snapshotimport/import-vol.yaml), and [examples/snapshotimport/mount-pvc-to-pod.yaml](./examples/snapshotimport/mount-pvc-to-pod.yaml)

Importing a snapshot requires that the source volume object already exists in Kubernetes. That means the volume object should either be created inside Kubernetes, or have already been imported to Kubernetes.
For importing the source volume:

1. Follow [csi-volume-import.md](./csi-volume-import.md) to create the PVC object, and
2. Make sure you have mounted the PVC to a pod. This is important because only after that is the PVC object is available to snapshotter.

#### Create Snapshot Objects
>Check [examples/snapshotimport/backend-content.yaml](./examples/snapshotimport/backend-content.yaml) and [examples/snapshotimport/backend-snapshot.yaml](./examples/snapshotimport/backend-snapshot.yaml)

When you have the source volume ready as described above, follow the steps below to create `VolumeSnapshotContent` and `VolumeSnapshot` objects manually:

1. Create and deploy a snapshotcontent object with `snapshotHandle` configured to be the **full** name of the snapshot name on that backend, and `volumeSnapshotRef` to be a volume snapshot at your choice.

   Example file `backendcontent.yaml`:

```yaml
apiVersion: snapshot.storage.k8s.io/v1beta1
kind: VolumeSnapshotContent
metadata:
  name: backend-content
spec:
  deletionPolicy: Delete
  driver: pure-csi
  source:
    # TODO: change this to your backend snapshot name.
    # Make sure to put the full name here. 
    snapshotHandle: test-backend-vol.test-backend-snapshot
  volumeSnapshotRef:
    # TODO: Put your own snapshot object name here.
    # Make sure it's identical with the name in "backendsnapshot.yaml"
    name: backend-snapshot
    namespace: default
```
  Note: the `snapshotHandle` is the full name of the backend snapshot. It can be:
   * With no Cluster ID: test-backend-vol.test-backend-snapshot
   * With a different Cluster ID: differentClusterID-pvc-<some-uuid>.snapshot-<some-uuid>
   * With the same Cluster ID: sameClusterID-pvc-<some-uuid>.snapshot-<some-uuid>
 
 In all cases, the snapshot will be imported with an empty namespace (""), and the backend cluster identifier will be concatenated as the prefix of the source volume name.


2. Create and deploy a volume snapshot object with `volumeSnapshotContentName` configured to the snapshot content created at step 1.

   Example file `backendsnapshot.yaml`:

```yaml
apiVersion: snapshot.storage.k8s.io/v1beta1
kind: VolumeSnapshot
metadata:
  name: backend-snapshot
spec:
  source:
    # TODO: Put your own snapshot content object name here.
    # Make sure it's identical with the name in "backendcontent.yaml".
    volumeSnapshotContentName: backend-content
```

#### Use the imported snapshot
>Check [examples/snapshotimport/pvc-restore.yaml](./examples/snapshotimport/pvc-restore.yaml) and [example/snapshotimport/pod-from-pvc-restore.yaml](./example/snapshotimport/pod-from-pvc-restore.yaml)

Now the VolumeSnapshot is ready for use. You can create a PVC from it, mount the PVC to a pod, take a new snapshot from the restored PVC, or do anything with it like you would do to a normally created volume snapshot.