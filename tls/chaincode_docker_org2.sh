sudo apt update
sudo apt -y install apt-transport-https ca-certificates curl gnupg2 software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
sudo apt update
apt-cache policy docker-ce
sudo apt install docker-ce
sudo systemctl status docker

cp -r /root/hlf_2.2_docker_free/no_tls/chaincodedocker .
cd /root/hlf_2.2_docker_free/no_tls/chaincodedocker/go
GO111MODULE=on go mod vendor
cd ~/

#/etc/hyperledger/fabric/core.yaml 
#в Core.yaml поменять строчку  runtime: $(BASE_DOCKER_NS)/fabric-baseos:$(ARCH)-$(BASE_VERSION) на  runtime: hyperledger/fabric-baseos:$(ARCH)-2.2.0

sudo systemctl stop fabric-peer0-org2.service
sudo systemctl disable fabric-peer0-org2.service
sudo systemctl start fabric-peer0-org2.service
systemctl status fabric-peer0-org2.service

export CCNAME=marblesnew

#Установить в Org1
peer lifecycle chaincode package ${CCNAME}.tar.gz --path hlf_2.2_docker_free/no_tls/chaincodedocker/go --lang golang --label ${CCNAME} 
peer lifecycle chaincode install ${CCNAME}.tar.gz

#Установить в Org2
peer lifecycle chaincode package ${CCNAME}.tar.gz --path /root/hlf_2.2_docker_free/no_tls/chaincodedocker/go --lang golang --label ${CCNAME} 
peer lifecycle chaincode install ${CCNAME}.tar.gz


peer lifecycle chaincode queryinstalled


#Approve в Org2
export CHAINCODE_CCID=marblesnew:3e48a2ebef42a098bd044ee6761363bc4b16593155843c607f678cd00934323c
peer lifecycle chaincode approveformyorg --channelID hypertest --name ${CCNAME}  --version 1.0 --init-required --package-id ${CHAINCODE_CCID} --sequence 1 -o orderer.hypertest.com:7050
peer lifecycle chaincode checkcommitreadiness --channelID hypertest --name ${CCNAME}  --version 1.0 --init-required --sequence 1 -o orderer.hypertest.com:7050 

#commit в Org1
peer lifecycle chaincode commit -o orderer.hypertest.com:7050 --channelID hypertest --name ${CCNAME}  --version 1.0 --sequence 1 --init-required --peerAddresses peer0.org1.hypertest.com:7051 --peerAddresses peer0.org2.hypertest.com:7051
peer lifecycle chaincode queryapproved -C hypertest -n ${CCNAME}  --sequence 1

#Инициализация CC в Org1
peer chaincode invoke -o orderer.hypertest.com:7050 -C hypertest -n ${CCNAME}  --isInit --peerAddresses peer0.org1.hypertest.com:7051 --peerAddresses peer0.org2.hypertest.com:7051 -c '{"Args":["initMarble","marble1","blue","35","tom"]}' --waitForEvent


peer chaincode query -C hypertest -n ${CCNAME}  -c '{"Args":["readMarble","marble1"]}'
peer chaincode invoke -o orderer.hypertest.com:7050 -C hypertest -n ${CCNAME}  --peerAddresses peer0.org1.hypertest.com:7051 --peerAddresses peer0.org2.hypertest.com:7051 -c '{"Args":["initMarble","marble1","blue","35","tom"]}' --waitForEvent

