import os
import boto3
import json
s3_client = boto3.client("s3")


def lambda_handler(event, context):
    return 'works'
