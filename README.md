Setup

1. Prequisites

```
sudo apt install build-essential
```

1. Install Mongo

https://docs.mongodb.com/manual/tutorial/install-mongodb-on-ubuntu/

```
sudo apt-get install gnupg
wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -

echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list
sudo apt-get update
sudo apt-get install -y mongodb-org=4.2.8 mongodb-org-server=4.2.8 mongodb-org-shell=4.2.8 mongodb-org-mongos=4.2.8 mongodb-org-tools=4.2.8
echo "mongodb-org hold" | sudo dpkg --set-selections
echo "mongodb-org-server hold" | sudo dpkg --set-selections
echo "mongodb-org-shell hold" | sudo dpkg --set-selections
echo "mongodb-org-mongos hold" | sudo dpkg --set-selections
echo "mongodb-org-tools hold" | sudo dpkg --set-selections

```

1. Update config to Create Replica Set
config file - /etc/mongod.conf (Default)

```
replication:
   replSetName: "rs0"
net:
  port: 27017
  bindIp: 0.0.0.0
```

sudo systemctl start mongod
sudo systemctl status mongod

1. Go to mongo shell and Initiate Replica Set

rs.initiate(
   {
      _id: "rs0",
      version: 1,
      members: [
         { _id: 0, host : "127.0.0.1:27017" },
      ]
   }
)

1. Create Users
use admin;

db.createUser(
  {
    user: "bsc_wallet_user",
    pwd: "w57pEXUk3XZmqcyc",  
    roles: [
       { role: "readWrite", db: "bsc_wallet" }
    ]
  }
)

db.createUser(
  {
    user: "xlm_wallet_user",
    pwd: "w57pEXUk3XZmqcyc",  
    roles: [
       { role: "readWrite", db: "btc_wallet" }
    ]
  }
)



1. Install Redis

`sudo apt install redis-server`



```

1. Start Node - testnet
Install :

```
sudo add-apt-repository -y ppa:ethereum/ethereum
sudo apt-get update 
sudo apt-get install ethereum
```
Create folder for etherum blockchain and run below command in it

Start Tmux Session (if not started already)
tmux new -s eth_node

Attach Tmux Session (if started already)
tmux a -t eth_node

Start Node
geth --testnet --syncmode="fast" -datadir . -rpc -rpcport "8545" -port "30303" -rpccorsdomain "*" --rpcaddr "0.0.0.0" -rpcapi eth,web3,personal,net --cache=1024

Attach Geth Node
Open new tab in tmux (ctrl b + c)
geth attach geth.ipc

CURL Example (To Test - Change IP)
curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":67}' http://172.16.120.24:8545

1. Update Config

    Go to config/config.js

    Update - 
         config.mnemonic -> client seed
         config.node.eth -> Node URL
         config.node.chainID -> Node Chain ID (1 Mainnet, 3 Ropsten, 4 Rinkbey)
         config.rabbitmq.url -> RabbitMQ Host

         config.db -> Update DB config
         config.redis -> Redis Config

         config.callback.url.pending -> Callback URL for Pending Transaction
         config.callback.url.confirm -> Callback URL for Confirmed Transaction
         
         update current path of config.erc.json -> JSON ABI file for ERC20 Contracts
         
         config.coldWallet.minimumValueTrigger.ETH => minimum eth check
         config.coldWallet.minimumValueTrigger.USDT => minimum erc check
         config.coldWallet.minimumValueTrigger.USDC => minimum erc check
         config.coldWallet.percentagMovementAmount => min value movement
         config.coldWallet.address => cold wallet address


1. Create Indexes

db.eth_transactions.createIndex({"tx_hash":1}, { unique : true })
db.erc_transactions.createIndex({"tx_hash":1}, { unique : true })
db.eth_address.createIndex({"address": 1}, { unique : true })
db.erc_registered_tokens.createIndex({"smart_contract_address": 1}, { unique : true })

1. Generate Log Folders

```
sudo mkdir -p /var/log/wallet/binance/api/
sudo mkdir -p /var/log/wallet/binance/services/eth/mempool/
sudo mkdir -p /var/log/wallet/binance/services/eth/withdraw/
sudo mkdir -p /var/log/wallet/binance/services/eth/block/
sudo mkdir -p /var/log/wallet/binance/services/erc/mempool/
sudo mkdir -p /var/log/wallet/binance/services/erc/block/
sudo mkdir -p /var/log/wallet/binance/services/hook/
sudo mkdir -p /var/log/wallet/binance/services/coldWallet/
sudo chmod -R 777 /var/log/wallet/*
```

1. Add Delete Paths in services/deleteLogs.js so that logs will be deleted after given time

1. Install Node and Pm2 

curl -sL https://deb.nodesource.com/setup_10.x -o nodesource_setup.sh
sudo bash nodesource_setup.sh
sudo apt install nodejs
sudo apt install npm

1. Install Packages

```
sudo npm install
sudo npm install pm2 -g
```


1. Generate Admin Wallet
    node scripts/GenerateAdminAddress.js


1. Run

    Run API Server 
        `pm2 start index.js --name="eth_wallet_api" --max-memory-restart 100M`
    
    Run Services ETH
        ```
         pm2 start services/BSCMempoolCrawler.js --name="bsc_mempool_crawler" --max-memory-restart 100M

         Easy temporary fix for (Error: Number can only safely store up to 53 bits)

         Open file .\node_modules\number-to-bn\node_modules\bn.js\lib\bn.js
         Go to line 506 assert(false, 'Number can only safely store up to 53 bits');
         Replace it with ret = Number.MAX_SAFE_INTEGER;

         pm2 start services/BSCBlockCrawler.js --name="bsc_block_crawler" --max-memory-restart 100M
         (Set bsc_crawled_blocks/erc_crawled_blocks to latest block in redis DB to skip blocks)

         pm2 start services/BEPMempoolCrawler.js --name="bep_mempool_crawler" --max-memory-restart 100M
         pm2 start services/BEPBlockCrawler.js --name="bep_block_crawler" --max-memory-restart 100M
         (Set bep_crawled_blocks/bep_crawled_blocks to latest block in redis DB to skip blocks)
         
         pm2 start services/ColdWalletMovement.js --name="bsc_cold_wallet_movement" --max-memory-restart 100M
         pm2 start services/DeleteLogs.js --name="bsc_logs_delete" --max-memory-restart 100M

        ```

1. Update EndPoints Paths in Exchange DB 

1. In case of callback fail
   Run -> scripts/RetryFailedCallbacks.js

1. Set expected Nonce in redis (same as admin hot wallet current nonce)
   redis-cli
   set bsc_admin_expected_nonce 0



sudo apt update
sudo apt upgrade
sudo apt autoremove

## Install NodeJS 14
curl -sL https://deb.nodesource.com/setup_14.x | sudo bash -
cat /etc/apt/sources.list.d/nodesource.list
sudo apt -y install nodejs

## Install Erlang
sudo apt install software-properties-common apt-transport-https
wget -O- https://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc | sudo apt-key add -
echo "deb https://packages.erlang-solutions.com/ubuntu focal contrib" | sudo tee /etc/apt/sources.list.d/rabbitmq.list
sudo apt update
sudo apt install erlang

## Install RabbitMQ
curl -s https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.deb.sh | sudo bash
sudo apt update && sudo apt install rabbitmq-server
systemctl status  rabbitmq-server.service
sudo systemctl enable rabbitmq-server
sudo rabbitmq-plugins enable rabbitmq_management

## Add Entry for Port
sudo ss -tunelp | grep 15672

## Incase of gyp error on NPM i
sudo apt install build-essential

## Install Redis-CLI
sudo apt install redis-server && sudo systemctl enable redis-server

## Install NGinx
sudo apt install nginx