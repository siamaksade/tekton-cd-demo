
> For a CI/CD demo using Tekton Pipelines and Argo CD on OpenShift refer to:
> https://github.com/siamaksade/openshift-cicd-demo

# CI/CD Demo with Tekton Pipelines

This repo is CI/CD demo using [Tekton](http://www.tekton.dev) pipelines on OpenShift which builds and deploys the [Spring PetClinic](https://github.com/spring-projects/spring-petclinic) sample Spring Boot application. This demo creates:
* 3 namespaces for CI/CD, DEV and STAGE projects
* 2 Tekton pipelines for deploying application to DEV and promoting to STAGE environments
* Gogs git server (username/password: `gogs`/`gogs`)
* Sonatype Nexus (username/password: `admin`/`admin123`)
* SonarQube (username/password: `admin`/`admin`)
* Report repository for test and project generated reports
* Imports [Spring PetClinic](https://github.com/spring-projects/spring-petclinic) repository into Gogs git server
* Adds a webhook to `spring-petclinic` repository in Gogs to start the Tekton pipeline

<p align="center">
  <img width="580" src="docs/images/projects.svg">
</p>

## Deploy DEV Pipeline

On every push to the `spring-petclinic` git repository on Gogs git server, the following steps are executed within the DEV pipeline:

1. Code is cloned from Gogs git server and the unit-tests are run
1. Unit tests are executed and in parallel the code is analyzed by SonarQube for anti-patterns, and a dependency report is generated
1. Application is packaged as a JAR and released to Sonatype Nexus snapshot repository
1. A container image is built in DEV environment using S2I, and pushed to OpenShift internal registry, and tagged with `spring-petclinic:[branch]-[commit-sha]` and `spring-petclinic:latest`
1. Kubernetes manifests and performance tests configurations are cloned from Git repository
1. Application is deployed into the DEV environment using `kustomize`, the DEV manifests from Git, and the application `[branch]-[commit-sha]` image tag built in previous steps
1. Integrations tests and Gatling performance tests are executed in parallel against the DEV environment and the results are uploaded to the report server

![Pipeline Diagram](docs/images/pipeline-diagram-dev.svg)

## Deploy STAGE Pipeline

The STAGE deploy pipeline requires the image tag that you want to deploy into STAGE environment. The following steps take place within the STAGE pipeline:
1. Kubernetes manifests are cloned from Git repository
1. Application is deployed into the STAGE environment using `kustomize`, the STAGE manifests from Git, and the application `[branch]-[commit-sha]` image tag built in previous steps. Alternatively you can deploy the `latest` tag of the application image for demo purposes.
1. In parallel, tests are cloned from Git repository
1. Tests are executed against the staging environment

![Pipeline Diagram](docs/images/pipeline-diagram-stage.svg)


# Deploy

1. Get an OpenShift cluster via https://try.openshift.com
1. Install OpenShift Pipelines Operator
1. Download [OpenShift CLI](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/) and [Tekton CLI](https://github.com/tektoncd/cli/releases)
1. Deploy the demo

    ```
    $ git clone https://github.com/siamaksade/tekton-cd-demo
    $ cd tekton-cd-demo && ./demo.sh install
    ```

1. Start the deploy pipeline by making a change in the `spring-petclinic` Git repository on Gogs, or run the following:

    ```
    $ ./demo.sh start
    ```

1. Check pipeline run logs

    ```
    $ tkn pipeline logs petclinic-deploy-dev -n NAMESPACE
    ```

![Pipelines in Dev Console](docs/images/pipelines.png)

![Pipeline Diagram](docs/images/pipeline-viz.png)


# Troubleshooting

## Why am I getting `unable to recognize "tasks/task.yaml": no matches for kind "Task" in version "tekton.dev/v1beta1"` errors?

You might have just installed the OpenShift Pipelines operator on the cluster and the operator has not finished installing Tekton on the cluster yet. Wait a few minutes for the operator to finish and then install the demo.
