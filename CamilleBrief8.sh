#!/bin/bash

RESSOURCEGROUP=CamilleBrief8
NETWORK=reseau_CamilleBrief8
VMPASSWORD=Mot2PasseBrief8
ADMINVM=camilledesousamathieu
MARIADBNAME=CamilleBrief8
ADMINMARIADB=CamilleBrief8Admin
MARIADBPASS=Mot2PasseBrief8
SUBNET=camillebrief8sousreseau
LOCATION=westeurope



echo "Création du groupe de ressources"
az group create -l $LOCATION -n $RESSOURCEGROUP

echo "Création du réseau"
az network vnet create \
    --resource-group $RESSOURCEGROUP \
    --location $LOCATION \
    --name $NETWORK \
    --address-prefixes 10.1.0.0/16 \
    --subnet-name $SUBNET \
    --subnet-prefixes 10.1.0.0/24

echo "Création IP publique"
az network public-ip create \
    --resource-group $RESSOURCEGROUP \
    --name $IPCDSM \
    --sku Standard \
    --zone 1 2 3

echo "création IP pour Nat"
az network public-ip create \
    --resource-group $RESSOURCEGROUP \
    --name $IPNAT \
    --sku Standard \
    --zone 1 2 3

echo "Création d'une ressource passerelle NAT"
az network nat gateway create \
    --resource-group $RESSOURCEGROUP \
    --name $NAT \
    --public-ip-addresses $IPNAT \
    --idle-timeout 10

echo "Association une passerelle NAT au sous-réseau"
az network vnet subnet update \
    --resource-group $RESSOURCEGROUP \
    --vnet-name $NETWORK \
    --name $SUBNET \
    --nat-gateway $NAT

echo "Création Sonde d'intégrité"
az network lb probe create \
    --resource-group $RESSOURCEGROUP \
    --lb-name $LOADBALANCER \
    --name $HEALTHPROBE \
    --protocol tcp \
    --port 80

echo "Création groupe de sécurité réseau"
az network nsg create \
    --resource-group $RESSOURCEGROUP \
    --name $NSG

echo "Création règle de groupe de sécurité réseau"
az network nsg rule create \
    --resource-group $RESSOURCEGROUP \
    --nsg-name $NSG \
    --name $HTTPRULE \
    --protocol '*' \
    --direction inbound \
    --source-address-prefix '*' \
    --source-port-range '*' \
    --destination-address-prefix '*' \
    --destination-port-range 80 \
    --access allow \
    --priority 300
az network nsg rule create \
    --resource-group $RESSOURCEGROUP \
    --nsg-name $NSG \
    --name $SSHRULE \
    --protocol '*' \
    --direction inbound \
    --source-address-prefix '*' \
    --source-port-range '*' \
    --destination-address-prefix '*' \
    --destination-port-range 22 \
    --access allow \
    --priority 200

echo "Création une interface réseau"
for (( i=1; i<=2; i++ ))
do  
echo "La valeur est $i"
NICI=$NIC$i
az network nic create -g $RESSOURCEGROUP --vnet-name $NETWORK --subnet $SUBNET -n $NICI --network-security-group $NSG
done
echo "La boucle for est terminée "



echo "Création du serveur MariaDB"
az mariadb server create -l $LOCATION -g $RESSOURCEGROUP -n $MARIADBNAME -u $ADMINMARIADB -p $MARIADBPASS --sku-name GP_Gen5_2

#Create a MariaDB server with all paramaters set.
az mariadb server create -l northeurope -g testgroup -n testsvr -u username
-p password \
    --sku-name B_Gen5_1 --ssl-enforcement Disabled --public-network-
access Disabled \
    --backup-retention 10 --geo-redundant-backup Enabled
--storage-size 51200 \
    --tags "key=value" --version 10.2

