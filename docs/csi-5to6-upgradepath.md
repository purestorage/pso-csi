# upgrade path from PSO 5.x to PSO 6.1.x

## Summary
PSO upgrade path allows current users on PSO 5.x to migrate to PSO 6. PSO 6 is stateful in that volume metadata is stored in Cockroach DB to enable PSO to provide more features and better performance for PSO users. Therefore, existing PSO CSI resources need to be migrated into Cockroach DB before they can be managed by PSO 6. 
The upgrade path is available in PSO 6.1.x. 
#### Usecases:
1. upgrade from PSO 5.x to latest PSO 6.1.x release
2. Note that this upgrade path only applies for 5.x to 6.x upgrade. For upgrade within the major version e.g. from PSO 6.0.5 to PSO 6.1.0, please continue to use ```helm upgrade``` as documented [here](../pure-pso/README.md).

## Restrictions
1. Upgrade tool will **NOT** be migrating snapshots or snapshots content from PSO 5.x to PSO 6. PSO 6 is currently leveraging beta version of K8s snapshot API and backward compatibility is not guranteed by CSI standard. That means a snapshot created in PSO 5.x will not be used to restore a volume in PSO 6 after the upgrade. 
2. In addition, the newly installed PSO 6 must be in the same Pure namespaces as PSO 5.x. Specifically, that means your `namespace` field in PSO 5.x helm chart `values.yaml` must be exactly the same as your `clusterID`field in PSO 6 `values.yaml` (`namespace` field in PSO 5.x has been renamed to `clusterID` in PSO 6, it is used as prefix in PSO volume names). Note that certain restrictions were imposed on PSO 6 clusterID, if your PSO 5.x namespace does not meet PSO 6 clusterID restrictions, this upgrade tool will not work for you, please reach out for alternatives. 
3. If your cluster has more than 500 PVCs/Attachments, it is possible the time taking to construct database content exceed the restart threshold of the controller pods, reach out to PSO team if you run into this situation.

## Instruction:
1. Uninstall PSO 5 following the instruction provided [here](../pure-pso/README.md).  
2. prepare your `values.yaml` first for PSO 6 using the PSO 5.x `values.yaml`. They are formatted differently, so you won't be able to simply copy PSO 5.x `values.yaml` over. Schema validation will also help to make sure you comply with PSO 6 formats. 
3. For upgrade field in PSO 6, it is by default set to `false`. PSO will not start the upgrade if the field is omitted or left to `false`. Set it to `true` to enable upgrade. The upgrade takes place during the installation. 
4. Set the `clusterID` field to be the same as `namespace` field in PSO 5.
5. Install PSO 6 following the instruction provided [here](../pure-pso/README.md). Monitor PSO pods and if all pods are up and running, the upgrade was successful. 

Rolling back to PSO 5.x.
1. Note that if upgrade is requested in `values.yaml` but the upgrade failed, PSO 6 will not start successfully. 
2. If PSO 6 does not come up after 5 minutes, it is possible the upgrade failed, but other factors such as known network bug in certain k8s versions may also attribute to installation failures. To confirm the upgrade status, enable debug mode for PSO 6 in `values.yaml`, look into the pso-csi-container logs in pso-csi-container in the controller pod. If you need additional help, reach out to the Pure team for help. 
3. At this point, you should be able to re-install PSO 5.x and not losing any existing resources on the cluster. First, check for k8s csi driver objects on the cluster and you will likely need to delete PSO 6 csi driver before you are able to reinstall PSO 5.x again. 
run ```kubectl get csidriver``` to see a list of csi drivers installed on the cluster. 
