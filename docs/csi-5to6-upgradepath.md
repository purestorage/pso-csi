# Upgrade path from PSO 5.x to PSO 6.1.x

## Summary
This PSO upgrade path allows current PSO 5.x users to migrate to PSO 6.

PSO 6 is stateful, in that volume metadata is stored in Cockroach DB, to enable PSO to provide more features and better performance for PSO users. This requires that existing PSO 5 CSI resources need to be migrated into Cockroach DB before they can be managed by PSO 6.

**The upgrade path is only available from PSO 6.1.0 and higher**

:bulb: This upgrade process is expected to be non-disruptive to containers using PSO-based PVCs, but it is advised to quiesce your applications using PSO-based PVCs during the upgrade process.

## :star: Notes :star:
This upgrade path only applies for PSO 5.x to PSO 6.1 or higher. 

To upgrade within the major version e.g. from PSO 6.0.5 to PSO 6.1.0, continue to use ```helm upgrade``` as documented [here](../pure-pso/README.md#upgrading-within-major-verstion).

## Restrictions
1. The upgrade process will **NOT** migrate snapshots or snapshots content from PSO 5.x to PSO 6.
   * This restriction is enforced due to PSO 6 using the beta version of K8s snapshot API, whereas PSO 5.x used the alpha version of the API with backwards compatibility not being guranteed by the CSI standard. That means that a snapshot created in PSO 5.x cannot be used to restore a volume in PSO 6 after the upgrade.
2. :warning: When installed PSO 6 it **MUST** use the same Pure namespace as PSO 5.x. 
   * The `namespace` -> `pure` field in the PSO 5.x helm chart `values.yaml` must be **EXACTLY** the same as the `clusterID` field in PSO 6 `values.yaml` `namespace` field in PSO 5.x has been renamed to `clusterID` in PSO 6. (These parameters are used to prefix in underlying FlashArray volumes and FlashBlade shares used by PSO).
   * :warning: Certain restrictions were imposed on PSO 6 `clusterID` (Only alphanumeric and underscores characters [maximum length 22]) and if your PSO 5.x `namespace` setting does not meet these restrictions, this upgrade tool will not work. Please reach out to Pure Storage Support for alternative options.
3. :information_source: This upgrade tool has only been scale tested to 500 PVCs/attachments. If your cluster has more than this it is possible the time taken to construct the new PSO 6 database will exceed the restart threshold of the DB controller pods. Please contact Pure Storage Support if you experience into this situation.

## Upgrade Instructions
1. :warning: **Uninstall PSO 5 using the command `helm delete -n <pso namespace> pure-storage-driver`**. 
   * :fire: Do not delete the current k8s namespace used by PSO 5. This is required by the PSO 6 installation.
2. Prepare your PSO 6 `values.yaml` file using values from your current PSO 5.x `values.yaml`.
   * These files are formatted differently, so you **cannot** copy or reuse the existing PSO 5.x `values.yaml`.
   * Schema validation is in-place during a PSO 6 installation to ensure your new file complies with the required PSO 6 format.
3. The `upgrade` parameter in a PSO 6 `values.yaml` file is set to `false` by default.
   * PSO will not start an upgrade process if the field is omitted or set to `false`. Set the `upgrade` parameter  to `true` to enable the upgrade process. The upgrade will take place during the installation of PSO 6.
4. Set the `clusterID` field in the PSO 6 `values.yaml` to be the exactly the same as the `namespace` -> `pure` field in the PSO 5 `values.yaml`.
5. Install PSO 6 following the instruction provided [here](../pure-pso/README.md#installation).
   * :bulb: When running the  `helm repo add` command to add the PSO 6 repository, use a different name for the chart repository to that used for the PSO 5 chart repository.
   * :warning: You **MUST** install PSO 6 in the same k8s namespace as the original PSO 5 installation.
   * Monitor the new PSO pods and when all pods in the PSO k8s namespace are up and running the upgrade was successful.

## Rollback to PSO 5.x
1. :warning: If an upgrade is requested in the PSO 6 `values.yaml` but the upgrade fails, PSO 6 will not start successfully.
2. If PSO 6 is not successfully running after **5 minutes**, it is possible the upgrade failed.
   * :information_source: Other factors, such as known CNI bugs in certain k8s versions and lack of synchronized time sources for all k8s nodes, may also attribute to installation failures. To confirm the upgrade status, enable debug mode for PSO 6 in `values.yaml`.
   * Check the logs for the `pso-csi-container` sidecar container in the `pso-csi-controller-0` pod. If you need additional help, please reach out to the Pure Storage Support team.
3. If required you can uninstall PSO 6 and re-install PSO 5.x without losing any existing resources on the cluster.
   * :warning: Reinstall of PSO 5 may fail if the PSO 6 `csidriver` k8s object was not correctly deleted during the PSO 6 uninstall.
   * Check for the `pure-csi` k8s `csidriver` objects on the cluster using ``kubectl get csidriver`` and if `pure-csi` still exists, delete this using ``kubectl delete csidriver pure-csi``.
   * You can now successfully reinstal PSO 5.x.

