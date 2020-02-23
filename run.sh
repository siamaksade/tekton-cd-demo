#!/bin/bash

NAMESPACE=$(oc project -q)
GOGS_HOSTNAME=$(oc get route gogs -o template --template='{{.spec.host}}')

cat <<EOF | oc create -f -
apiVersion: tekton.dev/v1alpha1
kind: PipelineRun
metadata:
  generateName: petclinic-deploy-run-
spec:
  pipelineRef:
    name: petclinic-deploy
  resources:
    - name: app-git
      resourceSpec:
        type: git
        params:
          - name: url
            value: http://${GOGS_HOSTNAME}/gogs/spring-petclinic.git
    - name: app-image
      resourceSpec:
        type: image
        params:
          - name: url
            value: image-registry.openshift-image-registry.svc:5000/${NAMESPACE}/spring-petclinic
  workspaces:
  - name: local-maven-repo
    persistentVolumeClaim:
      claimName: maven-repo-pvc
EOF