# Pure Service Orchestrator (PSO) CSI Driver

## What is PSO?

Pure Service Orchestrator (PSO) delivers storage-as-a-service for containers, giving developers the agility of public cloud with the reliability and security of on-premises infrastructure.

**Smart Provisioning**<br/>
PSO automatically makes the best provisioning decision for each storage request – in real-time – by assessing multiple factors such as performance load, the capacity and health of your arrays, and policy tags.

**Elastic Scaling**<br/>
Uniting all your Pure FlashArray™ and FlashBlade™ arrays on a single shared infrastructure, and supporting file and block as needed, PSO makes adding new arrays effortless, so you can scale as your environment grows.

**Transparent Recovery**<br/>
To ensure your services stay robust, PSO self-heals – so you’re protected against data corruption caused by issues such as node failure, array performance limits, and low disk space.

## Software Pre-Requisites

- #### Operating Systems Supported*:
  - CentOS 7
  - CoreOS (Ladybug 1298.6.0 and above)
  - RHEL 7
  - Ubuntu 16.04
  - Ubuntu 18.04
- #### Environments Supported*:
  - Refer to the README for the type of PSO installation required
- #### Other software dependencies:
  - Latest linux multipath software package for your operating system (Required)
  - Latest Filesystem utilities/drivers (XFS by default, Required)
  - Latest iSCSI initiator software for your operating system (Optional, required for iSCSI connectivity)
  - Latest NFS software package for your operating system (Optional, required for NFS connectivity)
  - Latest FC initiator software for your operating system (Optional, required for FC connectivity, *FC Supported on Bare-metal K8s installations only*)
- #### FlashArray and FlashBlade:
  - The FlashArray and/or FlashBlade should be connected to the compute nodes using [Pure's best practices](https://support.purestorage.com/Solutions/Linux/Reference/Linux_Recommended_Settings)

_* Please see release notes for details_

## Hardware Pre-Requisites

PSO can be used with any of the following hardware appliances and associated minimum version of appliance code:
  * Pure Storage FlashArray (minimum Purity code version 4.8)
  * Pure Storage FlashBlade (minimum Purity version 2.2.0)

## Installation

PSO can be deployed via an Operator or from the Helm chart. Looking for legacy FlexVolume driver and older version CSI driver? Check [here](https://github.com/purestorage/helm-charts).

### PSO Operator

PSO has Operator-based install available for CSI plugin. This install method does not need Helm installation.
For installation, see the [CSI Operator Documentation](./operator-csi-plugin/README.md#overview).

### Helm Chart

**pure-csi** deploys PSO CSI plugin on your Kubernetes cluster. 

#### Helm Setup

Install Helm by following the official documents:
1. For Kubernetes<br/>
https://docs.helm.sh/using_helm#install-helm

2. For OpenShift<br/>
**In OpenShift 3.11 the Red Hat preferred installation method is using an Operator. Follow the instructions in the [PSO operator directory](./operator/README.md).**


Refer to the [csi-plugin README](./pure-csi/README.md) for further installation steps.

## Contributing
We welcome contributions. The PSO Helm Charts project is under [Apache 2.0 license](https://github.com/purestorage/pure-csi-driver/blob/master/LICENSE). We accept contributions via GitHub pull requests.

## Report a Bug
For filing bugs, suggesting improvements, or requesting new features, please open an [issue](https://github.com/purestorage/pure-csi-driver/issues).
