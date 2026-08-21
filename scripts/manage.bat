@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
title TheirGram Manager - 192.168.0.200:20443

:: TheirGram Management Script
:: Change nick, phone, username, give/take stars
:: Update this file after each server feature change
:: DB: tg, Mongo: mongodb://mongodb:27017 (docker) or mongodb://localhost:27017 (local)
:: Stars: StarsBalance collection {UserId: long, Amount: long}
:: Layer 224, gram.there.durov

set "DB_NAME=tg"
set "MONGO_URI=mongodb://localhost:27017/%DB_NAME%"

:: Detect docker mongodb container
for /f "tokens=*" %%i in ('docker ps --format "{{.Names}}" 2^>nul ^| findstr /i "mongodb"') do set "MONGO_CONTAINER=%%i"
if defined MONGO_CONTAINER (
    set "MONGO_CMD=docker exec -i %MONGO_CONTAINER% mongosh"
    set "MONGO_URI_DOCKER=mongodb://mongodb:27017/%DB_NAME%"
    set "REDIS_CONTAINER="
    for /f "tokens=*" %%j in ('docker ps --format "{{.Names}}" 2^>nul ^| findstr /i "redis"') do set "REDIS_CONTAINER=%%j"
) else (
    set "MONGO_CMD=mongosh"
    set "MONGO_URI_DOCKER=%MONGO_URI%"
)

:menu
cls
echo ========================================
echo   TheirGram Manager (TheirGram)
echo   192.168.0.200:20443  gram.there.durov
echo   Layer 224  fingerprint 0xce27f5081215bda4
echo ========================================
echo.
echo  1. List users (UserId, phone, username, name)
echo  2. Change nickname (FirstName LastName)
echo  3. Change phone number
echo  4. Change username (@username)
echo  5. Stars: show balance
echo  6. Stars: give (add)
echo  7. Stars: take (subtract)
echo  8. Stars: set (absolute)
echo  9. Flush Redis cache (after manual DB edits)
echo  0. Exit
echo.
set /p choice="Select [0-9]: "

if "%choice%"=="1" goto list_users
if "%choice%"=="2" goto change_nick
if "%choice%"=="3" goto change_phone
if "%choice%"=="4" goto change_username
if "%choice%"=="5" goto stars_balance
if "%choice%"=="6" goto stars_give
if "%choice%"=="7" goto stars_take
if "%choice%"=="8" goto stars_set
if "%choice%"=="9" goto flush_redis
if "%choice%"=="0" exit /b 0
goto menu

:list_users
echo.
echo -- Users in %DB_NAME%.UserReadModel --
if defined MONGO_CONTAINER (
    docker exec -i %MONGO_CONTAINER% mongosh %MONGO_URI_DOCKER% --quiet --eval "db.UserReadModel.find({},{UserId:1,PhoneNumber:1,UserName:1,FirstName:1,LastName:1}).limit(50).forEach(p=>print(JSON.stringify(p)))"
) else (
    mongosh %MONGO_URI% --quiet --eval "db.UserReadModel.find({},{UserId:1,PhoneNumber:1,UserName:1,FirstName:1,LastName:1}).limit(50).forEach(p=>print(JSON.stringify(p)))"
)
pause
goto menu

:change_nick
set /p uid="UserId (e.g. 2010001): "
set /p first="FirstName: "
set /p last="LastName (empty for none): "
set /p about="About/bio (empty to skip): "
if "%about%"=="" set "about=%first%"
echo Updating UserReadModel and snapShots for %uid%...
if defined MONGO_CONTAINER (
    docker exec -i %MONGO_CONTAINER% mongosh %MONGO_URI_DOCKER% --quiet --eval "db.UserReadModel.updateOne({UserId: NumberLong('%uid%')}, {\$set: {FirstName: '%first%', LastName: '%last%', About: '%about%'}}); db.snapShots.updateOne({AggregateId: 'user_%uid%'}, {\$set: {'Snapshot.FirstName': '%first%', 'Snapshot.LastName': '%last%'}}); print('updated');"
) else (
    mongosh %MONGO_URI% --quiet --eval "db.UserReadModel.updateOne({UserId: NumberLong('%uid%')}, {\$set: {FirstName: '%first%', LastName: '%last%', About: '%about%'}}); db.snapShots.updateOne({AggregateId: 'user_%uid%'}, {\$set: {'Snapshot.FirstName': '%first%', 'Snapshot.LastName': '%last%'}}); print('updated');"
)
call :flush_redis_silent
echo Done. Nick changed.
pause
goto menu

:change_phone
set /p uid="UserId: "
set /p phone="New phone (e.g. 71234567890, without +): "
echo Updating phone for %uid% to %phone%...
if defined MONGO_CONTAINER (
    docker exec -i %MONGO_CONTAINER% mongosh %MONGO_URI_DOCKER% --quiet --eval "db.UserReadModel.updateOne({UserId: NumberLong('%uid%')}, {\$set: {PhoneNumber: '%phone%'}}); db.snapShots.updateOne({AggregateId: 'user_%uid%'}, {\$set: {'Snapshot.PhoneNumber': '%phone%'}}); print('updated phone');"
) else (
    mongosh %MONGO_URI% --quiet --eval "db.UserReadModel.updateOne({UserId: NumberLong('%uid%')}, {\$set: {PhoneNumber: '%phone%'}}); db.snapShots.updateOne({AggregateId: 'user_%uid%'}, {\$set: {'Snapshot.PhoneNumber': '%phone%'}}); print('updated phone');"
)
call :flush_redis_silent
echo Done. Phone changed. User must re-login if needed.
pause
goto menu

:change_username
set /p uid="UserId: "
set /p uname="New username (without @, empty to remove): "
echo Updating username for %uid% to '%uname%'...
if "%uname%"=="" (
    if defined MONGO_CONTAINER (
        docker exec -i %MONGO_CONTAINER% mongosh %MONGO_URI_DOCKER% --quiet --eval "var old=db.UserReadModel.findOne({UserId: NumberLong('%uid%')}); if(old && old.UserName){db.UserNameReadModel.deleteOne({UserName: old.UserName.toLowerCase()});} db.UserReadModel.updateOne({UserId: NumberLong('%uid%')}, {\$set: {UserName: null, Usernames: []}}); db.snapShots.updateOne({AggregateId: 'user_%uid%'}, {\$set: {'Snapshot.UserName': null}}); print('username removed');"
    ) else (
        mongosh %MONGO_URI% --quiet --eval "var old=db.UserReadModel.findOne({UserId: NumberLong('%uid%')}); if(old && old.UserName){db.UserNameReadModel.deleteOne({UserName: old.UserName.toLowerCase()});} db.UserReadModel.updateOne({UserId: NumberLong('%uid%')}, {\$set: {UserName: null, Usernames: []}}); db.snapShots.updateOne({AggregateId: 'user_%uid%'}, {\$set: {'Snapshot.UserName': null}}); print('username removed');"
    )
) else (
    if defined MONGO_CONTAINER (
        docker exec -i %MONGO_CONTAINER% mongosh %MONGO_URI_DOCKER% --quiet --eval "var peerId=NumberLong('%uid%'); var uname='%uname%'; var lower=uname.toLowerCase(); if(db.UserNameReadModel.findOne({UserName: lower})){print('ERROR: username occupied');} else { var old=db.UserReadModel.findOne({UserId: peerId}); if(old && old.UserName){db.UserNameReadModel.deleteOne({UserName: old.UserName.toLowerCase()});} db.UserNameReadModel.insertOne({UserName: lower, PeerId: peerId, UserNameLower: lower, Date: new Date()}); db.UserReadModel.updateOne({UserId: peerId}, {\$set: {UserName: uname, Usernames: [uname]}}); db.snapShots.updateOne({AggregateId: 'user_'+peerId}, {\$set: {'Snapshot.UserName': uname}}); print('username set to '+uname);}"
    ) else (
        mongosh %MONGO_URI% --quiet --eval "var peerId=NumberLong('%uid%'); var uname='%uname%'; var lower=uname.toLowerCase(); if(db.UserNameReadModel.findOne({UserName: lower})){print('ERROR: username occupied');} else { var old=db.UserReadModel.findOne({UserId: peerId}); if(old && old.UserName){db.UserNameReadModel.deleteOne({UserName: old.UserName.toLowerCase()});} db.UserNameReadModel.insertOne({UserName: lower, PeerId: peerId, UserNameLower: lower, Date: new Date()}); db.UserReadModel.updateOne({UserId: peerId}, {\$set: {UserName: uname, Usernames: [uname]}}); db.snapShots.updateOne({AggregateId: 'user_'+peerId}, {\$set: {'Snapshot.UserName': uname}}); print('username set to '+uname);}"
    )
)
call :flush_redis_silent
pause
goto menu

:stars_balance
set /p uid="UserId: "
if defined MONGO_CONTAINER (
    docker exec -i %MONGO_CONTAINER% mongosh %MONGO_URI_DOCKER% --quiet --eval "var d=db.StarsBalance.findOne({UserId: NumberLong('%uid%')}); if(d) print('Balance for %uid%: '+d.Amount+' stars'); else print('No StarsBalance for %uid% (default 0, converter fallback 10M)');"
) else (
    mongosh %MONGO_URI% --quiet --eval "var d=db.StarsBalance.findOne({UserId: NumberLong('%uid%')}); if(d) print('Balance for %uid%: '+d.Amount+' stars'); else print('No StarsBalance for %uid% (default 0)');"
)
pause
goto menu

:stars_give
set /p uid="UserId: "
set /p amount="Amount to GIVE (e.g. 1000): "
if defined MONGO_CONTAINER (
    docker exec -i %MONGO_CONTAINER% mongosh %MONGO_URI_DOCKER% --quiet --eval "db.StarsBalance.updateOne({UserId: NumberLong('%uid%')}, {\$inc: {Amount: NumberLong('%amount%')}}, {upsert: true}); var d=db.StarsBalance.findOne({UserId: NumberLong('%uid%')}); print('Given %amount% to %uid%, new balance: '+d.Amount);"
) else (
    mongosh %MONGO_URI% --quiet --eval "db.StarsBalance.updateOne({UserId: NumberLong('%uid%')}, {\$inc: {Amount: NumberLong('%amount%')}}, {upsert: true}); var d=db.StarsBalance.findOne({UserId: NumberLong('%uid%')}); print('Given %amount% to %uid%, new balance: '+d.Amount);"
)
pause
goto menu

:stars_take
set /p uid="UserId: "
set /p amount="Amount to TAKE (e.g. 500): "
if defined MONGO_CONTAINER (
    docker exec -i %MONGO_CONTAINER% mongosh %MONGO_URI_DOCKER% --quiet --eval "db.StarsBalance.updateOne({UserId: NumberLong('%uid%')}, {\$inc: {Amount: NumberLong('-%amount%')}}, {upsert: true}); var d=db.StarsBalance.findOne({UserId: NumberLong('%uid%')}); if(d.Amount<0){db.StarsBalance.updateOne({UserId: NumberLong('%uid%')}, {\$set:{Amount: NumberLong(0)}}); d.Amount=0;} print('Taken %amount% from %uid%, new balance: '+d.Amount);"
) else (
    mongosh %MONGO_URI% --quiet --eval "db.StarsBalance.updateOne({UserId: NumberLong('%uid%')}, {\$inc: {Amount: NumberLong('-%amount%')}}, {upsert: true}); var d=db.StarsBalance.findOne({UserId: NumberLong('%uid%')}); if(d.Amount<0){db.StarsBalance.updateOne({UserId: NumberLong('%uid%')}, {\$set:{Amount: NumberLong(0)}}); d.Amount=0;} print('Taken %amount% from %uid%, new balance: '+d.Amount);"
)
pause
goto menu

:stars_set
set /p uid="UserId: "
set /p amount="Set absolute balance to (e.g. 5000): "
if defined MONGO_CONTAINER (
    docker exec -i %MONGO_CONTAINER% mongosh %MONGO_URI_DOCKER% --quiet --eval "db.StarsBalance.updateOne({UserId: NumberLong('%uid%')}, {\$set: {Amount: NumberLong('%amount%')}}, {upsert: true}); print('Set %uid% balance to %amount%');"
) else (
    mongosh %MONGO_URI% --quiet --eval "db.StarsBalance.updateOne({UserId: NumberLong('%uid%')}, {\$set: {Amount: NumberLong('%amount%')}}, {upsert: true}); print('Set %uid% balance to %amount%');"
)
pause
goto menu

:flush_redis
call :flush_redis_silent
echo Redis flushed.
pause
goto menu

:flush_redis_silent
if defined REDIS_CONTAINER (
    docker exec %REDIS_CONTAINER% redis-cli FLUSHDB >nul 2>&1
    docker exec %REDIS_CONTAINER% redis-cli FLUSHALL >nul 2>&1
)
exit /b 0
