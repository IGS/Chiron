./graph-db/neo4j-community-3.2.0/bin/neo4j start

sed -i -- "s/localhost/$HOST_IP/g" graph-ui/epiviz-metaviz-4.1/site-settings.js

php -S 0.0.0.0:8888 -t /graph-ui/epiviz-metaviz-4.1/ &

python /graph-api/metaviz-data-provider-hmp_workshop/metavizRoute.py
