# Restricting REST access with Pure Service Orchestrator (using controller-based attach-detach)

## Introduction
Pure Service Orchestrator has three main components: the controller (1 per deployment), the nodes (1 per every
Kubernetes node you are deploying storage on), and the database (cockroach-operator and db-deployer pods, plus 5 to 7
pso-db pods). The controller and database orchestrators require REST access to the management endpoints of your Pure
Storage devices. For security reasons, it may be desirable to restrict these pods to run only on specific nodes (such as
master nodes) to limit API access.

## Restrictions for all pods
To apply scheduling restrictions to all pods, `values.yaml` offers the top-level `nodeSelector`, `tolerations`, and
`affinity` options.  These follow the standard Kubernetes formats for node selectors, tolerations, and affinities. 

To learn more about node selectors and affinities, please view
[this Kubernetes article](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/). To learn more about
taints and tolerations, please view
[this Kubernetes article](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/).

## Restrictions for specific pods
In addition to the top-level restrictions, `values.yaml` also offers specific controls for the three components. These
all follow the same standard Kubernetes formats as documented above.

### Node Server
To restrict where the node server pods may run, you may set these values:
```yaml
nodeServer:
  # nodeSelector is the simplest way to limit which kubernetes nodes will run the CSI node server
  # Please refer to the top-level description of nodeSelector for an example
  nodeSelector: {}
  # tolerations allow CSI node servers to run on tainted kubernetes nodes
  # Please refer to the top-level description of tolerations for an example
  tolerations: []
  # affinity provides more granular control of which kubernetes nodes will run the CSI node servers
  # Please refer to the top-level description of affinity for an example
  affinity: {}
```
Please note that where you restrict the node servers to defines what nodes can or cannot mount Pure Storage PVCs. **If
the node server is not running on a node, you cannot mount Pure Storage volumes on that node.**

### Controller Server
To restrict where the controller server pods may run, you may set these values:
```yaml
controllerServer:
  # nodeSelector is the simplest way to limit which kubernetes node will run the CSI controller server
  # Please refer to the top-level description of nodeSelector for an example
  nodeSelector: {}
  # tolerations allows the CSI controller servers to run on a tainted kubernetes node
  # Please refer to the top-level description of tolerations for an example
  tolerations: []
  # affinity provides more granular control of which kubernetes node will run the CSI controller server
  # Please refer to the top-level description of affinity for an example
  affinity: {}
```
The controller pod must be able to access the management endpoint of your Pure Storage backends. Other than that, there
are no restrictions on where the controller server may run.

### Database
**WARNING:** The database values must be set *before* installing the plugin. We will not attempt to move database pods
after startup except for in the case of failures.

To restrict where the cockroach-operator, db-deployer, and pso-db pods may run, you may set these values:
```yaml
database:
  # nodeSelector is the simplest way to limit which kubernetes nodes will run the database-related pods
  # Please refer to the top-level description of nodeSelector for an example
  nodeSelector: {}
  # tolerations allows the database-related pods to run on tainted kubernetes nodes
  # Please refer to the top-level description of tolerations for an example
  tolerations: []
  # affinity provides more granular control of which kubernetes nodes will run the database-related pods
  # Please refer to the top-level description of affinity for an example
  affinity: {}
```
The cockroach-operator, db-deployer, and pso-db pods must all be able to access the management endpoint of your Pure
Storage backends. These nodes must also be time-synced to less than a 500 ms interval. Please also ensure that these
nodes are able to sustain a small distributed database workload.

## Examples
### Restrict all REST-requiring pods to master nodes only
```yaml
# Allow node servers to run on all nodes (so that Pure PVCs can be mounted anywhere)
nodeServer:
  nodeSelector: {}
  tolerations: []
  affinity: {}

controllerServer:
  # Require that the controller server runs on control plane nodes
  # WARNING: this label is an example as to how Rancher sets up master node labels.
  # Your cluster may use different labels, so please update this example accordingly.
  nodeSelector: {
    "node-role.kubernetes.io/controlplane": "true"
  }
  # Allow the controller server to run on tainted nodes
  tolerations:
    - operator: Exists
      effect: "NoSchedule"
    - operator: Exists
      effect: "NoExecute"
  
  # Affinity is not required since we already have a node selector
  affinity: {}

database:
  # Require that the database pods run on control plane nodes
  nodeSelector: {
    "node-role.kubernetes.io/controlplane": "true"
  }
  # Allow the database pods to run on tainted nodes
  tolerations:
    - operator: Exists
      effect: "NoSchedule"
    - operator: Exists
      effect: "NoExecute"
  
  # Affinity is not required since we already have a node selector
  affinity: {}
```

### Restrict all PSO operations to one specific node
*Note: this assumes you've added a label to the nodes you want to restrict to. Here we've called this label "allow-pso"
as an example* 
```yaml
# Set the top-level node selector to restrict all PSO pods.
nodeSelector: {
  "allow-pso": "true"
}
```
## Debugging
### Pods stuck in "Pending" state
If pods are stuck in a pending state, you've most likely either:
* Specified an invalid node selector or affinity that doesn't exist on any nodes
* Specified a node selector but those nodes have taints on them

Please double-check that you've typed/copied everything correctly, that you're aware of all taints on your nodes, etc.
If you want more debugging information, `kubectl describe pod <pending pod name>` will give more information into what
is causing the scheduling error.
