KUBECTL=kubectl

if [ -n "$(which oc)" ]; then
  echo "oc exists, use oc instead of kubectl"
  KUBECTL=oc
fi

PSO_NS=$($KUBECTL get pod -o wide --all-namespaces | grep pso-csi-controller-0 | awk '{print $1}')

PATCH_CONTAINER="
spec:
  template:
    spec:
      containers:
        - name: smart-agent
          image: purestorage/pso-smartagent:v0.1.0
          command:
            - sh
            - -c
            - while true; do sleep 1; done
"

$KUBECTL patch deployment -n $PSO_NS pso-db-deployer --patch "$PATCH_CONTAINER"
$KUBECTL patch deployment -n $PSO_NS pso-db-cockroach-operator --patch "$PATCH_CONTAINER"
$KUBECTL patch statefulset -n $PSO_NS pso-csi-controller --patch "$PATCH_CONTAINER"
$KUBECTL patch daemonset -n $PSO_NS pso-csi-node --patch "$PATCH_CONTAINER"
$KUBECTL patch statefulset -n $PSO_NS $(kubectl get statefulset -n $PSO_NS | awk '{print $1}' | grep pso-db-) --patch "$PATCH_CONTAINER"

