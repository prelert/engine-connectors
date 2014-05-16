#!/bin/sh

############################################################################
#                                                                          #
# Copyright 2014 Prelert Ltd                                               #
#                                                                          #
# Licensed under the Apache License, Version 2.0 (the "License");          #
# you may not use this file except in compliance with the License.         #
# You may obtain a copy of the License at                                  #
#                                                                          #
#    http://www.apache.org/licenses/LICENSE-2.0                            #
#                                                                          #
# Unless required by applicable law or agreed to in writing, software      #
# distributed under the License is distributed on an "AS IS" BASIS,        #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. #
# See the License for the specific language governing permissions and      #
# limitations under the License.                                           #
#                                                                          #
############################################################################


# A simple Anomaly Detective Engine connector to analyze a batch of data from a MySQL data store needs to:
# 1. Create an Engine API job
# 2. Query the data store
# 3. Stream data from the data store to the Engine API job

# For example, if time series data is stored in MySQL as follows:
# mysql> select time,value from time_series_points where time_series_id=4118 order by time;
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

# Set appropriately for your database
MYSQL_USER=root
MYSQL_DB=dbname

PRELERT_API_HOST=localhost

# Create job and record JobId (note default fieldDelimiter is tab)
PRELERT_JOB_ID=`\
curl -X POST -H 'Content-Type: application/json' "http://$PRELERT_API_HOST:8080/engine/v0.3/jobs" -d '{
        "analysisConfig" : {
        "bucketSpan":3600,
        "detectors" :[{"function":"max","fieldName":"value"}]
},
    "dataDescription" : {
        "timeField":"time",
        "timeFormat":"yyyy-MM-dd HH:mm:ss"
    }
}' | awk -F'"' '{ print $4; }' \
`

echo "Created analysis job $PRELERT_JOB_ID"

echo "Querying MySQL and streaming results to Engine API"

# Query database (requesting tab separated output) and stream to Engine API
mysql -u "$MYSQL_USER" -p -D "$MYSQL_DB" -B -e "select time,value from time_series_points where time_series_id=4118 order by time;" | \
curl -X POST -T - "http://$PRELERT_API_HOST:8080/engine/v0.3/data/$PRELERT_JOB_ID"

echo "Done."

# Close job - this will flush analytics results
curl -X POST "http://$PRELERT_API_HOST:8080/engine/v0.3/data/$PRELERT_JOB_ID/close"


# Anomaly detection analysis results are now available to query
# Note: If streaming data then use asynchronous result processor script

# Get results and print to stdout as csv
./results-csv.sh $PRELERT_JOB_ID $PRELERT_API_HOST

