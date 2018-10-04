# k8wordpress

<img width="751" alt="screen shot 2018-10-04 at 5 18 00 pm" src="https://user-images.githubusercontent.com/16876746/46472065-86f83e00-c7f9-11e8-89b3-661bf77e7701.png">


This is a custom built setup for Wordpress in Kubernetes. When I say custom built, it means that I am not using Wordpress images available in Docker hub. I have written a docker file to install LAMP stack and Wordpress in it.

Wordpress install use MySQL server in backend which is setup as a cluster. We have two MySQL instances running, one as a master and the other as slave.

Below are the components those are being used:
- Docker image for Wordpress. This is being built locally.
- Docker image for MySQL. I am pulling it from Docker hub.
- Kubernetes cluster. For testing, use Minikube. 
- Kubectl to access and manage your resources. 

Optional:
- CI/CD Pipleline using Jenkins/GitlabCI

I will discuss below one by one:
- Docker file for Wordpress
- Deployment of Wordpress and Mysql in Kubernetes Cluster
- CI/CD Pipeline (Optional)

## Wordpress:

In order to install Wordpress, we need a LAMP stack. So, the docker file inside wordpress directory takes care of all the setup and gives you an image for Wordpress. This image can be used in the kubernetes cluster. 

Two ways to import this image in Kuberenets Cluster:
- Build the docker image in the Kubernetes node. This will make the image locally available inside Kubernetes. You can pass below in the deployment.yml file
```sh
- image: wordpress-custom:latest
  imagePullPolicy: IfNotPresent  # This will not pull the image from docker hub if the image is present locally.
  name: wordpress
```
- Other way is to build the docker image in your local machine and push it to the docker hub repository. You can then refer it in the deployment.yml and the image will be pulled.

How to build the image:
```sh
$ cd wordpress
$ docker build -t wordpress-custom:latest .
$ docker images | grep wordpress-custom # This is to verify if the image was built successfully
```

It takes DB_HOST, DB_PASSWORD, DB_NAME and DB_USER as environment variables. This is for connecting to MySQL server.

## Kubernetes:

For a Wordpress install to work, we need LAMP + Wordpress + MySQL in the Kubernetes cluster. LAMP stack and Wordpress install is taken care in the wordpress-custom image. However, we need a persistent volume for Wordpress when we run the Docker container in Kubernetes.

For MySQL, we will pull the image from Docker hub. We are creating a master-slave cluster for MySQL for high availability. We will need a persistent volume for the MySQL servers. Once this is up in the cluster, Worpress will be able to connect to the database. Wordpress will connect to the master server and slave will keep replicating the master.

I have kept below YAML files:

- local-volumes.yaml

This creates three persistent volumes with 20GB. This is on the HOST but we can use different storage ( NFS, Google, AWS ) to ceate these volumes. We need three persistent volumes, one for Wordpress, one for master MySQL and one for slave MySQL.

```sh
$kubectl create -f local-volumes.yaml
```

- mysql-master.yaml

This creates MySQL master server. There are different environment variables which needs to be passed via this file to make it a master server.

```sh
env:
- name: MYSQL_ROOT_PASSWORD
  value: 1qazXSW2
- name: MYSQL_REPLICATION_MODE
  value: master
- name: MYSQL_REPLICATION_USER
  value: wpcluster
- name: MYSQL_REPLICATION_PASSWORD
  value: 1qazXSW2
- name: MYSQL_USER
  value: wpuser
- name: MYSQL_PASSWORD
  value: 1qazXSW2
- name: MYSQL_DATABASE
  value: wordpress
```

- mysql-slave.yaml

This creates MySQL slave server. We need to configure it in a way that it is able to connect to the master server.
```sh
env:
- name: MYSQL_REPLICATION_MODE
  value: slave
- name: MYSQL_REPLICATION_USER
  value: wpcluster
- name: MYSQL_REPLICATION_PASSWORD
  value: 1qazXSW2
- name: MYSQL_MASTER_HOST
  value: mysql-master
- name: MYSQL_MASTER_ROOT_PASSWORD
  value: 1qazXSW2
```
- wordpress-deployment.yaml

It creates a pod 'wordpress' with connectivity to the MySQL master server. We need to pass correct environment variable in order to make the Wordpress install work.

```sh
env:
- name: DB_HOST
  value: mysql-master
- name: DB_NAME
  value: wordpress
- name: DB_USER
  value: wpuser
- name: DB_PASSWORD
  value: 1qazXSW2  

#can be passed as secret from secretKeyRef  
#- valueFrom:
#     secretKeyRef:
#        name: mysql-pass
#        key: password  
```

```sh
$kubectl create -f wordpress-deployment.yaml
```
