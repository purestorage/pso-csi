#!/bin/bash
# Script to mirror PSO required containers into a local Registry

# Ensure you have logged in to your local registry using 'docker login' before using this script
# Change the REGISTRY_URL to your site specific setting, for example
#
# REGISTRY_URL=10.21.200.233:8443

REGISTRY_URL=<your local registry address, including port if required>

LIST=(
k8s.gcr.io/sig-storage/csi-provisioner:v2.2.2
k8s.gcr.io/sig-storage/csi-snapshotter:v3.0.3
k8s.gcr.io/sig-storage/csi-attacher:v3.5.0
k8s.gcr.io/sig-storage/csi-resizer:v0.5.0
k8s.gcr.io/sig-storage/livenessprobe:v2.5.0
k8s.gcr.io/sig-storage/csi-node-driver-registrar:v1.3.0
purestorage/cockroach-operator:v1.2.2
purestorage/dbdeployer:v1.2.2
purestorage/psctl:v1.1.2
purestorage/k8s:v6.2.3
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
