#!/bin/bash -l

shopt -s extglob
ROUTE=${INPUT_COMMENT/\/screenshot*([[:space:]])/}
sh -c "echo Running Cypress with route $ROUTE"
cd ../test-app/ || exit
yarn cypress run --env route="$ROUTE"

date=`date +%Y%m%d`
dateFormatted=`date -R`
s3Bucket="tomdaly-gh-actions-test"
fileName="screenshot.png"
pathName="cypress/screenshots/spec.ts/$fileName"
relativePath="/${s3Bucket}/${fileName}"
contentType="application/octet-stream"
stringToSign="PUT\n\n${contentType}\n${dateFormatted}\n${relativePath}"
s3AccessKey=${MY_S3_ACCESS_KEY}
s3SecretKey=${MY_S3_SECRET_KEY}
region="eu-west-1"
signature=`echo -en ${stringToSign} | openssl sha1 -hmac ${s3SecretKey} -binary | base64`
sh -c "echo Uploading $fileName to S3"
curl -X PUT -T "${pathName}" \
-H "Host: ${s3Bucket}.s3-${region}.amazonaws.com" \
-H "Date: ${dateFormatted}" \
-H "Content-Type: ${contentType}" \
-H "Authorization: AWS ${s3AccessKey}:${signature}" \
-L http://${s3Bucket}.s3-${region}.amazonaws.com/${fileName} --max-redirs 1
sh -c "echo Done"
