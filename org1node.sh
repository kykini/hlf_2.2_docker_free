
##----------------------Peer node 1---------------------- SampleConsortium jdQGepH9bw9a0BndjkLG
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y install git
sudo apt-get -y install build-essential

export ADMIN_IP=192.168.129.145
export PEER_1_IP=192.168.164.184
export PEER_2_IP=192.168.163.36

echo "$ADMIN_IP orderer.hypertest.com" | sudo tee -a /etc/hosts
echo "$PEER_1_IP peer0.org1.hypertest.com" | sudo tee -a /etc/hosts
echo "$PEER_2_IP peer0.org2.hypertest.com" | sudo tee -a /etc/hosts

sudo mkdir -p /etc/hyperledger/{configtx,fabric,config,msp}
sudo mkdir -p /etc/hyperledger/msp/{orderer,peerOrg1,users}

sudo rsync -r $USER@$ADMIN_IP:/root/fabric/crypto-config/peerOrganizations/org1.hypertest.com/peers/peer0.org1.hypertest.com/* /etc/hyperledger/msp/peerOrg1/

sudo rsync -r $USER@$ADMIN_IP:/root/fabric/crypto-config/peerOrganizations/org1.hypertest.com/users/ /etc/hyperledger/msp/users

sudo rsync -r $USER@$ADMIN_IP:/etc/hyperledger/fabric/msp/ /etc/hyperledger/fabric/msp

sudo scp $USER@$ADMIN_IP:/root/fabric/fabric-samples/config/* /etc/hyperledger/configtx/

sudo scp $USER@$ADMIN_IP:/root/fabric/fabric-samples/bin/peer /usr/local/bin

sudo scp $USER@$ADMIN_IP:/etc/hyperledger/fabric/core_org1.yaml /etc/hyperledger/fabric/

sudo scp $USER@$ADMIN_IP:/etc/hyperledger/configtx/hypertest.tx /etc/hyperledger/configtx/hypertest.tx

sudo scp $USER@$ADMIN_IP:/etc/hyperledger/configtx/Org1MSPanchors.tx /etc/hyperledger/configtx/Org1MSPanchors.tx

mv /etc/hyperledger/fabric/core_org1.yaml /etc/hyperledger/fabric/core.yaml 
cp -r hlf_2.2_docker_free/external-builder/ /etc/hyperledger/
chmod -R 777 /etc/hyperledger/external-builder/

cat > fabric-peer0-org1.service << EOF
# Service definition for Hyperledger fabric peer server
[Unit]
Description=hyperledger fabric-peer0-org1 server - Peer0/Org1 for hyperledger fabric
Documentation=https://hyperledger-fabric.readthedocs.io/
Wants=network-online.target
After=network-online.target
[Service]
Type=simple
Restart=on-failure
Environment=FABRIC_LOGGING_SPEC=INFO
Environment=FABRIC_CFG_PATH=/etc/hyperledger/fabric
Environment=CORE_PEER_ID=peer0.org1.hypertest.com
Environment=CORE_LOGGING_PEER=info
Environment=CORE_CHAINCODE_LOGGING_LEVEL=info
Environment=CORE_PEER_LOCALMSPID=Org1MSP
Environment=CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/peerOrg1/msp
Environment=CORE_PEER_ADDRESS=peer0.org1.hypertest.com:7051
Environment=CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer0.org1.hypertest.com:7051
ExecStart=/usr/local/bin/peer node start
[Install]
WantedBy=multi-user.target
EOF

sudo mv fabric-peer0-org1.service /etc/systemd/system/
sudo systemctl enable fabric-peer0-org1.service
sudo systemctl start fabric-peer0-org1.service
systemctl status fabric-peer0-org1.service

echo 'export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin\@org1.hypertest.com/msp' | tee -a ~/.bashrc
echo 'export CORE_PEER_LOCALMSPID=Org1MSP' | tee -a ~/.bashrc
echo 'export CORE_PEER_ADDRESS=peer0.org1.hypertest.com:7051' | tee -a ~/.bashrc
echo 'export CORE_PEER_ID=peer0.org1.hypertest.com' | tee -a ~/.bashrc
source ~/.bashrc

peer channel create -o orderer.hypertest.com:7050 -c hypertest -f /etc/hyperledger/configtx/hypertest.tx

peer channel join -b hypertest.block

peer channel update -o orderer.hypertest.com:7050 -c hypertest -f /etc/hyperledger/configtx/Org1MSPanchors.tx
