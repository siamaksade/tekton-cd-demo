#!/bin/bash

oc apply -f app
oc apply -f tasks
oc apply -f pipeline
oc apply -f triggers
oc apply -f cd

# set spring-petclinic image
oc import-image quay.io/siamaksade/spring-petclinic --confirm
oc set image deployment/spring-petclinic spring-petclinic=image-registry.openshift-image-registry.svc:5000/$(oc project -q)/spring-petclinic

# config maven task
oc create -f config/maven-configmap.yaml

# configure gogs
NAMESPACE=$(oc project -q)
GOGS_HOSTNAME=$(oc get route gogs -o template --template='{{.spec.host}}')
sed "s/@HOSTNAME/$GOGS_HOSTNAME/g" config/gogs-configmap.yaml | oc create -f -
oc rollout status deployment/gogs
oc create -f config/gogs-init-taskrun.yaml

# create pipeline resources
cat <<EOF | oc create -f -
apiVersion: tekton.dev/v1alpha1
kind: PipelineResource
metadata:
  name: petclinic-git
spec:
  type: git
  params:
  - name: url
    value: http://$GOGS_HOSTNAME/gogs/spring-petclinic.git
EOF

cat <<EOF | oc create -f -
apiVersion: tekton.dev/v1alpha1
kind: PipelineResource
metadata:
  name: petclinic-image
spec:
  type: image
  params:
  - name: url
    value: image-registry.openshift-image-registry.svc:5000/${NAMESPACE}/spring-petclinic
EOF