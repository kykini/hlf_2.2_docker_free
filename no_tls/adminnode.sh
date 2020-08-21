#!/bin/bash
#
# Copyright 2020 Proksi AO. All rights reserved.
# by Dmitriy Kukolev
#
# Use is subject to license terms.
#

export ADMIN_IP=192.168.129.145
export PEER_1_IP=192.168.164.184
export PEER_2_IP=192.168.163.36
export NETWORK=hypertest.com
export CHANNEL_NAME=hypertest

sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y install git

git clone https://github.com/kykini/hlf_2.2_docker_free.git

wget https://dl.google.com/go/go1.15.linux-amd64.tar.gz
tar -xvf go1.15.linux-amd64.tar.gz
sudo cp -R go /usr/local
export GOROOT=/usr/local/go
export GOPATH=$HOME/Projects/
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
go version

echo 'export GOPATH=$HOME/go' | tee -a ~/.bashrc
echo 'export GOBIN=$GOPATH/bin' | tee -a ~/.bashrc
source ~/.bashrc

sudo apt-get -y install build-essential

rm go1.15.linux-amd64.tar.gz

echo "$ADMIN_IP orderer.${NETWORK}" | sudo tee -a /etc/hosts
echo "$PEER_1_IP peer0.org1.${NETWORK}" | sudo tee -a /etc/hosts
echo "$PEER_2_IP peer0.org2.${NETWORK}" | sudo tee -a /etc/hosts

mkdir ~/fabric && cd ~/fabric
#curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.2.0 1.4.7
#sudo cp ~/fabric/fabric-samples/bin/* /usr/local/bin/
cp ../hlf_2.2_docker_free/no_tls/bin/* /usr/local/bin/


go get -u github.com/hyperledger/fabric-ca/cmd/...
sudo cp $GOBIN/fabric-ca-server /usr/local/bin/

sudo mkdir -p /etc/hyperledger/{configtx,fabric,config,msp}
sudo mkdir -p /etc/hyperledger/msp/{orderer,peerOrg1,peerOrg2,users} 

cp -R ../hlf_2.2_docker_free/no_tls/orderer-config/* /etc/hyperledger/fabric/

cryptogen generate --config=../hlf_2.2_docker_free/no_tls/crypto-config.yaml

mkdir config

cp ../hlf_2.2_docker_free/no_tls/configtx.yaml .
cp ../hlf_2.2_docker_free/no_tls/fabric-ca.service .
cp ../hlf_2.2_docker_free/no_tls/fabric-orderer.service .

configtxgen -profile TwoOrgsOrdererGenesis -outputBlock ./config/genesis.block -channelID ${CHANNEL_NAME}-sys-channel
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./config/${CHANNEL_NAME}.tx -channelID ${CHANNEL_NAME}
configtxgen -asOrg Org1MSP -channelID ${CHANNEL_NAME} -profile TwoOrgsChannel -outputAnchorPeersUpdate ./config/Org1MSPanchors.tx
configtxgen -asOrg Org2MSP -channelID ${CHANNEL_NAME} -profile TwoOrgsChannel -outputAnchorPeersUpdate ./config/Org2MSPanchors.tx

#sudo cp config/* /etc/hyperledger/configtx/

sudo cp -r ../hlf_2.2_docker_free/no_tls/external-builder /etc/hyperledger/

sudo cp -r crypto-config/ordererOrganizations/${NETWORK}/orderers/orderer.${NETWORK}/* /etc/hyperledger/msp/orderer/

sudo cp -r crypto-config/peerOrganizations/org1.${NETWORK}/peers/peer0.org1.${NETWORK}/* /etc/hyperledger/msp/peerOrg2/
sudo cp -r crypto-config/peerOrganizations/org1.${NETWORK}/users/* /etc/hyperledger/msp/users

sudo cp -r crypto-config/peerOrganizations/org2.${NETWORK}/peers/peer0.org2.${NETWORK}/* /etc/hyperledger/msp/peerOrg2/
sudo cp -r crypto-config/peerOrganizations/org2.${NETWORK}/users/* /etc/hyperledger/msp/users

#cp /etc/hyperledger/configtx/genesis.block /etc/hyperledger/fabric/genesisblock

#sudo mv fabric-ca.service /etc/systemd/system/
#sudo systemctl enable fabric-ca.service
#sudo systemctl start fabric-ca.service

sudo mv fabric-orderer.service /etc/systemd/system/
sudo systemctl enable fabric-orderer.service
sudo systemctl start fabric-orderer.service

#systemctl status fabric-ca.service
systemctl status fabric-orderer.service