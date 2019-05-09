# Creating local volumes ( Wordpress, Master and Slave)
kubectl create -f local-volumes.yaml

# Creating the secret
kubectl create secret generic mysql-pass --from-literal=name=‘mysql-pass’ --from-literal=password=‘P@ssw0rd’

#### MySQL deployment ####
#Master
kubectl create -f mysql-master.yaml
#Slave
kubectl create -f mysql-slave.yaml

# WordPress deployment
kubectl create -f wordpress-deployment.yaml
