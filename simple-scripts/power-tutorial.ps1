################################################
#
# Anomaly Detective Tutorial for Windows PowerShell
#
# Run each code snippet below in sequence accoring to:
# http://www.prelert.com/docs/engine_api/latest/powershell.html
#
################################################



#### Creating the job ####

$engine = "http://localhost:8080/engine/v1"

# Uses single quotes as literal string contains double quotes 
$jobconfig = '{ 
    "id":"powershell", 
    "description":"Test job for powershell tutorial",
    "analysisConfig" : { 
        "bucketSpan":600, 
        "detectors" :[ 
            {"function":"min", "fieldName":"value" },
            {"function":"max", "fieldName":"value" }            
        ]
        },
        "dataDescription" : { 
            "fieldDelimiter":",",
            "timeField":"time",
            "timeFormat":"dd/MMM/yyyy HH:mm:ssX" 
        } 
}'

Invoke-RestMethod -uri $engine/jobs -Method POST -ContentType "application/json" -Body $jobconfig




#### Upload data to the job ####

$engine = "http://localhost:8080/engine/v1"
$jobdata = "C:\data\tutorial\power-data.csv"
$jobid = "powershell"
Invoke-RestMethod -uri $engine/data/$jobid -Method POST -InFile $jobdata



#### Close the job ####

$engine = "http://localhost:8080/engine/v1"
$jobid = "powershell"
Invoke-RestMethod -uri $engine/data/$jobid/close -Method POST 



#### Query results where anomaly score is greater than or equal to 80 (i.e. big anomalies)

$engine = "http://localhost:8080/engine/v1"
$jobid = "powershell"
Invoke-RestMethod -uri $engine/results/$jobid/buckets?anomalyScore=80 -Method GET | Select -ExpandProperty documents


#### Query results where anomaly score is greater than or equal to 80 and start date is ge 10th Aug

$engine = "http://localhost:8080/engine/v1"
$jobid = "powershell"
$results = Invoke-RestMethod -uri $engine/results/$jobid/buckets?anomalyScore=80`&start=2014-08-10T00:00:00-0000 -Method GET 
$results | Select -ExpandProperty documents
# Note the escape character before the & in Invoke_RestMethod



#### PowerShell is great for reading json data, here is an example where you can enumerate through all of your results

# This is not yet covered in the tutorial notes 

$engine = "http://localhost:8080/engine/v1"
$jobid = "powershell"
$skip = 0
$take = 1
$count = 0


$results = Invoke-RestMethod -uri $engine/results/$jobid/buckets?skip=$skip`&take=$take -Method GET 
$count = $results.hitCount
Write-Output ("Paginating through " + $count + " buckets")

$take = 1000

# Use pagination (in real life, we recommend using date filters too) 
while ($skip -lt $count)
{
    $buckets = Invoke-RestMethod -uri $engine/results/$jobid/buckets?skip=$skip`&take=$take -Method GET | Select -ExpandProperty documents

    foreach ($item in $buckets)
    {
        if ($item.anomalyScore -ge 80)
        {
            Write-Output ("Found " + $item.recordCount + " anomalies at " + $item.timestamp)
        }
    }
    $skip = $skip + $take
}



#### Delete the job

$engine = "http://localhost:8080/engine/v1"
$jobid = "powershell"
Invoke-RestMethod -uri $engine/jobs/$jobid -Method DELETE 


