import os
import boto3
import tempfile

BUCKET_NAME = os.environ['BUCKET_NAME']

def lambda_handler(event, context):
    s3_client = boto3.client('s3')

    # Generate a text file
    file_content = "Hello, World!"
    temp_file = tempfile.NamedTemporaryFile(delete=False)
    with open(temp_file.name, 'w') as f:
        f.write(file_content)

    # Upload file to S3
    s3_client.upload_file(temp_file.name, BUCKET_NAME, 'test_file.txt')

    # Download file from S3
    s3_client.download_file(BUCKET_NAME, 'test_file.txt', temp_file.name)

    # Read the content of the file and print
    with open(temp_file.name, 'r') as f:
        file_content = f.read()
        print(file_content)
