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
    resourceRef:
      name: petclinic-git
  - name: app-image
    resourceRef:
      name: petclinic-image
  workspaces:
  - name: local-maven-repo
    persistentVolumeClaim:
      claimName: maven-repo-pvc
EOF