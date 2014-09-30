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


# A simple Anomaly Detective Engine connector to analyze a batch of data from a
# web server access log that contains entries formatted like this:

# 172.16.1.25 - - [16/May/2014:16:38:34 +0100] "GET /wiki/index.php/Main_Page HTTP/1.1" 200 19329 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_5) AppleWebKit/537.75.14 (KHTML, like Gecko) Version/6.1.3 Safari/537.75.14"
# 172.16.1.25 - - [16/May/2014:16:38:36 +0100] "GET /wiki/index.php/Development_Setup HTTP/1.1" 200 49576 "http://linux/wiki/index.php/Main_Page" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_5) AppleWebKit/537.75.14 (KHTML, like Gecko) Version/6.1.3 Safari/537.75.14"
# 172.16.1.25 - - [16/May/2014:16:38:41 +0100] "GET /wiki/index.php/Development_Setup_for_Mac_OS_X HTTP/1.1" 200 52450 "http://linux/wiki/index.php/Development_Setup" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_5) AppleWebKit/537.75.14 (KHTML, like Gecko) Version/6.1.3 Safari/537.75.14"
# 172.16.1.35 - - [16/May/2014:17:04:29 +0100] "GET /wiki/ HTTP/1.1" 301 - "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.131 Safari/537.36"
# 172.16.1.35 - - [16/May/2014:17:04:29 +0100] "GET /wiki/index.php/Main_Page HTTP/1.1" 304 - "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.131 Safari/537.36"
# 172.16.1.35 - - [16/May/2014:17:04:29 +0100] "GET /wiki/index.php?title=MediaWiki:Monobook.css&usemsgcache=yes&ctype=text%2Fcss&smaxage=18000&action=raw&maxage=18000 HTTP/1.1" 200 60 "http://linux/wiki/index.php/Main_Page" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.131 Safari/537.36"

# We look for higher than usual numbers of each different status code, so will
# pick up occasions where there are lots of 500 errors (indicating back-end
# server problems) for example

# This file is usually only readable by root, so run this script with sudo
INPUT_FILE=/var/log/httpd/access_log

PRELERT_API_HOST=localhost

# Create job and record JobId (the fieldDelimiter is space in this case and
# we're happy with the default quote character)
PRELERT_JOB_ID=`\
curl -X POST -H 'Content-Type: application/json' "http://$PRELERT_API_HOST:8080/engine/v1/jobs" -d '{
        "analysisConfig" : {
        "bucketSpan":3600,
        "detectors" :[{"function":"high_count","byFieldName":"status"}]
},
    "dataDescription" : {
        "fieldDelimiter":" ",
        "timeField":"time",
        "timeFormat":"dd/MMM/yyyy:HH:mm:ss X"
    }
}' | awk -F'"' '{ print $4; }' \
`

echo "Created analysis job $PRELERT_JOB_ID"

echo "Uploading $INPUT_FILE"

# Upload to Engine API with a header row, replacing the square brackets around
# the date (the first of each on each line) with quotes
(echo 'clientip ident user time request status bytes referer useragent' && cat "$INPUT_FILE") | \
sed 's/\[/"/' | \
sed 's/\]/"/' | \
curl -X POST -T - "http://$PRELERT_API_HOST:8080/engine/v1/data/$PRELERT_JOB_ID"

echo "Done."

# Close job - this will flush analytics results
curl -X POST "http://$PRELERT_API_HOST:8080/engine/v1/data/$PRELERT_JOB_ID/close"


# Anomaly detection analysis results are now available to query
# Note: If streaming real-time data then use asynchronous result processor script

# Get results and print to stdout as csv
./results-csv.sh $PRELERT_JOB_ID $PRELERT_API_HOST

