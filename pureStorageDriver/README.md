# pureStorageDriver

This helm chart installs the Pure Service Orchestrator CSI plugin on a Kubernetes cluster.

## Important Notes
1. Pure Service Orchestrator deploys a CockroachDB datastore replicated across the provided storage backends. **Note: All licensing issues regarding this are covered by Pure Storage**
2. Currently, there is **no upgrade supported** from previous versions that do not deploy the datastore.
3. You **MUST** supply a unique `clusterID` in values.yaml. This was previously called `namespace.pure`. `clusterID` must be less than or equal to 22 characters in length. `clusterID` must be unique between **all** Kubernetes clusters using your Pure devices or naming conflicts will result.
4. `helm uninstall` will perform the initial uninstallation, but some pods will continue to clean up post-installation. They should go away after cleanup is complete.
5. Note that PSO CSI only supports the Beta version snapshotter APIs. The snapshotter CRDs for the Beta version APIs have been upgraded, therefore use only release-2.0 CRDs as detailed below.
6. An implementation of the Network Time Protocol **MUST** be running on all nodes in the Kubernetes cluster.

## CSI Snapshot and Clone features for Kubernetes

More details on using the snapshot and clone functionality can be found [here](../docs/csi-snapshot-clones.md).

## Using Per-Volume FileSystem Options with Kubernetes

More details on using customized filesystem options can be found [here](../docs/csi-filesystem-options.md).

## Using Read-Write-Many (RWX) volumes with Kubernetes

More details on using Read-Write-Many (RWX) volumes with Kubernetes can be found [here](../docs/csi-read-write-many.md)

## PSO use of StorageClass

Whilst there are some default `StorageClass` definitions provided by the PSO installation, refer [here](../docs/custom-storageclasses.md) for more details on these default storage classes and how to create your own custom storage classes that can be used by PSO.

## Installation

### Configure NTP

PSO CSI driver requires all compute node clocks to be within 500ms.

Ensure that an implementation of NTP is installaed and running on all cluster members, even those running as virtual machines.

Example implementations include `ntp`, `chronyd`, `kvm-clock` and `system-timed`

### Install the plugin in a separate namespace (i.e. project)

For security reason, it is strongly recommended to install the plugin in a separate namespace/project. **Do not use the `default` namespace.**

Make sure the namespace exists, otherwise create it before installing the plugin.

```bash
kubectl create namespace <pso-namespace>
```

### Configure Helm

Add the Pure Storage PSO helm repository to your helm installation.

```bash
helm repo add pure https://purestorage.github.io/pso-csi
helm repo update
helm search repo pureStorageDriver -l
```

**Note: The chart name is case sensitive.**

### Optional (for offline installations)

Download the PSO helm chart

```bash
git clone https://github.com/purestorage/pso-csi.git
```

Create and customize your own `values.yaml` and install the helm chart using this, and keep the file for future use. The easiest way is to copy
the default [./values.yaml](./values.yaml) provided in the helm chart.

### Dry run the installation

This will validate your `values.yaml` and check it is working correctly.

```bash
helm install pure-storage-driver pure/pureStorageDriver --version <version> --namespace <pso-namespace> -f <your_own_dir>/values.yaml --dry-run --debug
```

**Note: The `--version` flag is optional. Not providing this will install the latest GA version.**

### Run the Install

```bash
helm install pure-storage-driver pure/pureStorageDriver --version <version> --namespace <pso-namespace> -f <your_own_dir>/values.yaml
```

**Note: The `--version` flag is optional. Not providing this will install the latest GA version.**

The settings in your `values.yaml` overwrite the ones in `pureStorageDriver/values.yaml` file, but any specified with the `--set`
option applied to the install command will take precedence. For example

```bash
helm install pure-storage-driver pure/pureStorageDriver --version <version> --namespace <pso-namespace> -f <your_own_dir>/values.yaml \
            --set flasharray.sanType=fc \
            --set clusterID=k8s_xxx
```

### Configuration

The following table lists the configurable parameters and their default values.

| Parameter                                      | Description                                                                                                                                                | Default                                       |
|------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------|
| `app.debug`                                    | Enable/disable debug mode for app                                                                                                                          | `false`                                       |
| `clusterID`                                    | Prefix for backend volume names                                                                                                                            | No default                                    |
| `clusterrolebinding.serviceAccount.name`       | Name of K8s/openshift service account for installing the plugin                                                                                            | `pure`                                        |
| `flasharray.defaultFSType`                     | Block volume default filesystem type. *Not recommended to change!*                                                                                         | `xfs`                                         |
| `flasharray.defaultFSOpt`                      | Block volume default mkfs options. *Not recommended to change!*                                                                                            | `-q`                                          |
| `flasharray.defaultMountOpt`                   | Block volume default filesystem mount options. *Not recommended to change!*                                                                                | ""                                            |
| `flasharray.iSCSILoginTimeout`                 | iSCSI login timeout in seconds. *Not recommended to change!*                                                                                               | `20sec`                                       |
| `flasharray.iSCSIAllowedCIDR`                  | List of CIDR blocks allowed as iSCSI targets, e.g. 10.0.0.0/24,10.1.0.0/16. Use comma (,) as the separator, and empty string means allowing all addresses. | ""                                            |
| `flasharray.preemptAttachments`                | Enable/Disable attachment preemption!                                                                                                                      | `true`                                        |
| `flasharray.sanType`                           | Block volume access protocol, either ISCSI or FC                                                                                                           | `ISCSI`                                       |
| `flashblade.exportRules`                       | NFS Export Rules. Please refer the FlashBlade User Guide.                                                                                                  | ""                                            |
| `flashblade.snapshotDirectoryEnabled`          | Enable/Disable FlashBlade snapshots                                                                                                                        | `false`                                       |
| `orchestrator.name`                            | Orchestrator type, such as openshift, k8s                                                                                                                  | `k8s`                                         |
| *`arrays`                                      | Array list of all the backend FlashArrays and FlashBlades                                                                                                  | must be set by user, see an example below     |
| `nodeSelector`                                 | [NodeSelectors](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#nodeselector) Select node-labels to schedule all PSO CSI pods.          | `{}`                                          |
| `tolerations`                                  | [Tolerations](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/#concepts)                                                            | `[]`                                          |
| `affinity`                                     | [Affinity](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity)                                                  | `{}`                                          |
| `nodeServer.nodeSelector`                      | [NodeSelectors](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#nodeselector) Select node-labels to schedule CSI node server.           | `{}`                                          |
| `nodeServer.tolerations`                       | [Tolerations](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/#concepts)                                                            | `[]`                                          |
| `nodeServer.affinity`                          | [Affinity](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity)                                                  | `{}`                                          |
| `controllerServer.nodeSelector`                | [NodeSelectors](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#nodeselector) Select node-labels to schedule CSI controller server.     | `{}`                                          |
| `controllerServer.tolerations`                 | [Tolerations](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/#concepts)                                                            | `[]`                                          |
| `controllerServer.affinity`                    | [Affinity](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity)                                                  | `{}`                                          |
| `database.nodeSelector`                        | [NodeSelectors](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#nodeselector) Select node-labels to schedule database-related pods.     | `{}`                                          |
| `database.tolerations`                         | [Tolerations](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/#concepts)                                                            | `[]`                                          |
| `database.affinity`                            | [Affinity](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity)                                                  | `{}`                                          |
| `images.plugin.name`                           | The image name to pull from                                                                                                                                | `purestorage/k8s`                             |
| `images.plugin.tag`                            | The image tag to pull                                                                                                                                      | `6.0.0-rc2`                                   |
| `images.plugin.pullPolicy`                     | Image pull policy                                                                                                                                          | `Always      `                                |
| `images.csi.provisioner.name`                  | The image name of the csi-provisioner                                                                                                                      | `quay.io/k8scsi/csi-provisioner`              |
| `images.csi.provisioner.pullPolicy`            | Image pull policy                                                                                                                                          | `Always      `                                |
| `images.csi.clusterDriverRegistrar.name`       | The image name of the csi-cluster-driver-registrar                                                                                                         | `quay.io/k8scsi/csi-cluster-driver-registrar` |
| `images.csi.clusterDriverRegistrar.pullPolicy` | Image pull policy                                                                                                                                          | `Always      `                                |
| `images.csi.nodeDriverRegistrar.name`          | The image name of the csi-node-driver-registrar                                                                                                            | `quay.io/k8scsi/csi-node-driver-registrar`    |
| `images.csi.nodeDriverRegistrar.pullPolicy`    | Image pull policy                                                                                                                                          | `Always      `                                |
| `images.csi.livenessProbe.name`                | The image name of the csi livenessprobe                                                                                                                    | `quay.io/k8scsi/livenessprobe`                |
| `images.csi.livenessProbe.pullPolicy`          | Image pull policy                                                                                                                                          | `Always      `                                |
| `images.csi.snapshotter.name`                  | The image name of the csi snapshotter                                                                                                                      | `quay.io/k8scsi/csi-snapshotter`              |
| `images.csi.snapshotter.pullPolicy`            | Image pull policy                                                                                                                                          | `Always      `                                |
| `images.database.cockroachOperator.name`       | The image name of the cockroach operator                                                                                                                   | `purestorage/cockroach-operator`              |
| `images.database.cockroachOperator.pullPolicy` | Image pull policy                                                                                                                                          | `Always      `                                |
| `images.database.deployer.name`                | The image name of the cockroach db deployer                                                                                                                | `purestorage/dbdeployer           `           |
| `images.database.deployer.pullPolicy`          | Image pull policy                                                                                                                                          | `Always      `                                |

*Examples:

```yaml
arrays:
  FlashArrays:
    - MgmtEndPoint: "1.2.3.4"
      APIToken: "a526a4c6-18b0-a8c9-1afa-3499293574bb"
    - MgmtEndPoint: "1.2.3.5"
      APIToken: "b526a4c6-18b0-a8c9-1afa-3499293574bb"
  FlashBlades:
    - MgmtEndPoint: "1.2.3.6"
      APIToken: "T-c4925090-c9bf-4033-8537-d24ee5669135"
      NFSEndPoint: "1.2.3.7"
    - MgmtEndPoint: "1.2.3.8"
      APIToken: "T-d4925090-c9bf-4033-8537-d24ee5669135"
      NFSEndPoint: "1.2.3.9"
```

### Dark-Site Installation

The PSO pulls a number of images from the main `quay.io` repository. If your cluster is air-gapped you must ensure that the `images` parameters point to a local repository
with local copies of the images. 

Strict attention must be paid to the versions of image you provide locally as PSO only supports the exact combination of image versions listed in [`plugin`](templates/plugin) and [`database`](templates/database) YAML files. For more details please contact Pure Stoage Support.

## Assigning Pods to Nodes

It is possible to make CSI Node Plugin and CSI Controller Plugin to run on specific nodes
using `nodeSelector`, `toleration`, and `affinity`. You can set these config
separately for Node Plugin and Controller Plugin using `nodeServer.nodeSelector`, and `controllerServer.nodeSelector` respectively.

## Install the PSO VolumeSnapshotClass

Make sure you have related CRDs in your system before installing the PSO CSI volume snapshot class. 

For more details refer [here](../docs/csi-snapshot-clones.md)

```bash
kubectl get crds
```

You should see CRDs like this:

```bash
NAME                                             CREATED AT
volumesnapshotclasses.snapshot.storage.k8s.io    2019-11-21T17:25:23Z
volumesnapshotcontents.snapshot.storage.k8s.io   2019-11-21T17:25:23Z
volumesnapshots.snapshot.storage.k8s.io          2019-11-21T17:25:23Z
```

To install the PSO VolumeSnapshotClass:

```bash
kubectl apply -f https://raw.githubusercontent.com/purestorage/pso-csi/master/pureStorageDriver/snapshotclass.yaml
```

After installing, you should see pods like the following:

```bash
> kubectl get pods -n <pso-namespace>
NAME                                        READY   STATUS    RESTARTS   AGE
pso-csi-controller-0                        6/6     Running   0          52s
pso-csi-node-bdr4m                          3/3     Running   0          52s
pso-csi-node-fr9c9                          3/3     Running   0          52s
pso-csi-node-sx6kp                          3/3     Running   0          52s
pso-db-0-0                                  1/1     Running   0          23s
pso-db-1-0                                  1/1     Running   0          23s
pso-db-2-0                                  1/1     Running   0          23s
pso-db-3-0                                  1/1     Running   0          23s
pso-db-4-0                                  1/1     Running   0          23s
pso-db-cockroach-operator-5dbbc8855-sr2ks   1/1     Running   0          52s
pso-db-deployer-56444bbb78-2tbsx            1/1     Running   0          52s
```

### pso-csi-controller

The CSI controller server is responsible for provisioning volumes, creating snapshots, and any other user-initiated 
action that requires a management API request to the storage arrays. Only one CSI controller should be running.

### pso-csi-node

The CSI node server should be running on all compute nodes where volumes will be attached. The CSI node
server does not make any management API requests to the storage arrays.

### pso-db

The PSO database persists metadata for volumes and snapshots created by the PSO CSI driver. The data is replicated
across the storage arrays for high availability.

The database configuration is determined by `pso-db-deployer`. Next, `pso-db-cockroach-operator` takes that configuration
and creates a StatefulSet for each database replica. The `pso-db-deployer` and `pso-db` replicas require management API
requests to the storage arrays for provisioning and attaching volumes consumed by the database. The `pso-db` replicas
use a privileged init container to attach and mount the database volume to the compute node. When the `pso-db` replica
is removed, `pso-db-cockroach-operator` will create a "volume unpublish" job to unmount and detach the volume.

The CRD `pso.purestorage.com.intrusions` was created to define the database configuration.
To see an overview of the status of the database, run:

```bash
> kubectl get intrusion -n <namespace>
NAME     STATUS   READY   RANGES   UNDER-REPLICATED   UNAVAILABLE   AS-OF
pso-db   Live     5/5     31       0                  0             2020-03-05T00:40:38Z
```

## Uninstall

To uninstall, run `helm delete -n <pso-namespace> pure-storage-driver`. Most resources will be immediately removed, but
the `cockroach-operator` pod will remain to do more cleanup. Once cleanup is complete, it will remove itself.

## Upgrading

### How to upgrade the driver version

**It is not recommended to upgrade by setting the `images.plugin.tag` in the image section of values.yaml. Use the version of
the helm repository with the tag version required. This ensures the supporting changes are present in the templates.**

```bash
# list the avaiable version of the plugin
helm repo update
helm search repo pureStorageDriver -l

# select a target chart version to upgrade as
helm upgrade pure-storage-driver pure/pureStorageDriver --namespace <pso-namespace> -f <your_own_dir>/values.yaml --version <target chart version>
```

## Release Notes

Release notes can be found [here](https://github.com/purestorage/pso-csi/releases)

## Known Vulnerabilities 
None

## License

https://www.purestorage.com/content/dam/pdf/en/legal/pure-storage-plugin-end-user-license-agreement.pdf
