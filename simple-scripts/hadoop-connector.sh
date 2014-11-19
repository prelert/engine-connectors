#!/bin/sh

# Authors: Anasuya and Asif J - Wipro

# A simple Anomaly Detective Engine connector to analyze a batch of data from a hadoop data store needs to:
# 1. Create an Engine API job
# 2. Query the data store
# 3. Stream data from the data store to the Engine API job

# For example, if time series data is stored in hadoop as follows:
# +---------------------+-------+
# | time                | value |
# +---------------------+-------+
# | 2010-02-10 06:21:00 |   409 |
# | 2010-02-10 06:21:30 |   409 |
# | 2010-02-10 06:22:00 |   409 |
# | 2010-02-10 06:22:30 |   409 |
# | 2010-02-10 06:23:00 |   409 |
# | 2010-02-10 06:23:30 |   409 |

# Note: IMPORTANT to order by time

# Set appropriately for your hadoop details

# dfs.datanode.http.address
DFS_DATANODE_HTTP_ADDRESS=192.168.122.101
DFS_DATANODE_HTTP_PORT=50075

# Filesystem metadata operations(fs.default.name)
NAMENODE_RPC_ADDRESS=192.168.122.101
NAMENODE_RPC_PORT=8020

# Hadoop file system path where the file residing.
HDFS_PATH=/user/hdfs/
FILE_NAME=farequote.csv

PRELERT_API_HOST=localhost

# Create job and record JobId (note default fieldDelimiter is tab)
PRELERT_JOB_ID=`\
curl --globoff -X POST -H 'Content-Type: application/json' 'http://localhost:8080/engine/v1/jobs' -d '{
    "id":"farequote",
    "description":"Analysis of response time by airline",
    "analysisConfig" : {
        "bucketSpan":3600,
        "detectors" :[{"function":"metric","fieldName":"responsetime","byFieldName":"airline"}]
    },
    "dataDescription" : {
        "fieldDelimiter":",",
        "timeField":"time",
        "timeFormat":"yyyy-MM-dd HH:mm:ssX"
    }
}' | awk -F'"' '{ print $4; }' \
`

echo "Created analysis job $PRELERT_JOB_ID"

echo "Querying Hadoop and streaming results to Engine API"

curl -L --globoff "http://$DFS_DATANODE_HTTP_ADDRESS:$DFS_DATANODE_HTTP_PORT/webhdfs/v1$HDFS_PATH$FILE_NAME?op=OPEN&namenoderpcaddress=$NAMENODE_RPC_ADDRESS:$NAMENODE_RPC_PORT" | \
curl -X POST -T - "http://$PRELERT_API_HOST:8080/engine/v1/data/$PRELERT_JOB_ID"


echo "Done."

# Close job - this will flush analytics results
curl -X POST "http://$PRELERT_API_HOST:8080/engine/v1/data/$PRELERT_JOB_ID/close"


# Anomaly detection analysis results are now available to query
# Note: If streaming real-time data then use asynchronous result processor script

# Get results and print to stdout as csv
./results-csv.sh $PRELERT_JOB_ID $PRELERT_API_HOST

#Go to http://192.168.122.101:8080/dashboard/index.html#/dashboard/file/prelert_api_results.json 
