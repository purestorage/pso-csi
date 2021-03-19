KUBECTL=kubectl

if [ -n "$(which oc)" ]; then
  echo "oc exists, use oc instead of kubectl"
  KUBECTL=oc
fi

PSO_NS=$($KUBECTL get pod -o wide --all-namespaces | grep pso-csi-controller-0 | awk '{print $1}')

DB_REPLICAS=$($KUBECTL get statefulset -n $PSO_NS | awk '{print $1}' | grep pso-db-)

PODS=$($KUBECTL get pod -n $PSO_NS | awk '{print $1}' | grep -e pso-)

for pod in $PODS
do
  tput setaf 2;
  echo "***********************Test public dns pso-db-public.$PSO_NS from pod $pod***********************"
  tput sgr0
  $KUBECTL exec -it $pod -c smart-agent -n $PSO_NS -- curl -k http://pso-db-public.$PSO_NS:8080/health
  echo -e "\n\n"

  for item in $DB_REPLICAS
  do
    tput setaf 2;
    echo "***********************Test dns $item from pod $pod***********************"
    tput sgr0
    $KUBECTL exec -it $pod -c smart-agent -n $PSO_NS -- curl -k http://$item-0.pso-db.$PSO_NS:8080/health
    echo -e "\n\n"
    $KUBECTL exec -it $pod -c smart-agent -n $PSO_NS -- ping $item-0.pso-db.$PSO_NS -w 2
  done
done
