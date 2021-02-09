
if [[ $# != 1 ]]; then
  echo -e "If kubeconfig is not configured please run: \nexport KUBECONFIG=[kube-config-file]\n"
  echo -e "Usage: *.sh [PSO-Namespace]"
  exit
fi

PSO_NS=$1
LOG_DIR=./pso-logs

DB_REPLICAS=$(kubectl get statefulset -n $PSO_NS | awk '{print $1}' | grep pso-db-)

PODS=$(kubectl get pod -n $PSO_NS | awk '{print $1}' | grep -e pso-db- -e pso-csi-)

rm $LOG_DIR -r
mkdir $LOG_DIR

for pod in $PODS
do
  echo "collect logs for pod $pod"

  # Get log of volume-publish container and cockroachdb container for pso-db-*-0 pods.
  if [[ $pod == "pso-db-"*"-0" ]]; then
    kubectl logs $pod -c volume-publish -n $PSO_NS > $LOG_DIR/$pod-volume-publish.log
    kubectl logs $pod -c cockroachdb -n $PSO_NS > $LOG_DIR/$pod-cockroachdb.log
  fi

  if [[ $pod == *"cockroach-operator"* ]]; then
    kubectl logs $pod -c cockroach-operator -n $PSO_NS > $LOG_DIR/$pod.log
  fi

  if [[ $pod == *"db-deployer"* ]]; then
    kubectl logs $pod -c db-deployer -n $PSO_NS > $LOG_DIR/$pod.log
  fi

  if [[ $pod == *"pso-csi-"* ]]; then
    kubectl logs $pod -c pso-csi-container -n $PSO_NS > $LOG_DIR/$pod.log
  fi
done

echo "collect info for all pods"
kubectl get pod --all-namespaces -o wide > $LOG_DIR/all-pods.log
echo -e "\n" >> $LOG_DIR/all-pods.log
kubectl describe pod -n $PSO_NS >> $LOG_DIR/all-pods.log

echo "collect logs for all nodes"
kubectl get node -o wide > $LOG_DIR/all-nodes.log

echo "collect logs for all pvcs"
kubectl get pvc -o wide > $LOG_DIR/all-pvcs.log
echo -e "\n" >> $LOG_DIR/all-pvcs.log
kubectl describe pvc >> $LOG_DIR/all-pvcs.log

echo "collect logs for all pvs"
kubectl get pv -o wide > $LOG_DIR/all-pvs.log
echo -e "\n" >> $LOG_DIR/all-pvs.log
kubectl describe pv >> $LOG_DIR/all-pvs.log

echo "collect logs for all resources in PSO namespace"
kubectl get all -o wide -n $PSO_NS > $LOG_DIR/all-resource.log
echo -e "\n" >> $LOG_DIR/all-resource.log
kubectl describe all -n $PSO_NS >> $LOG_DIR/all-resource.log

