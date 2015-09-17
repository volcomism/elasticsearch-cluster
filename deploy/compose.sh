#!/bin/bash

### testing
set -x
###
## do login, credentials wil be on host via puppet
docker login -u chipdeploy
## pull new images
docker-compose pull
## stop old containers
docker-compose stop
## remove old containers
docker-compose rm -f
## start new containers
docker-compose up -d

##### define domain
DOMAIN="anfany.com"

##### detect some variables
ES_PUBLISH_HOST=${ES_PUBLISH_HOST:-`/sbin/ip addr|awk '/eth0/ { print $2 }'|grep -E -o '([0-9]{1,3}\.){3}[0-9]{1,3}'`}
ES_HOSTNAME=`hostname -f | cut -d "." -f1`
HOST_ENV=`hostname -f | cut -d "-" -f1`
PROJECT=`hostname -f | cut -d "-" -f2`
TYPE=`hostname -f | cut -d "-" -f3`
RZ=`hostname -f | cut -d "-" -f4`
CURRENT_HOST_NR=`hostname -f | cut -d "-" -f5 | cut -d "." -f1`
CURRENT_HOST="${RZ}-${CURRENT_HOST_NR}"

##### predefine master and zen hosts
PREDEFINED_MASTER=("es-01")
PREDEFINED_ZEN_HOSTS=("es-02" "es-03")


##### search ips from zen hosts, add to array
for ZEN in "${PREDEFINED_ZEN_HOSTS[@]}"
do
        echo "ZEN HOST ${ZEN}"
        ES_ZEN_HOSTS+=(`nslookup ${HOST_ENV}-${PROJECT}-${TYPE}-${ZEN}.${DOMAIN} |awk '/Address:/ { print $2 }'|tail -n1`)
done;

##### define slave settings as default
ES_ZEN_HOST="${ES_ZEN_HOSTS[@]}"
ES_MASTER=false

##### set master=true if host should be a master
for MASTER in "${PREDEFINED_MASTER[@]}"
do
        if [ ${CURRENT_HOST} == ${MASTER} ]
        then
            # node is a master
            ES_ZEN_HOST="${ES_ZEN_HOSTS[@]}"
            ES_MASTER=true
            break
        fi
done;



##### define settings per environment
if [ ${HOST_ENV} == "prd" ]
then
    ES_HEAP_SIZE="6g"
else
    ES_HEAP_SIZE="2g"
fi

ES_CLUSTERNAME="${HOST_ENV}-anfany-search"


/bin/sed -i "s@%ES_CLUSTERNAME%@${ES_CLUSTERNAME}@" docker-compose.yml
/bin/sed -i "s@%ES_HOSTNAME%@${ES_HOSTNAME}@" docker-compose.yml
/bin/sed -i "s@%ES_ZEN_HOST%@${ES_ZEN_HOST}@" docker-compose.yml
/bin/sed -i "s@%ES_MASTER%@${ES_MASTER}@" docker-compose.yml
/bin/sed -i "s@%ES_HEAP_SIZE%@${ES_HEAP_SIZE}@" docker-compose.yml
/bin/sed -i "s@%ES_PUBLISH_HOST%@${ES_PUBLISH_HOST}@" docker-compose.yml

docker-compose -f docker-compose.yml up -d

sleep 15

./install_plugins.sh

sleep 5

curl localhost:9200
#setting of minimum two master nodes
curl -XPUT 'http://localhost:9200/_cluster/settings' -d '{ "persistent" : { "discovery.zen.minimum_master_nodes" : 2 } }'
