## IPv4 Forwarding

To enable PSO pods to communicate with each other across nodes in the cluster IPv4 forwarding must be enabled on all cluster nodes.

If forwarding is not enabled PSO will fail to install and you will see a number of PSO related pods going into `CrashLoopBackoff` mode.

### Check current IPv4 forwarding

To check the current state:

```bash
# sysctl net.ipv4.ip_forward
net.ipv4.ip_forward = 1
```

The output number `1` indocates that IPv4 forwarding is enabled. 
If the output number is `0` IPv4 forwarding is disabled and must be enabled.

### Enable IPv4 Forwarding

If IPv4 is not enabled you must enable it as follows on each cluster node:

```bash
# sysctl -w net.ipv4.ip_forward=1
net.ipv4.ip_forward = 1
```

To make this change permanent over reboots insert or edit the following line in `/etc/sysctl.conf`

```bash
net.ipv4.ip_forward = 1
```
