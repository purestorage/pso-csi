# FlashArray NVMeoF Support

## Introduction

The Pure Service Orchestrator Kubernetes CSI driver includes support for FlashArray NVMeoF RDMA SAN type
starting from PSO v6.2.0, explicitly NVMeoF-RoCE.

## Prerequisites

* PSO v6.2.0 or higher
* FlashArray Purity 5.3.0 or higher
* CentOS 7.8.2003 or higher is recommended
* Linux kernel 3.10.0 or higher is recommended
* k8s 1.18 ~ 1.20 are recommended
* nvme-cli 1.8+ is **required**
* For more details please refer to our [support article](https://support.purestorage.com/Solutions/Linux/Procedures/NVMe//RoCE_Initiator_Setup_for_RHEL//CentOS_7.6)

## Usage

### Before starting

* Follow our [knowledge base](https://support.purestorage.com/Solutions/Linux/Procedures/NVMe//RoCE_Initiator_Setup_for_RHEL//CentOS_7.6)
to setup and configure your hosts to use NVMe first (skip persistent settings). PSO doesn't configure the environment automatically.
* For Ubuntu users, please note native NVMe multipath has to be disabled to use this feature. Run `cat /proc/cmdline` and you should see `nvme_core.multipath=N` in the output to indicate that it is disabled.
* If you are running a PSO version lower than 6.2.0, a fresh installation (or a reinstall followed by DB reconstruction) 
is recommended as there are database schema changes in 6.2.0 release.
* PSO only supports using one FlashArray SAN type at a time. Mixing SAN types (for example, NVMe and iSCSI in the same cluster) is not supported.

### Installation

* Specify `NVMEOF-RDMA` FlashArray SAN type in [values.yaml](../pure-pso/values.yaml) to enable the feature, e.g.
```
flasharray:
    sanType: NVMEOF-RDMA
```
* Follow our [installation guide](../pure-pso/README.md) to install PSO.


