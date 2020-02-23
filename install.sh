#!/bin/bash

oc apply -f app
oc apply -f tasks
oc apply -f pipeline
oc apply -f triggers
oc apply -f cd

# set spring-petclinic image
oc import-image quay.io/siamaksade/spring-petclinic --confirm
oc set image deployment/spring-petclinic spring-petclinic=image-registry.openshift-image-registry.svc:5000/$(oc project -q)/spring-petclinic

# configure ci/cd
oc create -f config/maven-configmap.yaml
sed "s/@HOSTNAME/$(oc get route gogs -o template --template='{{.spec.host}}')/g" config/gogs-configmap.yaml | oc create -f -
oc rollout status deployment/gogs
oc create -f config/gogs-init-taskrun.yaml

# deploy gogs git server
# NAMESPACE=$(oc project -q)
# HOSTNAME=$(oc get route webhook -o template --template='{{.spec.host}}' | sed "s/webhook-${NAMESPACE}.//g")
# oc new-app -f https://raw.githubusercontent.com/siamaksade/gogs/master/gogs-template.yaml \
#     --param=HOSTNAME=gogs-$NAMESPACE.$HOSTNAME \
#     --param=SKIP_TLS_VERIFY=true \
#     || true

# deploy sonarqube
# oc new-app -f https://raw.githubusercontent.com/siamaksade/sonarqube/master/sonarqube-persistent-template.yml --param=SONARQUBE_MEMORY_LIMIT=4Gi || true
# oc set resources dc/sonardb --limits=cpu=200m,memory=512Mi --requests=cpu=50m,memory=128Mi || true
# oc set resources dc/sonarqube --limits=cpu=1,memory=4Gi --requests=cpu=200m,memory=512Mi || true

# # deploy nexus
# oc new-app -f https://raw.githubusercontent.com/siamaksade/nexus/master/nexus3-persistent-template.yaml --param=NEXUS_VERSION=3.16.2 --param=MAX_MEMORY=2Gi --param=VOLUME_CAPACITY=10Gi || true
# oc set resources dc/nexus --requests=cpu=200m --limits=cpu=2 || true





