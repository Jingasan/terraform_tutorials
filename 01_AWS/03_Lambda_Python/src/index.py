import os
import json
#import boto3

def handler(event, context):
    env_val = os.getenv('ENV_VAL')
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': env_val,
        })
    }