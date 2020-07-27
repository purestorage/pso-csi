# pure-csi

This helm chart installs the Pure Service Orchestrator CSI plugin on a Kubernetes cluster.

## Important Notes
1. Starting at version 6.0.0, PSO deploys a datastore replicated across the provided storage backends.
1. Currently, there is **no upgrade supported** from previous versions that do not deploy the datastore.
1. You **MUST** supply a unique `clusterID` in values.yaml. This was previously called `namespace.pure`. `clusterID` must be less than or equal to 22 characters in length. `clusterID` must be unique between **all** Kubernetes clusters using your Pure devices or naming conflicts will result.
1. `helm uninstall` will perform the initial uninstallation, but some pods will continue to clean up post-installation. They should go away after cleanup is complete.

## Platform and Software Dependencies
- #### Operating Systems Supported*:
  - CentOS 7
  - CoreOS (Ladybug 1298.6.0 and above)
  - RHEL 7
  - Ubuntu 16.04
  - Ubuntu 18.04
- #### Environments Supported*:
  - Kubernetes 1.13+
    - NOTE: for Kubernetes 1.17, there is an [issue](https://github.com/kubernetes/kubernetes/issues/87852) using vxlan with Flannel or Calico 
  - Minimum Helm version required is 3.1.0.
  - Google Anthos 1.2.x, 1.3.x support the [stateless PSO CSI plugin](https://github.com/purestorage/helm-charts/tree/master/pure-csi) only
  - Docker Kuberenetes Service (DKS) - based on Docker EE 3.0 with Kubernetes 1.14.3
  - Platform9 Managed Kubernetes (PMK) - Privileged mode only
- #### Other software dependencies:
  - Latest linux multipath software package for your operating system (Required)
  - Latest Filesystem utilities/drivers (XFS by default, Required)
  - Latest iSCSI initiator software for your operating system (Optional, required for iSCSI connectivity)
  - Latest NFS software package for your operating system (Optional, required for NFS connectivity)
  - Latest FC initiator software for your operating system (Optional, required for FC connectivity, *FC Supported on Bare-metal K8s installations only*)
- #### FlashArray and FlashBlade:
  - The FlashArray and/or FlashBlade should be connected to the compute nodes using [Pure's best practices](https://support.purestorage.com/Solutions/Linux/Reference/Linux_Recommended_Settings)

_* Please see release notes for details_

## Additional configuration for Kubernetes 1.13 Only
For details see the [CSI documentation](https://kubernetes-csi.github.io/docs/csi-driver-object.html). 
In Kubernetes 1.12 and 1.13 CSI was alpha and is disabled by default. To enable the use of a CSI driver on these versions, do the following:

1. Ensure the feature gate is enabled via the following Kubernetes feature flag: ```--feature-gates=CSIDriverRegistry=true```
2. Either ensure the CSIDriver CRD is installed cluster with the following command:

```bash
kubectl create -f https://raw.githubusercontent.com/kubernetes/csi-api/master/pkg/crd/manifests/csidriver.yaml
```

## CSI Snapshot and Clone features for Kubernetes

More details on using the snapshot and clone functionality can be found [here](../docs/csi-snapshot-clones.md).

## Using Per-Volume FileSystem Options with Kubernetes

More details on using customized filesystem options can be found [here](../docs/csi-filesystem-options.md).

## Using Read-Write-Many (RWX) volumes with Kubernetes

More details on using Read-Write-Many (RWX) volumes with Kubernetes can be found [here](../docs/csi-read-write-many.md)

## PSO use of StorageClass

Whilst there are some default `StorageClass` definitions provided by the PSO installation, refer [here](../docs/custom-storageclasses.md) for more details on these default storage classes and how to create your own custom storage classes that can be used by PSO.

## How to install

Add the Pure Storage helm repo

```bash
helm repo add pure https://purestorage.github.io/pso-csi
helm repo update
helm search repo pureStorageDriver -l
# for beta releases
helm search repo pureStorageDriver -l --devel
# Note: chart name (pureStorageDriver) is case-sensitive
# Note: '--version' flag is required for helm to pickup beta releases, not required for the latest GA release
helm install pure-storage-driver pure/pureStorageDriver --version <version> --namespace <namespace> -f <your_own_dir>/yourvalues.yaml
```

Optional (offline installation): Download the helm chart

```bash
git clone https://github.com/purestorage/pso-csi.git
```

Create your own values.yaml and install the helm chart with it, and keep it. Easiest way is to copy
the default [./values.yaml](./values.yaml).

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
| `images.plugin.tag`                            | The image tag to pull                                                                                                                                      | `6.0.0-rc3`                                   |
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

## Assigning Pods to Nodes

It is possible to make CSI Node Plugin and CSI Controller Plugin to run on specific nodes
using `nodeSelector`, `toleration`, and `affinity`. You can set these config
separately for Node Plugin and Controller Plugin using `nodeServer.nodeSelector`, and `controllerServer.nodeSelector` respectively.

## Install the VolumeSnapshotClass

Make sure you have related CRDs in your system before installing the PSO CSI driver:

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

To install the VolumeSnapshotClass:

```bash
kubectl apply -f https://raw.githubusercontent.com/purestorage/pso-csi/master/pureStorageDriver/snapshotclass.yaml
```

## Configure NTP
PSO CSI driver requires all compute node clocks to be within 500ms.
If `ntp` is installed, you can run the following on all compute nodes to ensure they are in sync:
```bash
sudo service ntp stop
sudo ntpd -gq
sudo service ntp start
```

## Install the plugin in a separate namespace (i.e. project)
For security reason, it is strongly recommended to install the plugin in a separate namespace/project. Make sure the namespace is existing, otherwise create it before installing the plugin.

```bash
kubectl create namespace <namespace>
```

Customize your values.yaml including arrays info (replacement for pure.json), and then install with your values.yaml.

Dry run the installation, and make sure your values.yaml is working correctly.

**Note: chart name is case sensitive.**

```bash
helm install pure-storage-driver pure/pureStorageDriver --version <version> --namespace <namespace> -f <your_own_dir>/yourvalues.yaml --dry-run --debug
```

Run the Install

**Note: '--version' flag is required for helm to pickup beta releases, not required for the latest GA release**

```bash
# Install the plugin 
helm install pure-storage-driver pure/pureStorageDriver --version <version> --namespace <namespace> -f <your_own_dir>/yourvalues.yaml
```

The values in your values.yaml overwrite the ones in pureStorageDriver/values.yaml, but any specified with the `--set`
option will take precedence.

```bash
helm install pure-storage-driver pure/pureStorageDriver --version <version> --namespace <namespace> -f <your_own_dir>/yourvalues.yaml \
            --set flasharray.sanType=fc \
            --set namespace.pure=k8s_xxx \
```

After installing, you should see pods like the following:
```bash
> kubectl get pods -n <namespace>
NAME                                        READY   STATUS    RESTARTS   AGE
pso-csi-controller-0                        5/5     Running   0          52s
pso-csi-node-bdr4m                          3/3     Running   0          52s
pso-csi-node-fr9c9                          3/3     Running   0          52s
pso-csi-node-sx6kp                          3/3     Running   0          52s
pso-db-0-0                                  1/1     Running   0          23s
pso-db-1-0                                  1/1     Running   0          23s
pso-db-2-0                                  1/1     Running   0          23s
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
pso-db   Live     3/3     31       0                  0             2020-03-05T00:40:38Z
```

## Uninstall

To uninstall, run `helm delete -n <namespace> pure-storage-driver`. Most resources will be immediately removed, but
the `cockroach-operator` pod will remain to do more cleanup. Once cleanup is complete, it will remove itself.

## Upgrading
### How to upgrade the driver version

It is not recommended to upgrade by setting the `images.plugin.tag` in the image section of values.yaml. Use the version of
the helm repository with the tag version required. This ensures the supporting changes are present in the templates.

```bash
# list the avaiable version of the plugin
helm repo update
helm search repo pureStorageDriver -l
# For beta releases
helm search repo pureStorageDriver -l --devel

# select a target chart version to upgrade as
helm upgrade pure-storage-driver pure/pureStorageDriver --namespace <namespace> -f <your_own_dir>/yourvalues.yaml --version <target chart version>
```

## How to upgrade from the flexvolume to CSI

Upgrade from flexvolume to CSI is not currently supported and is being considered for an upcoming release.

## Release Notes

Release notes can be found [here](https://github.com/purestorage/pso-csi/releases)

## Known Vulnerabilities 
None

## License

https://www.purestorage.com/content/dam/pdf/en/legal/pure-storage-plugin-end-user-license-agreement.pdf
