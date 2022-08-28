################################## integration-test.sh ################################## 
#!/bin/bash

#integration-test.sh

sleep 5s

PORT=$(kubectl -n default get svc ${serviceName} -o json | jq .spec.ports[].nodePort)

echo "PORT: ${PORT}"
echo "applicationURL: ${applicationURL}"
echo "applicationURI: ${applicationURI}"
echo $applicationURL:$PORT$applicationURI

if [[ ! -z "$PORT" ]];
then

    response=$(curl -s $applicationURL:$PORT$applicationURI)
    http_code=$(curl -s -o /dev/null -w "%{http_code}" $applicationURL:$PORT$applicationURI)

    if [[ "$response" == 100 ]];
        then
            echo "Increment Test Passed"
        else
            echo "Increment Test Failed"
    fi;

    if [[ "$http_code" == 200 ]];
        then
            echo "HTTP Status Code Test Passed"
        else
            echo "HTTP Status code is not 200"
    fi;

    if [[ "$response" == 100 && "$http_code" == 200 ]];
        then
        echo "All tests passed"
        exit 0;
    else
        echo "Integration tests failed"
        exit 1;

else
        echo "The Service does not have a NodePort"
        exit 1;
fi;

################################## integration-test.sh ################################## 
