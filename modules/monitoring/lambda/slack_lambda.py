import os
import json
import urllib3

http = urllib3.PoolManager()
SLACK_WEBHOOK_URL = os.environ['SLACK_WEBHOOK_URL']

def lambda_handler(event, context):
    message = {
        "text": json.dumps(event)
    }
    encoded_msg = json.dumps(message).encode('utf-8')
    resp = http.request('POST', SLACK_WEBHOOK_URL, body=encoded_msg, headers={'Content-Type': 'application/json'})
    return {
        'statusCode': resp.status,
        'body': resp.data.decode('utf-8')
    }
