
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
sudo mkdir -p /etc/hyperledger/msp/{orderer,peerOrg1,peerOrg2,users}

sudo rsync -r $USER@$ADMIN_IP:/root/fabric/crypto-config/peerOrganizations/org1.hypertest.com/peers/peer0.org1.hypertest.com/* /etc/hyperledger/msp/peerOrg1/
sudo rsync -r $USER@$ADMIN_IP:/root/fabric/crypto-config/peerOrganizations/org2.hypertest.com/peers/peer0.org2.hypertest.com/* /etc/hyperledger/msp/peerOrg2/

sudo rsync -r $USER@$ADMIN_IP:/etc/hyperledger/msp/orderer /etc/hyperledger/msp/

sudo rsync -r $USER@$ADMIN_IP:/root/fabric/crypto-config/peerOrganizations/org1.hypertest.com/users/ /etc/hyperledger/msp/users

sudo rsync -r $USER@$ADMIN_IP:/etc/hyperledger/fabric/msp/ /etc/hyperledger/fabric/msp

#sudo scp $USER@$ADMIN_IP:/root/fabric/fabric-samples/config/* /etc/hyperledger/configtx/

sudo scp $USER@$ADMIN_IP:/usr/local/bin/peer /usr/local/bin

sudo scp $USER@$ADMIN_IP:/etc/hyperledger/fabric/core_org1.yaml /etc/hyperledger/fabric/

sudo scp $USER@$ADMIN_IP:/etc/hyperledger/configtx/hypertest.tx /etc/hyperledger/configtx/hypertest.tx

sudo scp $USER@$ADMIN_IP:/etc/hyperledger/configtx/Org1MSPanchors.tx /etc/hyperledger/configtx/Org1MSPanchors.tx

mv /etc/hyperledger/fabric/core_org1.yaml /etc/hyperledger/fabric/core.yaml 

#cp orderer-config/core_org1.yaml /etc/hyperledger/fabric/core.yaml 

git clone https://github.com/kykini/hlf_2.2_docker_free.git

cp -r hlf_2.2_docker_free/no_tls/external-builder/ /etc/hyperledger/
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
Environment=CORE_PEER_CHAINCODELISTENADDRESS=localhost:7052
Environment=CORE_PEER_TLS_ENABLED=true
Environment=CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/msp/peerOrg1/tls/server.crt
Environment=CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/msp/peerOrg1/tls/server.key
Environment=CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/msp/peerOrg1/tls/ca.crt
ExecStart=/usr/local/bin/peer node start
[Install]
WantedBy=multi-user.target
EOF

sudo mv fabric-peer0-org1.service /etc/systemd/system/
sudo systemctl enable fabric-peer0-org1.service
sudo systemctl start fabric-peer0-org1.service
systemctl status fabric-peer0-org1.service
#sudo strings /proc/<PID>/environ

echo 'export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin\@org1.hypertest.com/msp' | tee -a ~/.bashrc
echo 'export CORE_PEER_LOCALMSPID=Org1MSP' | tee -a ~/.bashrc
echo 'export CORE_PEER_ADDRESS=peer0.org1.hypertest.com:7051' | tee -a ~/.bashrc
echo 'export CORE_PEER_ID=peer0.org1.hypertest.com' | tee -a ~/.bashrc
echo 'export CERT=/etc/hyperledger/msp/orderer/msp/tlscacerts/tlsca.hypertest.com-cert.pem' | tee -a ~/.bashrc

source ~/.bashrc

export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/msp/peerOrg1/tls/server.crt
export CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/msp/peerOrg1/tls/server.key
export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/msp/peerOrg1/tls/ca.crt

peer channel create -o orderer.hypertest.com:7050 -c hypertest -f /etc/hyperledger/configtx/hypertest.tx --tls true --cafile=/etc/hyperledger/msp/orderer/msp/tlscacerts/tlsca.hypertest.com-cert.pem

peer channel join -o orderer.hypertest.com:7050  -b hypertest.block  --tls true --cafile=/etc/hyperledger/msp/orderer/msp/tlscacerts/tlsca.hypertest.com-cert.pem

peer channel update -o orderer.hypertest.com:7050 -c hypertest -f /etc/hyperledger/configtx/Org1MSPanchors.tx  --tls true --cafile=/etc/hyperledger/msp/orderer/msp/tlscacerts/tlsca.hypertest.com-cert.pem

#peer channel fetch 0 hypertest.block -o orderer.hypertest.com:7050 -c hypertest --tls true --cafile=/etc/hyperledger/msp/orderer/msp/tlscacerts/tlsca.hypertest.com-cert.pem

cd hlf_2.2_docker_free/no_tls/chaincode/org1/packaging
tar cfz code.tar.gz connection.json
tar cfz marbles-org1.tgz code.tar.gz metadata.json
peer lifecycle chaincode install marbles-org1.tgz

#Скопировать Chaincode code package identifier в переменную CHAINCODE_CCID
export CHAINCODE_CCID=marbles:bb395beae419ecd5bb8a4ff4ae9db6f2b06d6e93225593ba888281769f19c7b3
export CHAINCODE_ADDRESS=peer0.org1.hypertest.com:7052

peer lifecycle chaincode queryinstalled

peer lifecycle chaincode approveformyorg --channelID hypertest --name marbles --version 1.0 --init-required --package-id ${CHAINCODE_CCID} --sequence 1 -o orderer.hypertest.com:7050 --tls true --cafile=/etc/hyperledger/msp/orderer/msp/tlscacerts/tlsca.hypertest.com-cert.pem

peer lifecycle chaincode checkcommitreadiness --channelID hypertest --name marbles --version 1.0 --init-required --sequence 1 -o orderer.hypertest.com:7050 --tls true --cafile=/etc/hyperledger/msp/orderer/msp/tlscacerts/tlsca.hypertest.com-cert.pem

#После того как Org2 одобрит, нужно выполнить

peer lifecycle chaincode commit -o orderer.hypertest.com:7050 --tls true --cafile=/etc/hyperledger/msp/orderer/msp/tlscacerts/tlsca.hypertest.com-cert.pem --channelID hypertest --name marbles --version 1.0 --sequence 1 --init-required --peerAddresses peer0.org1.hypertest.com:7051 --tlsRootCertFiles /etc/hyperledger/msp/peerOrg1/tls/ca.crt --peerAddresses peer0.org2.hypertest.com:7051 --tlsRootCertFiles /etc/hyperledger/msp/peerOrg2/tls/ca.crt 

peer lifecycle chaincode queryapproved -C hypertest -n marbles --sequence 1

#Запустить CC как сервис

cd ../
wget https://dl.google.com/go/go1.15.linux-amd64.tar.gz
tar -xvf go1.15.linux-amd64.tar.gz
sudo cp -R go /usr/local
export GOROOT=/usr/local/go
export GOPATH=$HOME/Projects/
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
go version

go build -o external-cc
cp external-cc /usr/local/bin/

cat > external-cc.service << EOF
# Service definition for Hyperledger fabric CC server
[Unit]
Description=hyperledger fabric-peer0-org2 CC Server
Documentation=https://hyperledger-fabric.readthedocs.io/
Wants=network-online.target
After=network-online.target
[Service]
Type=simple
Restart=on-failure
Environment=CHAINCODE_CCID=${CHAINCODE_CCID}
Environment=CHAINCODE_ADDRESS=${CHAINCODE_ADDRESS}
ExecStart=/usr/local/bin/external-cc
[Install]
WantedBy=multi-user.target
EOF

sudo mv external-cc.service /etc/systemd/system/
sudo systemctl enable external-cc.service
sudo systemctl start external-cc.service
systemctl status external-cc.service


#peer chaincode invoke -o orderer.hypertest.com:7050 -C hypertest -n marbles --isInit --peerAddresses peer0.org1.hypertest.com:7051 --peerAddresses peer0.org2.hypertest.com:7051 -c '{"Args":["initMarble","marble1","blue","35","tom"]}' --waitForEvent
peer chaincode invoke -o orderer.hypertest.com:7050 -C hypertest -n marbles --peerAddresses peer0.org1.hypertest.com:7051 --peerAddresses peer0.org2.hypertest.com:7051 -c '{"Args":["initMarble","marble1","blue","35","tom"]}' --waitForEvent

peer chaincode query -C hypertest -n marbles -c '{"Args":["readMarble","marble1"]}'


