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

# A simple Anomaly Detective Engine connector to delete results dated up until
# the current date minus the given expiry days from the Elasticsearch index
# corresponding to the given job id.

usage() {
	echo "Usage: $0 [-f] [-h <elasticsearch-host>] [-p <elasticsearch-port>] <job-id> <expiry-days>" 1>&2;
	exit 1;
}


ES_HOST='localhost'
ES_PORT='9200'
FORCE=0

while getopts ":fh:p:" opt; do
    case $opt in
        f)
            FORCE=1
            ;;
        h)
            ES_HOST=${OPTARG}
            ;;
        p)
            ES_PORT=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

JOB_ID=$1
EXPIRY_DAYS=$2

if [ -z "${JOB_ID}" ] || [ -z "${EXPIRY_DAYS}" ]; then
    usage
fi

TIMESTAMP=`date -v -${EXPIRY_DAYS}d +%Y-%m-%d`

echo "Deleting results before $TIMESTAMP for job $JOB_ID from $ES_HOST:$ES_PORT"

if [ ${FORCE} -eq 0 ]; then
    read -r -p "Are you sure? [y/n] " response
    case $response in
        [yY][eE][sS]|[yY])
            ;;
        *)
            echo "Aborted"
            exit 0
            ;;
    esac
fi

curl -XDELETE "http://${ES_HOST}:${ES_PORT}/${JOB_ID}/bucket,record/_query?pretty=1" -d "{ \"query\" : { \"range\" : { \"@timestamp\" : { \"lt\" : \"${TIMESTAMP}\" }}}}"

echo "Done"
