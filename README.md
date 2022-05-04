# createMongoReplicaSet
Scripts that automatically create a mongoDB replica set consisting of 3 nodes:

```
mongodb://127.0.0.1:27017
mongodb://127.0.0.1:27018
mongodb://127.0.0.1:27019
```

The corresponding services for Windows, Linux (systemd) and OSX will be created.

## Motivation

To be able to use transactions within MongoDB, it is necessary to operate MongoDB as a multi-node replica set. For this, at least 3 nodes must be created and started as a service. The scripts available here make this possible very easily and for any OS.

## Install

* dump your db (skip if DB empty)
* edit path section in head of script
* make script startable
* execute script
* check replica set with mongo client
* restore you db

### Windows

```shell
./start-mongo-replset.bat
```

creates and starts 3 Windows services: "MongoDB0", "MongoDB1", "MongoDB2"
### Linux (systemd)

```shell
chmod a+x *.sh
./start-mongo-replset-debian.sh
```

creates and starts 3 systemd services: "mongod-rs0.service", "mongod-rs1.service", "mongod-rs2.service" 


### OSX

```shell
chmod a+x *.sh
./start-mongo-replset-osx.sh
```

creates and starts 3 OSX services: "rs0.mongo.plist", "rs1.mongo.plist", "rs2.mongo.plist"