#!/bin/bash
# shell script to create a simple mongodb replica set

binPath=$(where mongod|head -1)
dbPath=/var/lib/mongodb/mongosvr
logPath=/var/log/mongo
pidPath=$dbPath
launchPath=~/Library/LaunchAgents

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
    launchctl stop rs$i.mongo.plist
    launchctl unload $launchPath/rs$i.mongo.plist
    rm $launchPath/rs$i.mongo.plist
    mkdir -p $dbPath/rs-$i
done


echo "creating launch files"
for i in {0..2}
do
  port=$(expr $i + 1)
  echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
	<key>Label</key>
	<string>org.rs$i.mongo.mongod</string>
	<key>KeepAlive</key>
    <true/>
    <key>Program</key>
	<string>$binPath</string>
    <key>StandardInPath</key>
    <string>$logPath/mongodbRS$i.stdin</string>
    <key>StandardOutPath</key>
    <string>$logPath/mongodbRS$i.stdout</string>
    <key>StandardErrorPath</key>
    <string>$logPath/mongodbRS$i.stderr</string>
    <key>ProgramArguments</key>
	<array>
		<string>--logpath=$logPath/mongodbRS$i.log</string>
		<string>--dbpath=$dbPath/rs-$i</string>
		<string>--replSet</string>
		<string>set</string>
		<string>--port</string>
		<string>270${port}7</string>
		<string>--bind_ip</string>
		<string>127.0.0.1</string>
		<string>--pidfilepath</string>
		<string>$pidPath/rs-$i.pid</string>
	</array>
</dict>
</plist>" > $launchPath/rs$i.mongo.plist
done

echo "start nodes"
for i in {0..2}
do
    launchctl load -w $launchPath/rs$i.mongo.plist
    launchctl start rs$i.mongo.plist
done

# --config ../../config/mongod.cfg --pidfilepath
# wait a bit for the first server to come up
sleep 5
echo "config replyset"
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
