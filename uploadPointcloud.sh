#!/bin/bash
BUCKET_NAME=test-cvast-potree 

aws s3 sync www/potree/resources/pointclouds s3://${BUCKET_NAME} --recursive