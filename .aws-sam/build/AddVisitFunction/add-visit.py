import json
import boto3

def add_visit(siteName):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('Visits')

    response = table.update_item(
        Key={
            'siteName': siteName
        },
        UpdateExpression='set totalVisits = totalVisits + :num',
        ExpressionAttributeValues={
            ':num': 1
        },
        ReturnValues='UPDATED_NEW'
    )

    return response

def lambda_handler(event, context):
    # site_name = event['siteName']
    site_name = 'resume'
    add_visit_response = add_visit(site_name)

    response_body = { 'siteName': site_name, 
        'totalVisits': str(add_visit_response['Attributes']['totalVisits']) 
    }

    return {
        'statusCode': 200,
        'body': json.dumps(response_body),
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
    }