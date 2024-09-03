# Launching an EC2 instance
In this exercise, you log in to the console as the IAM Admin user. You then launch an EC2 instance by using the IAM role that you created previously. Finally, after you create the employee directory application, you stop and then terminate the instance. Because this instance launch is a dry run, you terminate the instance to prevent additional costs from incurring.
## Setting up by AWS Management Console 
In this task, you will launch an EC2 instance that hosts the employee directory application.
1. If needed, log in to the AWS Management Console as your Admin user.
2. In the **Services** search bar, search for **EC2**, and open the service by choosing **EC2**.
3. In the navigation pane, under **Instances** choose **Instances**.
4. Choose **Launch instances**.
5. For **Name** use ***employee-directory-app***.
6. Under **Application and OS Images (Amazon Machine Image)**, choose the default **Amazon Linux 2023**.
7. Under **Instance type**, select **t2.micro**.
8. Under **Key pair (login)**, choose **Create a new key pair**.
9. For **Key pair name**, paste ***app-key-pair***. Choose **Create key pair**. The required **.pem** file should automatically download for you.
10. Under **Network settings** and **Edit**: Keep the default VPC selection, which should have (default) after the network name
  - **Subnet**: Choose the first subnet in the dropdown list
  - **Auto-assign Public IP**: Enable
11. Under **Firewall (security groups)** choose **Create security group** use ***app-sg*** for the **Security group name** and **Description**.
12. Under **Inbound security groups rules** choose **Remove** above the **ssh** rule.
13. Choose **Add security group rule**. For **Type** choose **HTTP**. Under **Source type** choose **Anywhere**.
14. Expand **Advanced details** and under **IAM instance profile** choose **S3DynamoDBFullAccessRole**.
15 .In the **User data box**, paste the following code:
```bash
#!/bin/bash -ex
wget https://aws-tc-largeobjects.s3-us-west-2.amazonaws.com/DEV-AWS-MO-GCNv2/FlaskApp.zip
unzip FlaskApp.zip
cd FlaskApp/
yum -y install python3-pip
pip install -r requirements.txt
yum -y install stress
export PHOTOS_BUCKET=${SUB_PHOTOS_BUCKET}
export AWS_DEFAULT_REGION=<INSERT REGION HERE>
export DYNAMO_MODE=on
FLASK_APP=application.py /usr/local/bin/flask run --host=0.0.0.0 --port=80
```
