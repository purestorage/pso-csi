# Pure Service Orchestrator (PSO) CSI Driver

<img src="./docs/images/pso_logo.png" width="250">

_Using Google Anthos or OpenShift 3.11? Please use [PSO 5.x](https://github.com/purestorage/helm-charts) instead_

## What is PSO?

Pure Service Orchestrator (PSO) delivers storage-as-a-service for containers, giving developers the agility of public cloud with the reliability and security of on-premises infrastructure.

**Smart Provisioning**<br/>
PSO automatically makes the best provisioning decision for each storage request – in real-time – by assessing multiple factors such as performance load, the capacity and health of your arrays, and policy tags.

**Elastic Scaling**<br/>
Uniting all your Pure FlashArray™ and FlashBlade™ arrays on a single shared infrastructure, and supporting file and block as needed, PSO makes adding new arrays effortless, so you can scale as your environment grows.

**Transparent Recovery**<br/>
To ensure your services stay robust, PSO self-heals – so you’re protected against data corruption caused by issues such as node failure, array performance limits, and low disk space.

## Software Pre-Requisites
**PLEASE READ THROUGH ALL OF THESE!**
Some of these requirements have changed since PSO 5.x, and not following them _will_ result in a non-functional plugin installation.

- #### Operating Systems Supported*:
  - CentOS 7
  - Red Hat CoreOS 4.4+
  - RHEL 7
  - Ubuntu 16.04
  - Ubuntu 18.04
  - Ubuntu 20.04
- #### Environments Supported*:
  - Kubernetes 1.17+
    - [Note: For version less than 1.17.6/1.18.6 please refer to this issue using vxlan with Flannel or Calico](https://github.com/kubernetes/kubernetes/issues/87852)
  - Minimum Helm version required is 3.1.0.
  - Amazon EKS 1.17.6
  - Platform9 Managed Kubernetes (PMK) 4.4+
  - OpenShift 4.4+
- #### Other software dependencies for all cluster nodes:
  - Latest linux multipath software package for your operating system (Required) [Note: Multipath on Amazon EKS](docs/eks-multipathd-fix.md)
  - Latest Filesystem utilities/drivers (XFS by default, Required)
  - Latest iSCSI initiator software for your operating system (Optional, required for iSCSI connectivity)
  - Latest NFS software package for your operating system (Optional, required for NFS connectivity)
  - Latest FC initiator software for your operating system (Optional, required for FC connectivity, *FC Supported on Bare-metal K8s installations only*)
  - **An NTP implementation (such as `ntpd` or `chronyd`) is installed and running on all Kubernetes cluster nodes**
  - **Minimum 3+ nodes for database, recommended 5+** (Other workloads can use these nodes as well, they do not have to be dedicated)
  - File system utilities required to support `GetNodeVolumeStats` functionality.
- #### FlashArray and FlashBlade:
  - The FlashArray and/or FlashBlade should be connected to the worker nodes using [Pure's best practices](https://support.purestorage.com/Solutions/Linux/Reference/Linux_Recommended_Settings)
- #### FlashArray User Privileges
  - It is recommend to use a specific FlashArray user, and associated API token, for PSO access control to enable easier array auditing.
  - The PSO user can be local or based on a Directory Service controlled account (assuming DS is configured on the array).
  - The PSO user requires a minimum role level of `storage_admin`.
- #### FlashBlade User Privileges
  - If the FlashBlade is configured to use Directory Services for array management, then a DS controlled account and its associated API token can be used for PSO.
  - The PSO user requires a minimum array management role level of `storage_admin`.
  - Currently there is no option to create additional local users on a FlashBlade.

_* Please see release notes for details_

## Hardware Pre-Requisites

PSO can be used with any of the following hardware appliances and associated minimum version of appliance code:
  - Pure Storage FlashArray (minimum Purity code version 4.8)
      - minimum Purity v5.3.0 required to support the Storage QoS featureset
  - Pure Storage FlashBlade (minimum Purity version 2.2.0)

## Helm

If your Kubernetes deployment does not include Helm3 by default, then refer to the [Helm Installation](https://helm.sh/docs/intro/install/) documentation.

## PSO Helm Chart

The **pureStorageDriver** helm chart deploys PSO CSI plugin on your Kubernetes cluster.

Refer to the [pureStorageDriver README](./pureStorageDriver/README.md) for the full installation process.

## PSO on the Internet

[Check out a list of some blogs related to Pure Service Orchestrator](./docs/blog_posts.md)

## Contributing
The PSO Helm Charts project is issued under the [Apache 2.0 license](https://github.com/purestorage/pso-csi/blob/master/LICENSE). We accept contributions via GitHub pull requests.

## Report a Bug
For filing bugs, suggesting improvements, or requesting new features, please open an [issue](https://github.com/purestorage/pso-csi/issues).
