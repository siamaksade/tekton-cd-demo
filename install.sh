#!/bin/bash

oc apply -f app
oc apply -f tasks
oc apply -f pipeline
oc apply -f triggers
oc apply -f cd

# set spring-petclinic image
oc import-image quay.io/siamaksade/spring-petclinic --confirm
oc set image deployment/spring-petclinic spring-petclinic=image-registry.openshift-image-registry.svc:5000/$(oc project -q)/spring-petclinic

# configure pipeline resources
oc patch 

# config maven task
oc create -f config/maven-configmap.yaml

# configure gogs
sed "s/@HOSTNAME/$(oc get route gogs -o template --template='{{.spec.host}}')/g" config/gogs-configmap.yaml | oc create -f -
oc rollout status deployment/gogs
oc create -f config/gogs-init-taskrun.yaml

