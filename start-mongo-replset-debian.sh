#!/bin/bash

# shell script to create a simple mongodb replica set (tested on osx)

binPath=$(which mongod)
dbPath=/var/lib/mongodb/mongosvr
logPath=/var/log/mongo
pidPath=$dbPath
systemPath=/lib/systemd/system

function finish {
    pids=(`cat $pidPath/rs-*.pid`)
    for pid in "${pids[@]}"
    do
        kill $pid
        wait $pid
    done
}
trap finish EXIT

set -e


echo "cleanup"
for i in {0..2}
do
    sudo systemctl stop mongod-rs$i
    sudo rm $systemPath/mongod-rs$i.service.test
    mkdir -p $dbPath/rs-$i
done



echo "creating service files"
for i in {0..2}
do
  port=$(expr $i + 1)
  echo "[Unit]
Description=High-performance, schema-free document-oriented database
After=syslog.target network.target
[Service]
User=mongodb
Group=mongodb
ExecStart=$binPath --shardsvr --dbpath $dbPath/rs-$i --replSet set  --port 270${port}7 --pidfilepath $pidPath/rs-$i.pid --logpath=$logPath/mongodbRS$i.log

[Install]
WantedBy=multi-user.target" > $systemPath/mongod-rs$i.service
done

sudo systemctl daemon-reload

echo "start nodes"
for i in {0..2}
do
    sudo systemctl start mongod-rs$i
done



# --config ../../config/mongod.cfg --pidfilepath
# wait a bit for the first server to come up
sleep 5
echo "Replset created"
# call rs.initiate({...})
cfg="{
    _id: 'set',
    members: [
        {_id: 1, host: '127.0.0.1:27017'},
        {_id: 2, host: '127.0.0.1:27027'},
        {_id: 3, host: '127.0.0.1:27037'}
    ]
}"
mongo 127.0.0.1:27017 --eval "JSON.stringify(db.adminCommand({'replSetInitiate' : $cfg}))"
