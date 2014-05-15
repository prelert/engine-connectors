Anomaly Detective Engine Connectors
=================

These sample connectors show how to interface with the Anomaly Detective Engine API.

Anomaly Detective analytics uses artificial intelligence in the form of unsupervised machine learning and advanced computational mathematics to process huge volumes of streaming data. It automatically learns normal behavior patterns represented by the data, then identifies and cross-correlates the anomalies.

The Anomaly Detective Engine API is a RESTful interface that enables developers to incorporate this advanced analytics engine into their applications using any language that supports communications over HTTP. Data can be streamed from Big Data stores, from proprietary databases or by uploading a file. The system is self-learning and automatically models the data, without needing to be configure or trained.


Setting up
============

1. Have a read of our documentation: http://www.prelert.com/docs/engine_api/latest
2. Download and install the Anomaly Detective Engine API from here: http://www.prelert.com/reg/anomaly-detective-engine-api.html
3. We recommend you try our quick start example: http://www.prelert.com/docs/engine_api/latest/quick-start.html


Connectors
============
A Connector forwards data from any data source to the Engine API for analysis. The Connector will:

1. Create an Engine API job
2. Query the data store
3. Stream data from the data store to the Engine API job

Simple scripts are available that use cURL. These show a variety of ways to forward data to the Engine API.

Alternatively use our Java or Python clients, available on GitHub. 

Results Processors
============
Results can be viewed using the Engine Dashboard, which is installed along with the Engine API. 

Alternatively a Results Processor can be developed to querying the anomaly detection results. This could be as simple as creating a CSV output, or as complex as adding to Elasticsearch. 

The results are provided as JSON objects to allow maximum flexibility.


