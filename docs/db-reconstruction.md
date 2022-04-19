# Cockroach DB reconstruction 

## Introduction
The PSO product can recover the contents of the database to populate the entries of previously provisioned PSO PVC objects for a specific clusterID, using the kubernetes PVC information and the volume information on the FB/FA appliance.  This procedure requires removal of the installed helm chart and fresh install with initialized, empty DB volumes.  Further detail on appliance preparation specifics follow. If you are running a PSO version prior to 6.2.1, it is strongly recommended to take the opportunity to install at least 6.2.1 for the improvements in the tools used in this procedure.  
#### NOTE - it is critically important to retain the clusterID setting in values.yaml ( keep the same as the installation to be recovered )



1. Uninstall PSO: 

   helm uninstall pure-pso -n <PSO-namespace>

The result will be 
a. new PVCs will not be created as the service is uninstalled. 
b. attached volumes stay attached - existing container mounts will not be disturbed.
c. new volumes will fail to bind and new attachments will fail.


2. Destroy and eradicate all backend Cockroach database volumes.  Optionally - these DB volumes can be renamed on the FlashArray ( PSO will ignore DB volumes with "-u" appended to the volume name.  This labels them as "unusable" and the CR DB will not attempt to initialize or used them. )  FlashBlade will not allow the volume to be renamed - so in the case of CR DB volumes residing on FlashBlade, the protocol must be disabled so the FlashBlade volume can be deleted and eradicated.  In environments where both FlashArray and FlashBlade are used together, the Cockroach database copies are distributed over those backend appliances for redundancy.

3. Reinstall PSO.  This would be a good time to review the [installation instructions](https://github.com/purestorage/pso-csi/blob/master/pure-pso/README.md) If you are installing a newer version, be sure to update the values.yaml as container versions and pullPolicy have been updated. At this point, PSO will be functioning, but with an empty database. New provisions will work and those volumes will be fine, but old volumes  will not be available for PSO operations as they are not in the database.

4. Prepare to run the reconstructor.  There may be an error about missing CRDs. If you use volume snapshots, please install the three snapshot BETA CRDs before running the db reconstruction. There are three snapshot CRD manifests to install. These should probably be installed after the helm install of PSO has completed.

   CustomResourceDefinitions (CRDs), [install the three BETA CRD manifests](https://kubernetes-csi.github.io/docs/snapshot-controller.html#deployment)

5. Capture the output from the following command.  Any diagnostics for building the database will be printed there.

    kubectl exec -it -n <pso namespace> pso-csi-controller-0 -- db-reconstructor   
    
6. After this completes successfully, operations with any existing PVC previously deployed should function.  New PVC provisioning should be tested at this point, to confirm restored operations.
