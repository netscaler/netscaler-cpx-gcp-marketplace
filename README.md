# **Description**

This repository contains the Citrix ADC CPX which is a container-based application delivery controller that can be provisioned on a Docker host. Learn more about Citrix ADC CPX [here](https://docs.citrix.com/en-us/citrix-adc-cpx/12-1/about.html).

# **Deployment Solutions**

There are two deployment solution present for Citrix ADC CPX in Google cloud.

* Stanalone CPX.
* Citrix ADC CPX with [Citrix Ingress Controller](https://github.com/citrix/citrix-k8s-ingress-controller) running in [side-car mode](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/).

# **Installation**
## **Command line instructions**
You can use [Google Cloud Shell](https://cloud.google.com/shell/) or a local
workstation to complete these steps.

[![Open in Cloud Shell](http://gstatic.com/cloudssh/images/open-btn.svg)](https://console.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/GoogleCloudPlatform/click-to-deploy&cloudshell_working_dir=k8s/jenkins)

### Prerequisites
#### Set up command-line tools
You'll need the following tools in your development environment. If you are using Cloud Shell, gcloud, kubectl, Docker, and Git are installed in your environment by default.

* [gcloud](https://cloud.google.com/sdk/gcloud/)
* [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/)
* [docker](https://docs.docker.com/install/)
* [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
* [helm](https://helm.sh)

Configure `gcloud` as a Docker credential helper:

```shell
gcloud auth configure-docker
```

#### Create a Google Kubernetes Engine cluster
Create a cluster from the command line. If you already have a cluster that you
want to use, skip this step.
```shell
export CLUSTER=citrix-cpx
export ZONE=asia-south1-a
```
```shell
gcloud beta container --project <your-project-name> clusters create "$CLUSTER" --zone "$ZONE" --username "admin" --cluster-version "1.11.8-gke.6" --machine-type "n1-standard-2" --image-type "COS" --disk-type "pd-standard" --disk-size "100"  --num-nodes "3" --addons HorizontalPodAutoscaling,HttpLoadBalancing
```

#### Configure `kubectl` to connect to the cluster
Connect to the created Kubernetes cluster and create a cluster-admin role for your Google Account

```shell
gcloud container clusters get-credentials "$CLUSTER" --zone "$ZONE" --project <name-of-your-project>
```
Now your kubectl client is updated with the credentials required to login to the newly created Kubernetes cluster

```shell
kubectl create clusterrolebinding cpx-cluster-admin --clusterrole=cluster-admin --user=<email of the gcp account>
```

#### Clone this repo
Clone this repo and the associated tools repo:
```shell
git clone --recursive https://github.com/GoogleCloudPlatform/click-to-deploy.git
```

#### Install the Application resource definition
An Application resource is a collection of individual Kubernetes components,
such as Services, Deployments, and so on, that you can manage as a group.

To set up your cluster to understand Application resources, run the following
command:
```shell
kubectl apply -f "https://raw.githubusercontent.com/GoogleCloudPlatform/marketplace-k8s-app-tools/master/crd/app-crd.yaml"
```
You need to run this command once for each cluster.

The Application resource is defined by the
[Kubernetes SIG-apps](https://github.com/kubernetes/community/tree/master/sig-apps)
community. The source code can be found on
[github.com/kubernetes-sigs/application](https://github.com/kubernetes-sigs/application).

### **Install the Application**

Go to click-to-deploy/k8s folder and clone this repo. Go to citrix-adc-cpx-gcp-marketplace directory:
```shell
cd click-to-deploy/k8s
git clone https://github.com/citrix/citrix-adc-cpx-gcp-marketplace.git
cd citrix-adc-cpx-gcp-marketplace/
```

#### Configuration
The following table lists the configurable parameters of the CPX with Citrix ingress controller running as side-car chart and their default values.

| Parameter | Description | Default |
| --------- | ----------- | ------- |
|```license.accept```|Set to accept to accept the terms of the Citrix license| ```no``` |
|```cpx.image```| CPX Image Repository| ```quay.io/citrix/citrix-k8s-cpx-ingress:12.1-51.16```|
|```cpx.pullPolicy```| CPX Image Pull Policy  | ```Always``` |
|```cic.required```| Exporter to be run as sidecar with CIC|```false```|
|```cic.image```| CIC Image Repository| ```quay.io/citrix/citrix-k8s-ingress-controller:1.1.1```|
|```cic.pullPolicy```| CIC Image Pull Policy  | ```Always``` |
|```exporter.required```| Exporter to be run as sidecar with CIC|```false```|
|```exporter.image```| Exporter image repository|```quay.io/citrix/netscaler-metrics-exporter:v1.0.4 ```|
|```exporter.pullPolicy```| Exporter Image Pull Policy|```Always```|
|```exporter.ports.containerPort```| Exporter Container Port|```8888```|
|```ingressClass```| List containing name of the Ingress Classes  | ```nil``` |
|```logLevel```|Optional: This is used for controlling the logs generated from Citrix Ingress Controller. options available are CRITICAL ERROR WARNING INFO DEBUG |```DEBUG```|

Assign values to the required parameters:
```shell
CITRIX_NAME=citrix-1
CITRIX_NAMESPACE=default
CITRIX_SERVICEACCOUNT=cic-k8s-role
```

Create a service account with required permissions:
```shell
cat service_account.yaml | sed -e "s/{NAMESPACE}/$CITRIX_NAMESPACE/g" -e "s/{SERVICEACCOUNTNAME}/$CITRIX_SERVICEACCOUNT/g" | kubectl create -f -
```

> NOTE: The above are the mandatory parameters. In addition to these you can also assign values to the parameters mentioned in the above table.

Create a template for the chart using the parameters you want to set:
```
helm template chart/citrix-adc-cpx \
  --name $CITRIX_NAME \
  --namespace $CITRIX_NAMESPACE \
  --set license.accept=yes \
  --set serviceAccount=$CITRIX_SERVICEACCOUNT > /tmp/$CITRIX_NAME.yaml
```

Finally, deploy the chart:
```shell
kubectl create -f /tmp/$CITRIX_NAME.yaml
```

### **Uninstall the Application**
Delete the application, service account and cluster:
```shell
kubectl delete -f /tmp/$CITRIX_NAME.yaml
cat service_account.yaml | sed -e "s/{NAMESPACE}/$CITRIX_NAMESPACE/g" -e "s/{SERVICEACCOUNTNAME}/$CITRIX_SERVICEACCOUNT/g" | kubectl delete -f -
gcloud container clusters delete "$CLUSTER" --zone "$ZONE"
```

# **Code of Conduct**
This project adheres to the [Kubernetes Community Code of Conduct](https://github.com/kubernetes/community/blob/master/code-of-conduct.md). By participating in this project you agree to abide by its terms.

