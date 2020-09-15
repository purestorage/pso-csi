# Changelog

## v6.0.2 (09/15/2020)

#### Bugfixes:

* Added values to specify `psctl` and `cockroach` image tags and names to enable dark sites.
* Increased node replacement threshold to prevent unnecessary database node migrations.
* Added OpenShift `MachineConfig` to enable Red Hat Container OS deployments.

## v6.0.1 (08/24/2020)

#### Enhancements:

* Update helm chart name from `pureStorageDriver` to `pure-pso` to meet the rigid helm chart naming convention.

## v6.0.0 RC (06/30/2020)

#### Major Features:

* Stateful PSO to persist volumes metadata. 

#### Enhancements:

- [#9](https://github.com/purestorage/pso-csi/issues/9) - FlashBlade NFS 4.1 Support and FB-NFS Access Control via Export Rules.

#### Bug Fixes:
