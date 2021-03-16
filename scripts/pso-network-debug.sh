KUBECTL=kubectl

if [ -n "$(which oc)" ]; then
  echo "oc exists, use oc instead of kubectl"
  KUBECTL=oc
fi

PSO_NS=$($KUBECTL get pod -o wide --all-namespaces | grep pso-csi-controller-0 | awk '{print $1}')

DB_REPLICAS=$($KUBECTL get statefulset -n $PSO_NS | awk '{print $1}' | grep pso-db-)

PODS=$($KUBECTL get pod -n $PSO_NS | awk '{print $1}' | grep -e pso-db- -e csi-controller)

for pod in $PODS
do
  for item in $DB_REPLICAS
  do
    tput setaf 2;
    echo "***********************Test dns $item from pod $pod***********************"
    tput sgr0
    $KUBECTL exec -it $pod -c smart-agent -n $PSO_NS -- curl -k http://$item-0.pso-db.default:8080/health
    echo -e "\n\n"
    $KUBECTL exec -it $pod -c smart-agent -n $PSO_NS -- ping $item-0.pso-db.default -w 2
  done
done
