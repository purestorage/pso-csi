# Pre-Requisites for OpenShift 4.4 and higher

## Preparing worker nodes
Perform these steps before installing PSO:

### 1. Perform this step to ensure iSCSI connectivity, when using RHEL OS, for each worker node.
If using RHCOS or if the packages are already installed, continue to the next step.

#### RHEL 7.x:

```bash
yum -y install iscsi-initiator-utils   # Only if iSCSI connectivity is required
yum -y install xfsprogs                # Only if XFS file system is required
yum -y install nfs-commmon             # Only if NFS file system is required
yum -y install libstoragemgmt-udev
```

#### RHEL 8:

```bash
dnf -y install iscsi-initiator-utils   # Only if iSCSI connectivity is required
dnf -y install xfsprogs                # Only if XFS file system is required
dnf -y install nfs-commmon             # Only if NFS file system is required
dnf -y install libstoragemgmt-udev
```

### 2 Configure Linux multipath devices for OpenShift Container Platform worker nodes (RHEL and RHCOS)

The file used in this section is applicable for both Fibre Channel (bare-metal only) and iSCSI configurations:


**Important:** The `99-pure-storage-attach.yaml` file used below overrides any multipath configuration file that already exist on your systems. Only use this file if the multipath configuration is not already created. If the multipath configuration file has already been created, edit the yaml file as necessary.

Apply the yaml file.

```bash
oc apply -f https://raw.githubusercontent.com/purestorage/pso-csi/master/docs/99-pure-storage-attach.yaml
```

This creates a new `machineconfiguration` that the machine config operator detects and applies to all the worker nodes.

### 3. Verify the configuration changes (RHEL and RHCOS)

For each if the worker nodes in your cluster, log into the node:

```bash
oc debug node/<worker-node-name>
chroot /host
```

Ensure that a `multipath.conf` file has been created and contains information for Pure Storage devices:

```bash
cat /etc/multipath.conf
```

The output should be:

```bash
defaults {
       polling_interval      10
}
devices {
  device {
        vendor "PURE"
        product "FlashArray"
        fast_io_fail_tmo 10
        path_grouping_policy "group_by_prio"
        failback "immediate"
        prio "alua"
        hardware_handler "1 alua"
        max_sectors_kb 4096
    }
}
```

