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


# A simple Anomaly Detective Engine connector to analyze a batch of data from a CSV file.

# This script effectively does the same analysis as the tutorial, but with the various
# steps automated instead of being entered manually

# If you haven't already got it, the tutorial data can be downloaded from:
# http://s3.amazonaws.com/prelert_demo/farequote_ISO_8601.csv

# Note: The records in the CSV file MUST be ordered by time - they are in the tutorial
#       data but if you substitute a CSV file of your own you must make sure it's
#       sorted into ascending time order

CSV_FILE=/home/dave/farequote_ISO_8601.csv

PRELERT_API_HOST=localhost

# Create job and record JobId (note default fieldDelimiter is tab)
PRELERT_JOB_ID=`\
curl -X POST -H 'Content-Type: application/json' "http://$PRELERT_API_HOST:8080/engine/v0.3/jobs" -d '{
        "analysisConfig" : {
        "bucketSpan":3600,
        "detectors" :[{"function":"metric","fieldName":"responsetime","byFieldName":"airline"}]
},
    "dataDescription" : {
        "fieldDelimiter":",",
        "timeField":"time",
        "timeFormat":"yyyy-MM-dd HH:mm:ss"
    }
}' | awk -F'"' '{ print $4; }' \
`

echo "Created analysis job $PRELERT_JOB_ID"

echo "Uploading $CSV_FILE"

# Upload to Engine API
curl -X POST -T "$CSV_FILE" "http://$PRELERT_API_HOST:8080/engine/v0.3/data/$PRELERT_JOB_ID"

echo "Done."

# Close job - this will flush analytics results
curl -X POST "http://$PRELERT_API_HOST:8080/engine/v0.3/data/$PRELERT_JOB_ID/close"


# Anomaly detection analysis results are now available to query
# Note: If streaming real-time data then use asynchronous result processor script

# Get results and print to stdout as csv
./results-csv.sh $PRELERT_JOB_ID $PRELERT_API_HOST

