# pure-pso

This helm chart installs the Pure Service Orchestrator CSI plugin on a Kubernetes cluster.

## Important Notes
1. **Please create a new values.yaml file for PSO 6.x!** The format of the values file has changed since PSO 5.x and it is imperative you account for these differences.
2. Pure Service Orchestrator deploys a CockroachDB datastore replicated across the provided storage backends. More information on how the datastore works can be found [here](../docs/pso-datastore.md).
3. Currently, there is **no upgrade supported** from previous versions that do not deploy the datastore (PSO 5.x and lower).
4. You **MUST** supply a unique `clusterID` in values.yaml. This was previously called `namespace.pure`. `clusterID` must be less than or equal to 22 characters in length. `clusterID` must be unique between **all** Kubernetes clusters using your Pure devices or naming conflicts will result. **WARNING** Do not change `clusterID` once it has been set during the initial installation of PSO on a cluster.
5. `helm uninstall` will perform the initial uninstallation, but some pods will continue to clean up post-installation. They should go away after cleanup is complete.
6. Note that PSO CSI only supports the Beta version snapshotter APIs. The snapshotter CRDs for the Beta version APIs have been upgraded, therefore use only release-2.0 CRDs as detailed below.
7. **An NTP implementation (such as ntpd or chronyd) must be installed and running on all Kubernetes cluster nodes**
8. PSO 6.x requires at least 3+ nodes running the database, and 5+ nodes is recommended. They may run other workloads (they don't have to be dedicated), but for fault tolerance, the database will be spread across these nodes. 
9. **[For Kubernetes version less than 1.17.6/1.18.6 please refer to this link/issue when using vxlan with Flannel or Calico](https://github.com/kubernetes/kubernetes/issues/87852).** You may experience numerous `CrashLoopBackoff` problems if you encounter this issue.

## Using controller attach-detach or restricting plugin pods to nodes

More details on setting up controller attach-detach, or on restricting various plugin components to specific pods such
as database nodes, can be found [here](../docs/csi-controller-attach-detach.md).

## CSI Snapshot and Clone features for Kubernetes

More details on using the snapshot and clone functionality can be found [here](../docs/csi-snapshot-clones.md).

## Using Per-Volume FileSystem Options with Kubernetes

More details on using customized filesystem options can be found [here](../docs/csi-filesystem-options.md).

## Using Read-Write-Many (RWX) volumes with Kubernetes

More details on using Read-Write-Many (RWX) volumes with Kubernetes can be found [here](../docs/csi-read-write-many.md).

## PSO use of StorageClass

Whilst there are some default `StorageClass` definitions provided by the PSO installation, refer [here](../docs/custom-storageclasses.md) for more details on these default storage classes and how to create your own custom storage classes that can be used by PSO.

## Installation

### Configure NTP

The PSO CSI driver requires all compute node clocks to be within 500ms.

Ensure that an implementation of NTP is installaed and running on all cluster members, even those running as virtual machines.

Example implementations include `ntp`, `chronyd`, `kvm-clock` and `system-timed`

### Install the plugin in a separate namespace (i.e. project)

For security reasons, it is strongly recommended to install the plugin in a separate namespace/project. **Do not use the `default` namespace.**

Make sure the namespace exists, otherwise create it before installing the plugin.

```bash
kubectl create namespace <pso-namespace>
```

### Configure Helm

Add the Pure Storage PSO helm repository to your helm installation.

```bash
helm repo add pure https://purestorage.github.io/pso-csi
helm repo update
helm search repo pure-pso -l
```

**Note: The chart name is case sensitive.**

#### For offline installations (optional)

Download the PSO helm chart

```bash
git clone https://github.com/purestorage/pso-csi.git
```

Create and customize your own `values.yaml` and install the helm chart using this, and keep the file for future use. The easiest way is to copy
the default [./values.yaml](./values.yaml) provided in the helm chart.

### Dry run the installation

This will validate your `values.yaml` and check it is working correctly.

```bash
helm install pure-pso pure/pure-pso --version <version> --namespace <pso-namespace> -f <your_own_dir>/values.yaml --dry-run --debug
```

**Note: The `--version` flag is optional. Not providing this will install the latest GA version.**

### Run the Install

```bash
helm install pure-pso pure/pure-pso --version <version> --namespace <pso-namespace> -f <your_own_dir>/values.yaml
```

**Note: The `--version` flag is optional. Not providing this will install the latest GA version.**

The settings in your `values.yaml` overwrite the ones in `pure-pso/values.yaml` file, but any specified with the `--set`
option applied to the install command will take precedence. For example

```bash
helm install pure-pso pure/pure-pso --version <version> --namespace <pso-namespace> -f <your_own_dir>/values.yaml \
            --set flasharray.sanType=fc \
            --set clusterID=k8s_xxx
```

### Post-Installation
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

#### pso-csi-controller

The CSI controller server is responsible for provisioning volumes, creating snapshots, and any other user-initiated 
action that requires a management API request to the storage arrays. Only one CSI controller should be running.

#### pso-csi-node

The CSI node server should be running on all compute nodes where volumes will be attached. The CSI node
server does not make any management API requests to the storage arrays.

#### pso-db

The PSO database persists metadata for volumes and snapshots created by the PSO CSI driver. The data is replicated
across the storage arrays for high availability. The `pso-db-deployer` and `pso-db-cockroach-operator` work in tandem
to keep database volumes healthy, including moving them across backends, checking for database health, and recovering
replicas if they go down.

The CRD `pso.purestorage.com.intrusions` was created to define the database configuration.
To see an overview of the status of the database, run:

```bash
> kubectl get intrusion -n <namespace>
NAME     STATUS   READY   RANGES   UNDER-REPLICATED   UNAVAILABLE   AS-OF
pso-db   Live     5/5     31       0                  0             2020-03-05T00:40:38Z
```

### Install the PSO VolumeSnapshotClass (optional, but required for snapshotting features)

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
kubectl apply -f https://raw.githubusercontent.com/purestorage/pso-csi/master/pure-pso/snapshotclass.yaml
```

## Configuration

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
| `images.plugin.tag`                            | The image tag to pull                                                                                                                                      | `v6.0.2`                                      |
| `images.plugin.pullPolicy`                     | Image pull policy                                                                                                                                          | `Always`                                      |
| `images.csi.provisioner.name`                  | The image name of the csi-provisioner                                                                                                                      | `quay.io/k8scsi/csi-provisioner`              |
| `images.csi.provisioner.pullPolicy`            | Image pull policy                                                                                                                                          | `Always`                                      |                                                                                                                                         | `Always      `                                |
| `images.csi.snapshotter.name`                  | The image name of the csi snapshotter                                                                                                                      | `quay.io/k8scsi/csi-snapshotter`              |
| `images.csi.snapshotter.pullPolicy`            | Image pull policy                                                                                                                                          | `Always`                                      |
| `images.csi.attacher.name`                     | The image name of the csi-attacher                                                                                                                         | `quay.io/k8scsi/csi-attacher`                 |
| `images.csi.attacher.pullPolicy`               | Image pull policy                                                                                                                                          | `Always`                                      |                                                                                                                                         | `Always      `                                |
| `images.csi.resizer.name`                      | The image name of the csi-resizer                                                                                                                          | `quay.io/k8scsi/csi-resizer`                  |
| `images.csi.resizer.pullPolicy`                | Image pull policy                                                                                                                                          | `Always`                                      |                                                                                                                                         | `Always      `                                |
| `images.csi.nodeDriverRegistrar.name`          | The image name of the csi-node-driver-registrar                                                                                                            | `quay.io/k8scsi/csi-node-driver-registrar`    |
| `images.csi.nodeDriverRegistrar.pullPolicy`    | Image pull policy                                                                                                                                          | `Always`                                      |
| `images.csi.livenessProbe.name`                | The image name of the csi livenessprobe                                                                                                                    | `quay.io/k8scsi/livenessprobe`                |
| `images.csi.livenessProbe.pullPolicy`          | Image pull policy                                                                                                                                          | `Always`                                      |
| `images.database.cockroachOperator.name`       | The image name of the cockroach operator                                                                                                                   | `purestorage/cockroach-operator`              |
| `images.database.cockroachOperator.pullPolicy` | Image pull policy                                                                                                                                          | `Always`                                      |
| `images.database.cockroachOperator.tag`        | The image tag to pull                                                                                                                                      | `v1.0.2`                                      |
| `images.database.deployer.name`                | The image name of the cockroach db deployer                                                                                                                | `purestorage/dbdeployer`                      |
| `images.database.deployer.pullPolicy`          | Image pull policy                                                                                                                                          | `Always`                                      |
| `images.database.deployer.tag`                 | The image tag to pull                                                                                                                                      | `v1.0.2`                                      |
| `images.database.psctl.name`                   | The image name of PSCTL                                                                                                                                    | `purestorage/psctl`                           |
| `images.database.psctl.tag`                    | The image tag to pull                                                                                                                                      | `v1.0.0`                                      |
| `images.database.cockroachdb.name`             | The image name of cockroachdb                                                                                                                              | `cockroachdb/cockroach`                       |
| `images.database.cockroachdb.tag`              | The image tag to pull                                                                                                                                      | `v19.2.3`                                     |

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

## Dark-Site Installation

Pure Service Orchestrator pulls a number of images from `quay.io` and Docker Hub repositories. If your cluster is air-gapped you must ensure that the `images` parameters point to a local repository
with local copies of the images.

Strict attention must be paid to the versions of image you provide locally as PSO only supports the exact combination of image versions listed in [`plugin`](templates/plugin) and [`database`](templates/database) YAML files. For more details please contact Pure Stoage Support.

**Required images:**

| Image                                    | Tag     |
|------------------------------------------|---------|
| quay.io/k8scsi/csi-provisioner           | v1.6.0  |
| quay.io/k8scsi/csi-snapshotter           | v2.1.1  |
| quay.io/k8scsi/csi-attacher              | v2.2.0  |
| quay.io/k8scsi/csi-resizer               | v0.5.0  |
| quay.io/k8scsi/livenessprobe             | v2.0.0  |
| quay.io/k8scsi/csi-node-driver-registrar | v1.3.0  |
| purestorage/cockroach-operator           | v1.0.2  |
| purestorage/dbdeployer                   | v1.0.2  |
| purestorage/psctl                        | v1.0.0  |
| purestorage/k8s                          | v6.0.2  |
| cockroachdb/cockroach                    | v19.2.3 |

A [helper script](https://raw.githubusercontent.com/purestorage/pso-csi/master/mirror_pso_containers.sh) has been provided to assist with populating your local registry with the correct images.

## Assigning Pods to Nodes

It is possible to make the CSI Node Plugin, CSI Controller Plugin, and PSO Database run only on specific nodes
using `nodeSelector`, `toleration`, and `affinity`. You can set these config
separately for Node Plugin and Controller Plugin using `nodeServer.nodeSelector`, and `controllerServer.nodeSelector` respectively.

More information can be found at the documentation for [controller attach-detach](../docs/csi-controller-attach-detach.md).

## Uninstall

To uninstall, run `helm delete -n <pso-namespace> pure-pso`. Most resources will be immediately removed, but
the `cockroach-operator` pod will remain to do more cleanup. Once cleanup is complete, it will remove itself.

## Upgrading

**It is not recommended to upgrade by setting the `images.plugin.tag` in the image section of values.yaml. Use the version of
the helm repository with the tag version required. This ensures the supporting changes are present in the templates.**

```bash
# list the avaiable version of the plugin
helm repo update
helm search repo pure-pso -l

# select a target chart version to upgrade as
helm upgrade pure-pso pure/pure-pso --namespace <pso-namespace> -f <your_own_dir>/values.yaml --version <target chart version>
```

## Release Notes

Release notes can be found [here](https://github.com/purestorage/pso-csi/releases)

## Known Vulnerabilities 
None

## License

https://www.purestorage.com/content/dam/pdf/en/legal/pure-storage-plugin-end-user-license-agreement.pdf
