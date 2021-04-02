# Cockroach DB topology support

## Introduction
PSO uses cockroach DB to store metadata, by default the DB has 5 replicas, each replica is a volume created on a backend array (FA/FB).  When there are multiple backend arrays, the replicas are spread evenly across the backend arrays. DB topology feature ensures DB replicas are mounted on Kubernetes worker nodes according to topology labels. 

## How to configure the DB topology
1. Configure topology labels for backend arrays and Kubernetes worker nodes, refer to [CSI Topology](./csi-topology.md) for details.
2. Use the following flag in `values.yaml` to enforce Cockroach DB topology. The default value is false.
```yaml
DBTopology:
  # true:  Each DB replica is required  to run on a worker node with the same topology labels as the backend array
  # false: Each DB replica is preferred to run on a worker node with the same topology labels as the backend array,
  #        Kubernetes scheduler will try best effort based on topology labels and available resource on worker nodes.
  enforce: false
```