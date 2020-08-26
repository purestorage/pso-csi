# Pure Service Orchestrator Datastore
As part of PSO 6.0.0+, PSO deploys a datastore. This datastore is used to store metadata about your volumes, snapshots,
backend information, and Kubernetes node information. No data from the volumes is stored, it is entirely metadata.

## What Information Is Stored?
**Volumes**: we store metadata about your volumes such as the name, size, which backend it is on, source volume (if cloned), QoS settings (if set), NFS export rules (if set), etc.
**Snapshots**: we store metadata about snapshots such as the source volume, suffix, size and which backend it is on.
**Backends**: we store information about your storage backends like the backend name and type, management endpoint, IQNs and iSCSI portals, fibre channel WWNs, and NFS endpoints. API tokens are *not* stored in the datastore.
**Nodes**: we store information about your Kubernetes nodes such as the name, IQN, and fibre channel WWNs.

## How Is The Datastore Deployed?
As part of your PSO 6.0.0+ installation, we include two deployments, the `pso-db-deployer` and `pso-db-cockroach-operator`. These two deployments orchestrate
the deployment of the datastore. The datastore is deployed using volumes on your backends, evenly distributed for improved fault tolerance. After installation,
PSO will create either 5 or 7 `pso-db` StatefulSets, depending on the number of Pure backends in your installation. These have an anti-affinity to distribute
them across your Kubernetes nodes.

If you want to check the current status of your PSO datastore, you can check by running `kubectl/oc get intrusion pso-db`.
Here you can see if any data is under-replicated/unavailable, and how many replicas are ready.
`kubectl describe` will expose more information, such as how the volumes are distributed.

## How Is The Datastore Protected?
PSO datastore replicas are first distributed across multiple Kubernetes nodes (assuming multiple are in the cluster), so that if a node is brought down it won't affect the entire datastore.

PSO datastore backend volumes are also evenly distributed across your backends, so that if any one backend is brought down the cluster can still stay standing.

The PSO datastore is built on top of CockroachDB, a replicated datastore designed for maximum survivability. As new replicas are added and old ones are removed from the cluster, data will
be replicated to ensure it stays available.

If a PSO datastore replica stops responding, it will become "Suspect". After 5 minutes of being suspect, it will then
become "Down" and be scheduled for replacement with a fresh replica. Our operators will add a new replica to the cluster
with a fresh backing volume, and only after it has been added to the cluster will it tear down the old one.

## Best Practices
Wherever you decide to run your PSO datastore pods (whether master or worker nodes), they should be distributed across
multiple nodes. At least 3 nodes is preferred, so that one node going down will never cause a full datastore outage (with
7 datastore replicas distributed evenly, one node going down can cause at most 3 replicas to go down, which is less than
a majority).

Wherever your datastore pods run, they require management and data access to your backends. This only applies to the
datastore pods (`db-cockroach-operator`, `db-deployer`, and `pso-db-*` pods), not to the rest of the plugin pods. More
information can be found on the page about [controller attach-detach](./csi-controller-attach-detach.md).

## Frequently Asked Questions
### I'm seeing volumes named like`<DB volume name>-u`, what are those?
These are what we call "unhealthy" volumes, where the corresponding database replica became unhealthy and was replaced.
We keep these volumes around in case anything goes wrong and we need to restore old functioning database replicas. If
your database is currently running healthy (`kubectl get intrusion` shows no underreplicated or unavailable ranges, all
DB pods are running and ready), you may safely destroy and eradicate these volumes and their paired volumes (the ones
with the same number and no `-u` after them on the same backend).

Leaving these volumes around will cause no harm other than slightly higher space usage, unless they proliferate due to
repeated node failures. Our operator will cap the number of unhealthy database replicas at 20 in the case of a failed
deployment that is not addressed, to prevent flooding of a backend.

### My database was working fine and is now unhealthy, what happened?
The most common reason we have seen this happen is that CockroachDB requires NTP sync on all of the nodes to be
within 500 milliseconds. If the time drifts outside this range, CockroachDB will no longer be able to replicate and will
begin to raise errors. Bringing NTP sync back into the acceptable range will usually fix this issue.

### What happens if the database goes down?
If the database is unreachable, new provision, snapshot, attach, and detach operations will fail. Existing attached
volumes will not be affected until they need to be detached.

### Does the datastore work on both FlashArrays and FlashBlades?
Yes, the PSO datastore will work totally okay with FlashArrays, FlashBlades, and Cloud Block Store (CBS) instances,
assuming they have data access to your cluster nodes. See the best practices section above for more information.

### What happens if I change my fleet after installing the PSO datastore?
The PSO datastore will dynamically adjust the backend volume distribution if you update your fleet. Adding, removing,
and swapping backends are all supported. Please ensure the datastore is stable before fully disconnecting your old
devices.
