@echo off
setlocal enabledelayedexpansion
set dbPathW=c:\ProgramData\mongosvr
set dbPath=%dbPathW:\=/%
set logPath=%dbPath%
set binPath=C:\Program Files\MongoDB\Server\5.0\bin

taskkill /IM "mongod.exe" /F

mkdir "%dbPathW%"

echo "cleanup"
for /l %%i in (0, 1, 2) do (
    mkdir "%dbPathW%\rs-%%i"
    sc stop MongoDB%%i
    timeout /t 1
    sc delete MongoDB%%i
)

echo "create and start files"
for /l %%i in (0, 1, 2) do (
    set /A port=%%i+1
    sc create MongoDB%%i binPath= "\"%binPath%\mongod.exe\" --service --dbpath \"%dbPathW%\rs-%%i\" --replSet set --bind_ip 127.0.0.1 --port 270!port!7 --logpath=\"%logPath%\rs-%%i.log\"" DisplayName= "MongoDB-RS%%i" start= "auto"
    sc start MongoDB%%i
)

timeout /t 5
echo "create replset"

set cfg={^
    _id: 'set',^
    members: [^
        {_id: 1, host: '127.0.0.1:27017'},^
        {_id: 2, host: '127.0.0.1:27027'},^
        {_id: 3, host: '127.0.0.1:27037'}^
    ]}
"%binPath%\mongo" 127.0.0.1:27017 --eval "JSON.stringify(db.adminCommand({'replSetInitiate' : %cfg%}))"

