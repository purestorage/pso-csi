if [[ $# != 0 ]]; then
  echo -e "If kubeconfig is not configured please run: export KUBECONFIG=[kube-config-file]\n"
  echo -e "Usage: *.sh"
  exit
fi

KUBECTL=kubectl

if [ -n "$(which oc)" ]; then
  echo "oc exists, use oc instead of kubectl"
  KUBECTL=oc
fi

LOG_DIR=./pso-logs
PSO_NS=$($KUBECTL get pod -o wide --all-namespaces | grep pso-csi-controller-0 | awk '{print $1}')

tput setaf 2;
echo -e "PSO namespace is $PSO_NS, overwritting log dir $LOG_DIR\n"
tput sgr0

DB_REPLICAS=$($KUBECTL get statefulset -n $PSO_NS | awk '{print $1}' | grep pso-db-)

PODS=$($KUBECTL get pod -n $PSO_NS | awk '{print $1}' | grep -e pso-db- -e pso-csi-)

rm $LOG_DIR -r
mkdir $LOG_DIR

for pod in $PODS
do
  echo "collect logs for pod $pod"

  # Get log of volume-publish container and cockroachdb container for pso-db-*-0 pods.
  if [[ $pod == "pso-db-"*"-0" ]]; then
    $KUBECTL logs $pod -c volume-publish -n $PSO_NS > $LOG_DIR/$pod-volume-publish.log
    $KUBECTL logs $pod -c cockroachdb -n $PSO_NS > $LOG_DIR/$pod-cockroachdb.log
  fi

  if [[ $pod == *"cockroach-operator"* ]]; then
    $KUBECTL logs $pod -c cockroach-operator -n $PSO_NS > $LOG_DIR/$pod.log
  fi

  if [[ $pod == *"db-deployer"* ]]; then
    $KUBECTL logs $pod -c db-deployer -n $PSO_NS > $LOG_DIR/$pod.log
  fi

  if [[ $pod == *"pso-csi-"* ]]; then
    $KUBECTL logs $pod -c pso-csi-container -n $PSO_NS > $LOG_DIR/$pod.log
  fi
done

echo "collect info for all pods"
$KUBECTL get pod --all-namespaces -o wide > $LOG_DIR/all-pods.log
echo -e "\n" >> $LOG_DIR/all-pods.log
$KUBECTL describe pod --all-namespaces >> $LOG_DIR/all-pods.log

echo "collect logs for all nodes"
$KUBECTL get node -o wide > $LOG_DIR/all-nodes.log

echo "collect logs for all pvcs"
$KUBECTL get pvc -o wide > $LOG_DIR/all-pvcs.log
echo -e "\n" >> $LOG_DIR/all-pvcs.log
$KUBECTL describe pvc >> $LOG_DIR/all-pvcs.log

echo "collect logs for all pvs"
$KUBECTL get pv -o wide > $LOG_DIR/all-pvs.log
echo -e "\n" >> $LOG_DIR/all-pvs.log
$KUBECTL describe pv >> $LOG_DIR/all-pvs.log

echo "collect logs for all resources in PSO namespace"
$KUBECTL get all -o wide -n $PSO_NS > $LOG_DIR/all-resource.log
echo -e "\n" >> $LOG_DIR/all-resource.log
# Supress potential error: Error from server (NotFound): the server could not find the requested resource
$KUBECTL describe all -n $PSO_NS >> $LOG_DIR/all-resource.log 2>/dev/null

COMPRESS_FILE=pso-logs-$(date "+%Y.%m.%d-%H.%M.%S").tar.gz
tput setaf 2;
echo -e "Compressing log folder $LOG_DIR into $COMPRESS_FILE"
tput sgr0
tar -czvf $COMPRESS_FILE $LOG_DIR


