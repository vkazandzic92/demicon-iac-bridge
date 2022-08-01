import os
import boto3
import json
s3_client = boto3.client("s3")


def lambda_handler(event, context):
    try:
        object_key = os.environ['object_key']
        bucket = os.environ['bucket']
        request = event['Records'][0]['cf']['request']
        file_content = s3_client.get_object(
            Bucket=bucket, Key=object_key)["Body"].read()

        state_dict = json.loads(file_content)
        state_output_value = state_dict['outputs']

        if 'query_string' in request:
            query_string = request['query_string']
            return {
                "statusCode": 200,
                "body": state_output_value[query_string],
                "headers": {
                    "Content-Type": "application/json"
                }
            }
        else:
            return {
                "statusCode": 200,
                "body": {'outputs': state_output_value},
                "headers": {
                    "Content-Type": "application/json"
                }
            }

    except Exception as e:
        print(e)
        return {
            "statusCode": 400,
            "body": {"user_message": "Cannot retreieve data from terraform output",
                     "developer_message": e},
            "headers": {
                "Content-Type": "application/json"
            }
        }
