#!/bin/bash
# TheirGram Manager - 192.168.0.200:20443
# Change nick, phone, username, give/take stars
# Update this file after each server feature change
# DB: tg, Stars: StarsBalance {UserId: long, Amount: long}
# Layer 224, gram.there.durov, fingerprint 0xce27f5081215bda4

set -e

DB_NAME="tg"
MONGO_URI="mongodb://localhost:27017/${DB_NAME}"
MONGO_CONTAINER=$(docker ps --format "{{.Names}}" 2>/dev/null | grep -i mongodb | head -n1 || true)
REDIS_CONTAINER=$(docker ps --format "{{.Names}}" 2>/dev/null | grep -i redis | head -n1 || true)

if [ -n "$MONGO_CONTAINER" ]; then
    MONGO_CMD="docker exec -i $MONGO_CONTAINER mongosh"
    MONGO_URI_DOCKER="mongodb://mongodb:27017/${DB_NAME}"
else
    MONGO_CMD="mongosh"
    MONGO_URI_DOCKER="$MONGO_URI"
fi

flush_redis() {
    if [ -n "$REDIS_CONTAINER" ]; then
        docker exec "$REDIS_CONTAINER" redis-cli FLUSHDB >/dev/null 2>&1 || true
        docker exec "$REDIS_CONTAINER" redis-cli FLUSHALL >/dev/null 2>&1 || true
    fi
}

list_users() {
    echo "-- Users in ${DB_NAME}.UserReadModel --"
    if [ -n "$MONGO_CONTAINER" ]; then
        docker exec -i "$MONGO_CONTAINER" mongosh "$MONGO_URI_DOCKER" --quiet --eval 'db.UserReadModel.find({},{UserId:1,PhoneNumber:1,UserName:1,FirstName:1,LastName:1}).limit(50).forEach(p=>print(JSON.stringify(p)))'
    else
        mongosh "$MONGO_URI" --quiet --eval 'db.UserReadModel.find({},{UserId:1,PhoneNumber:1,UserName:1,FirstName:1,LastName:1}).limit(50).forEach(p=>print(JSON.stringify(p)))'
    fi
}

change_nick() {
    read -p "UserId (e.g. 2010001): " uid
    read -p "FirstName: " first
    read -p "LastName (empty for none): " last
    read -p "About/bio (empty to skip): " about
    [ -z "$about" ] && about="$first"
    echo "Updating UserReadModel and snapShots for $uid..."
    if [ -n "$MONGO_CONTAINER" ]; then
        docker exec -i "$MONGO_CONTAINER" mongosh "$MONGO_URI_DOCKER" --quiet --eval "db.UserReadModel.updateOne({UserId: NumberLong('$uid')}, {\$set: {FirstName: '$first', LastName: '$last', About: '$about'}}); db.snapShots.updateOne({AggregateId: 'user_${uid}'}, {\$set: {'Snapshot.FirstName': '$first', 'Snapshot.LastName': '$last'}}); print('updated');"
    else
        mongosh "$MONGO_URI" --quiet --eval "db.UserReadModel.updateOne({UserId: NumberLong('$uid')}, {\$set: {FirstName: '$first', LastName: '$last', About: '$about'}}); db.snapShots.updateOne({AggregateId: 'user_${uid}'}, {\$set: {'Snapshot.FirstName': '$first', 'Snapshot.LastName': '$last'}}); print('updated');"
    fi
    flush_redis
    echo "Done. Nick changed."
}

change_phone() {
    read -p "UserId: " uid
    read -p "New phone (e.g. 71234567890, without +): " phone
    echo "Updating phone for $uid to $phone..."
    if [ -n "$MONGO_CONTAINER" ]; then
        docker exec -i "$MONGO_CONTAINER" mongosh "$MONGO_URI_DOCKER" --quiet --eval "db.UserReadModel.updateOne({UserId: NumberLong('$uid')}, {\$set: {PhoneNumber: '$phone'}}); db.snapShots.updateOne({AggregateId: 'user_${uid}'}, {\$set: {'Snapshot.PhoneNumber': '$phone'}}); print('updated phone');"
    else
        mongosh "$MONGO_URI" --quiet --eval "db.UserReadModel.updateOne({UserId: NumberLong('$uid')}, {\$set: {PhoneNumber: '$phone'}}); db.snapShots.updateOne({AggregateId: 'user_${uid}'}, {\$set: {'Snapshot.PhoneNumber': '$phone'}}); print('updated phone');"
    fi
    flush_redis
    echo "Done."
}

change_username() {
    read -p "UserId: " uid
    read -p "New username (without @, empty to remove): " uname
    echo "Updating username for $uid to '$uname'..."
    if [ -z "$uname" ]; then
        if [ -n "$MONGO_CONTAINER" ]; then
            docker exec -i "$MONGO_CONTAINER" mongosh "$MONGO_URI_DOCKER" --quiet --eval "var old=db.UserReadModel.findOne({UserId: NumberLong('$uid')}); if(old && old.UserName){db.UserNameReadModel.deleteOne({UserName: old.UserName.toLowerCase()});} db.UserReadModel.updateOne({UserId: NumberLong('$uid')}, {\$set: {UserName: null, Usernames: []}}); db.snapShots.updateOne({AggregateId: 'user_${uid}'}, {\$set: {'Snapshot.UserName': null}}); print('username removed');"
        else
            mongosh "$MONGO_URI" --quiet --eval "var old=db.UserReadModel.findOne({UserId: NumberLong('$uid')}); if(old && old.UserName){db.UserNameReadModel.deleteOne({UserName: old.UserName.toLowerCase()});} db.UserReadModel.updateOne({UserId: NumberLong('$uid')}, {\$set: {UserName: null, Usernames: []}}); db.snapShots.updateOne({AggregateId: 'user_${uid}'}, {\$set: {'Snapshot.UserName': null}}); print('username removed');"
        fi
    else
        if [ -n "$MONGO_CONTAINER" ]; then
            docker exec -i "$MONGO_CONTAINER" mongosh "$MONGO_URI_DOCKER" --quiet --eval "var peerId=NumberLong('$uid'); var uname='$uname'; var lower=uname.toLowerCase(); if(db.UserNameReadModel.findOne({UserName: lower})){print('ERROR: username occupied');} else { var old=db.UserReadModel.findOne({UserId: peerId}); if(old && old.UserName){db.UserNameReadModel.deleteOne({UserName: old.UserName.toLowerCase()});} db.UserNameReadModel.insertOne({UserName: lower, PeerId: peerId, UserNameLower: lower, Date: new Date()}); db.UserReadModel.updateOne({UserId: peerId}, {\$set: {UserName: uname, Usernames: [uname]}}); db.snapShots.updateOne({AggregateId: 'user_'+peerId}, {\$set: {'Snapshot.UserName': uname}}); print('username set to '+uname);}"
        else
            mongosh "$MONGO_URI" --quiet --eval "var peerId=NumberLong('$uid'); var uname='$uname'; var lower=uname.toLowerCase(); if(db.UserNameReadModel.findOne({UserName: lower})){print('ERROR: username occupied');} else { var old=db.UserReadModel.findOne({UserId: peerId}); if(old && old.UserName){db.UserNameReadModel.deleteOne({UserName: old.UserName.toLowerCase()});} db.UserNameReadModel.insertOne({UserName: lower, PeerId: peerId, UserNameLower: lower, Date: new Date()}); db.UserReadModel.updateOne({UserId: peerId}, {\$set: {UserName: uname, Usernames: [uname]}}); db.snapShots.updateOne({AggregateId: 'user_'+peerId}, {\$set: {'Snapshot.UserName': uname}}); print('username set to '+uname);}"
        fi
    fi
    flush_redis
}

stars_balance() {
    read -p "UserId: " uid
    if [ -n "$MONGO_CONTAINER" ]; then
        docker exec -i "$MONGO_CONTAINER" mongosh "$MONGO_URI_DOCKER" --quiet --eval "var d=db.StarsBalance.findOne({UserId: NumberLong('$uid')}); if(d) print('Balance for $uid: '+d.Amount+' stars'); else print('No StarsBalance for $uid (default 0, converter fallback 10M)');"
    else
        mongosh "$MONGO_URI" --quiet --eval "var d=db.StarsBalance.findOne({UserId: NumberLong('$uid')}); if(d) print('Balance for $uid: '+d.Amount+' stars'); else print('No StarsBalance for $uid (default 0)');"
    fi
}

stars_give() {
    read -p "UserId: " uid
    read -p "Amount to GIVE (e.g. 1000): " amount
    if [ -n "$MONGO_CONTAINER" ]; then
        docker exec -i "$MONGO_CONTAINER" mongosh "$MONGO_URI_DOCKER" --quiet --eval "db.StarsBalance.updateOne({UserId: NumberLong('$uid')}, {\$inc: {Amount: NumberLong('$amount')}}, {upsert: true}); var d=db.StarsBalance.findOne({UserId: NumberLong('$uid')}); print('Given $amount to $uid, new balance: '+d.Amount);"
    else
        mongosh "$MONGO_URI" --quiet --eval "db.StarsBalance.updateOne({UserId: NumberLong('$uid')}, {\$inc: {Amount: NumberLong('$amount')}}, {upsert: true}); var d=db.StarsBalance.findOne({UserId: NumberLong('$uid')}); print('Given $amount to $uid, new balance: '+d.Amount);"
    fi
}

stars_take() {
    read -p "UserId: " uid
    read -p "Amount to TAKE (e.g. 500): " amount
    if [ -n "$MONGO_CONTAINER" ]; then
        docker exec -i "$MONGO_CONTAINER" mongosh "$MONGO_URI_DOCKER" --quiet --eval "db.StarsBalance.updateOne({UserId: NumberLong('$uid')}, {\$inc: {Amount: NumberLong('-$amount')}}, {upsert: true}); var d=db.StarsBalance.findOne({UserId: NumberLong('$uid')}); if(d.Amount<0){db.StarsBalance.updateOne({UserId: NumberLong('$uid')}, {\$set:{Amount: NumberLong(0)}}); d.Amount=0;} print('Taken $amount from $uid, new balance: '+d.Amount);"
    else
        mongosh "$MONGO_URI" --quiet --eval "db.StarsBalance.updateOne({UserId: NumberLong('$uid')}, {\$inc: {Amount: NumberLong('-$amount')}}, {upsert: true}); var d=db.StarsBalance.findOne({UserId: NumberLong('$uid')}); if(d.Amount<0){db.StarsBalance.updateOne({UserId: NumberLong('$uid')}, {\$set:{Amount: NumberLong(0)}}); d.Amount=0;} print('Taken $amount from $uid, new balance: '+d.Amount);"
    fi
}

stars_set() {
    read -p "UserId: " uid
    read -p "Set absolute balance to (e.g. 5000): " amount
    if [ -n "$MONGO_CONTAINER" ]; then
        docker exec -i "$MONGO_CONTAINER" mongosh "$MONGO_URI_DOCKER" --quiet --eval "db.StarsBalance.updateOne({UserId: NumberLong('$uid')}, {\$set: {Amount: NumberLong('$amount')}}, {upsert: true}); print('Set $uid balance to $amount');"
    else
        mongosh "$MONGO_URI" --quiet --eval "db.StarsBalance.updateOne({UserId: NumberLong('$uid')}, {\$set: {Amount: NumberLong('$amount')}}, {upsert: true}); print('Set $uid balance to $amount');"
    fi
}

# CLI args support: ./manage.sh <cmd> [args]
if [ $# -gt 0 ]; then
    case "$1" in
        list) list_users ;;
        nick) change_nick ;;
        phone) change_phone ;;
        username) change_username ;;
        stars) stars_balance ;;
        give) stars_give ;;
        take) stars_take ;;
        set) stars_set ;;
        flush) flush_redis; echo "Redis flushed" ;;
        *) echo "Usage: $0 {list|nick|phone|username|stars|give|take|set|flush}" ;;
    esac
    exit 0
fi

# Interactive menu
while true; do
    echo "========================================"
    echo "  TheirGram Manager (TheirGram)"
    echo "  192.168.0.200:20443  gram.there.durov"
    echo "  Layer 224  fingerprint 0xce27f5081215bda4"
    echo "========================================"
    echo ""
    echo " 1. List users"
    echo " 2. Change nickname (FirstName LastName)"
    echo " 3. Change phone number"
    echo " 4. Change username (@username)"
    echo " 5. Stars: show balance"
    echo " 6. Stars: give (add)"
    echo " 7. Stars: take (subtract)"
    echo " 8. Stars: set (absolute)"
    echo " 9. Flush Redis cache"
    echo " 0. Exit"
    echo ""
    read -p "Select [0-9]: " choice
    case "$choice" in
        1) list_users ;;
        2) change_nick ;;
        3) change_phone ;;
        4) change_username ;;
        5) stars_balance ;;
        6) stars_give ;;
        7) stars_take ;;
        8) stars_set ;;
        9) flush_redis; echo "Redis flushed" ;;
        0) exit 0 ;;
        *) echo "Invalid" ;;
    esac
    echo ""
    read -p "Press Enter to continue..."
done
