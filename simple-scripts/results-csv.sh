#!/bin/sh

# A simple Anomaly Detective Engine Results Processor that outputs results to stdout as CSV

# Input: 
# $PRELERT_JOB_ID   : Job ID
# $PRELERT_API_HOST : API host URI

PRELERT_JOB_ID=$1
PRELERT_API_HOST=$2

echo "Getting results for $PRELERT_JOB_ID from $PRELERT_API_HOST"

# Get results and print to stdout as csv
# Gets first million rows
curl "http://$PRELERT_API_HOST:8080/engine/v0.3/results/$PRELERT_JOB_ID?take=1000000" | python -c "
import json,sys

obj=json.load(sys.stdin)

buckets=obj['documents']

print 'date,id,anomalyScore'

for bucket in buckets:
    print '{0},{1},{2}'.format(bucket['timestamp'], bucket['id'], bucket['anomalyScore'])
"

