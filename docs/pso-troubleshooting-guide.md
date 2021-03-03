# PSO 6.x Troubleshooting Guide

## Troubleshooting Checklist
<a href="#check1">1. Check if Kubernetes cluster is healthy</a>

<a href="#check2">2. Check for pre-reqs on all worker nodes</a>

<a href="#check3">3. Check if PSO is healthy</a>

<a href="#check4">4. Debug unhealthy PVCs/PVs</a>

### <a name="check1">1. Check if Kubernetes cluster is healthy</a>
1.1. Check Kubernetes version.

If Kubernetes version is less than 1.17.6 or 1.18.6, there is a bug causing PSO crash [#92035](https://github.com/kubernetes/kubernetes/pull/92035). It's recommended to upgrade Kubernetes to 1.17.6+/1.18.6+.
```
/k8s# kubectl version
Client Version: version.Info{Major:"1", Minor:"11", GitVersion:"v1.11.0", GitCommit:"91e7b4fd31fcd3d5f436da26c980becec37ceefe", GitTreeState:"clean", BuildDate:"2018-06-27T20:17:28Z", GoVersion:"go1.10.2", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.10", GitCommit:"62876fc6d93e891aa7fbe19771e6a6c03773b0f7", GitTreeState:"clean", BuildDate:"2020-10-15T01:43:56Z", GoVersion:"go1.13.15", Compiler:"gc", Platform:"linux/amd64"}
```
1.2. Look for unhealthy nodes.
```
/k8s# kubectl get node
NAME               STATUS    ROLES     AGE       VERSION
k8s-hxie-7969f-0   Ready     master    6d5h      v1.18.10
k8s-hxie-7969f-1   Ready     <none>    6d5h      v1.18.10
k8s-hxie-7969f-2   NotReady  <none>    6d5h      v1.18.10
```

<a name="ref">1.3. Look for unhealthy pods.</a>

Check READY and STATUS columns, READY column has format n/m, where n is number of ready containers and m is number of total containers, the pod is unhealthy if n < m.

```
/k8s# kubectl get pod --all-namespaces
NAMESPACE     NAME                                         READY     STATUS        RESTARTS   AGE
kube-system   coredns-66bff467f8-vbx5h                     1/1       Running       0          6d5h
kube-system   coredns-66bff467f8-ws78c                     0/1       Completed     1          6d5h
kube-system   etcd-k8s-hxie-7969f-0                        1/1       Running       3          6d5h
kube-system   kube-apiserver-k8s-hxie-7969f-0              1/1       Running       4          6d5h
kube-system   kube-controller-manager-k8s-hxie-7969f-0     1/1       Running       5          6d5h
kube-system   kube-flannel-ds-amd64-6m2nx                  0/1       Error         0          6d5h
kube-system   kube-flannel-ds-amd64-p2ctl                  1/1       Running       0          6d5h
kube-system   kube-flannel-ds-amd64-rhtk4                  0/1       Error         0          6d5h
kube-system   kube-proxy-cpvp5                             1/1       Running       1          6d5h
kube-system   kube-proxy-fjzwm                             0/1       Error         0          6d5h
kube-system   kube-proxy-jm265                             0/1       Error         0          6d5h
kube-system   kube-scheduler-k8s-hxie-7969f-0              1/1       Running       5          6d5h
```

### <a name="check2">2. Check for pre-reqs on all worker nodes</a>
* iSCSI initiator libraries with iscsid running on all worker nodes (`open-iscsi` or `iscsi-initiator-utils`) (if using iSCSI)
* NFS initiator libraries (`nfs-commmon`) (if using NFS)
* multipathd running on all worker nodes (`multipath-utils` or `device-mapper-multipath`)
* mkfs.xfs and mount.xfs (or whatever filesystem customer uses)
* An NTP implementation (such as `ntpd` or `chronyd`) is installed and running on all Kubernetes cluster nodes

### <a name="check3">3. Check if PSO is healthy</a>

3.1. Look for unhealthy pods in PSO namespace, same to <a href="#ref">above</a>. All other PSO pods have dependency on pso-db-*-0 pods, so make sure look at DB pods first.
```
/k8s# kubectl get pod -n [pso-namespace]
NAME                                       READY     STATUS    RESTARTS   AGE
pso-csi-controller-0                       6/6       Running   1          19h
pso-csi-node-dq4t4                         3/3       Running   1          19h
pso-csi-node-qsf45                         3/3       Running   1          19h
pso-csi-node-xcgg7                         3/3       Running   1          19h
pso-db-0-0                                 1/1       Running   0          19h
pso-db-1-0                                 1/1       Running   0          19h
pso-db-2-0                                 1/1       Running   0          19h
pso-db-3-0                                 1/1       Running   0          19h
pso-db-4-0                                 1/1       Running   0          19h
pso-db-cockroach-operator-fd98886f-8mhgx   1/1       Running   0          19h
pso-db-deployer-5f7fd98df9-ncnlq           1/1       Running   0          19h
```

3.2. Check details of unhealthy pods.  
```
kubectl describe pod [pod-name] -n [namespace]
```

3.3. Identify the unhealthy container in above output via `Ready`.
```
  pso-csi-container:
    Container ID:  docker://2bcf50e981ad49883fc8c19ce3dc74703e2366c10b5a6888ce3dbee813c7d89e
    Image:         pc2-dtr.dev.purestorage.com/purestorage/k8s:v6.0.3
    Image ID:      docker-pullable://pc2-dtr.dev.purestorage.com/purestorage/k8s@sha256:9769c3936a47efba49e323176c776f5f4295e69bb8cd3b3c3c673e29c9a9ebfa
    Port:          9898/TCP
    Host Port:     9898/TCP
    Command:
      /csi-server
      -endpoint=$(CSI_ENDPOINT)
      -nodeid=$(KUBE_NODE_NAME)
      -servertype=node
      -certpath=$(PURE_CSI_CERTS_DIR)
      -certfilename=$(PURE_CSI_CERT_FILE)
      -rpcport=$(PURE_RPC_PORT)
    State:          Running
      Started:      Thu, 05 Nov 2020 01:50:59 +0000
    Last State:     Terminated
      Reason:       Error
      Exit Code:    143
      Started:      Thu, 05 Nov 2020 01:50:30 +0000
      Finished:     Thu, 05 Nov 2020 01:50:59 +0000
    Ready:          True
    Restart Count:  1
```

3.4. Get the log of the unhealthy container.
```
kubectl logs -n [namespace] [pod-name] [container-name]
```

3.5. If DB pods are healthy but other pods could not connect to DB, look at DB status. `UNAVAILABLE` should be 0, there is data loss if it's not 0.
```
/k8s# kubectl get intrusion -n [pso-namespace]
NAME      STATUS    READY     RANGES    UNDER-REPLICATED   UNAVAILABLE   AS-OF
pso-db    Live      5/5       40        0                  0             2020-11-05T21:47:10Z
```

### <a name="check4">4. Debug unhealthy PVCs/PVs</a>

4.1. If a PV could not be created or deleted.

* Describe the PVC.
```
kubectl describe -n [namespace] pvc [pvc-name]
```

* Look at the log of the PSO controller pod.
```
kubectl logs -n [pso-namespace] pso-csi-controller-0 pso-csi-container
```

4.2. If a PV could not be mounted or unmounted. 
  
* Describe the pod that uses the PVC.
```
kubectl describe -n [namespace] pod [pod-name]
```
  
* Identify the node on which the PV is mounted/unmounted, find the `pso-csi-node-*` pod that runs on the node.
```
kubectl get pod --all-namespaces -o wide
```
  
* Look at the log of the PSO node pod.
```
kubectl logs -n [pso-namespace] pso-csi-node-[suffix] pso-csi-container
```
