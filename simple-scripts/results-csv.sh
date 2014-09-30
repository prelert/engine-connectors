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

# A simple Anomaly Detective Engine Results Processor that outputs results to stdout as CSV

# Input: 
# $PRELERT_JOB_ID   : Job ID
# $PRELERT_API_HOST : API host URI

PRELERT_JOB_ID=$1
PRELERT_API_HOST=$2

echo "Getting results for $PRELERT_JOB_ID from $PRELERT_API_HOST"

# Get results and print to stdout as csv
# Gets first million rows
curl "http://$PRELERT_API_HOST:8080/engine/v1/results/$PRELERT_JOB_ID/buckets?take=1000000" | python -c "
import json,sys

obj=json.load(sys.stdin)

buckets=obj['documents']

print 'date,id,anomalyScore'

for bucket in buckets:
    print '{0},{1},{2}'.format(bucket['timestamp'], bucket['id'], bucket['anomalyScore'])
"

