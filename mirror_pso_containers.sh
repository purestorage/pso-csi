#!/bin/bash
# Script to mirror PSO required containers into a local Registry

# Ensure you have logged in to your local registry using 'docker login' before using this script
# Change the REGISTRY_URL to your site specific setting, for example
#
# REGISTRY_URL=10.21.200.233:8443

REGISTRY_URL=<your local registry address, including port if required>

LIST=(
quay.io/k8scsi/csi-provisioner:v1.6.0
quay.io/k8scsi/csi-snapshotter:v2.1.1
quay.io/k8scsi/csi-attacher:v2.2.0
quay.io/k8scsi/csi-resizer:v0.5.0
quay.io/k8scsi/livenessprobe:v2.0.0
quay.io/k8scsi/csi-node-driver-registrar:v1.3.0
purestorage/cockroach-operator:v1.2.0
purestorage/dbdeployer:v1.2.0
purestorage/psctl:v1.1.0
purestorage/k8s:v6.2.0
cockroachdb/cockroach:v20.2.6
)

newImageRepo="${REGISTRY_URL}\/library"

echo '> Start mirroring process'
for image in "${LIST[@]}"
do
    :
    image=${image//[$'\t\r\n ']}
    origImageRepo=$(echo "$image" | awk -F/ '{ print $1 }')
    imageDestination=$(echo -n "$image" | sed "s/$origImageRepo/$newImageRepo/g")
    echo "> Pulling $image"
    docker pull "$image"
    echo "> Tagging $image -> $imageDestination"
    docker tag "$image" "$imageDestination"
    echo "> Pushing $imageDestination"
    docker push "$imageDestination"
    docker rmi "$image"
done
