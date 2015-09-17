#!/bin/bash
# Install plugins for development
docker exec deploy_elasticsearch_1 /usr/share/elasticsearch/bin/plugin -install mobz/elasticsearch-head
docker exec deploy_elasticsearch_1 /usr/share/elasticsearch/bin/plugin -install elasticsearch/marvel/latest
docker exec deploy_elasticsearch_1 /usr/share/elasticsearch/bin/plugin -install royrusso/elasticsearch-HQ
