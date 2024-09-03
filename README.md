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
15. In the **User data box**, paste the following code:
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
16. In the pasted code, change the following line to match your Region (your Region is listed at the top right, next to your user name):
```bash
export AWS_DEFAULT_REGION=<INSERT REGION HERE>
```
Example:
The following example uses the US West (Oregon) Region, or us-west-2.
```bash
export AWS_DEFAULT_REGION=us-west-2
```
17. Choose **Launch instance**.
18. Choose **View all instances**.
The instance should now be listed under **Instances**.
19. Wait for the **Instance state** to change to Running and the **Status check** to change to 2/2 checks passed.

**Note**: Often, the status checks update, but the console user interface (UI) might not update to reflect the most recent information. You can minimize waiting by refreshing the page after a few minutes.
## Setting up by Terraform
### 1. Provider Block
```hcl
provider "aws" {
  region = "ap-southeast-1" # Change this to your desired region
}
```
  - **provider "aws"**: This block specifies that we are using AWS as our cloud provider.
  - **region**: Specifies the AWS region where your resources will be created. Change this to your desired region, such as "us-east-1" if that is where you want your EC2 instance to reside.
### 2. Key Pair Resource
```hcl
resource "aws_key_pair" "app_key_pair" {
  key_name   = "app-key-pair"
  public_key = file("<path-to-your-public-key>.pem") # Replace with the path to your public key file
}
```
  - **resource "aws_key_pair"**: This resource creates an SSH key pair for accessing the EC2 instance.
  - **key_name**: The name of the key pair, which will be ***"app-key-pair"*** in this case.
  - **public_key**: Specifies the path to your public key file (usually has a ***.pem** extension). Replace ***<path-to-your-public-key>.pem*** with the actual path to your public key.
### 3. Security Group Resource
```hcl
resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  description = "Security group for the employee directory app"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["YOUR_IP_ADDRESS/32"] # Replace with your IP address for SSH access
  }
}
```
  - **resource "aws_security_group"**: This defines a new security group called ***"app-sg"*** for your application.
  - **ingress block**: Defines inbound rules for the security group:
    - **First ingress rule**: Allows HTTP traffic on port 80 from anywhere (***0.0.0.0/0***).
    - **Second ingress rule**: Allows SSH traffic on port 22 but restricts it to a specific IP address (replace ***YOUR_IP_ADDRESS/32*** with your actual IP).
### 4. EC2 Instance Resource
```hcl
resource "aws_instance" "employee_directory_app" {
  ami           = "ami-0abcdef1234567890" # Replace with the latest Amazon Linux 2023 AMI ID
  instance_type = "t2.micro"
  key_name      = aws_key_pair.app_key_pair.key_name
  subnet_id     = "<subnet_id>" # Replace with the actual subnet ID
  
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data = <<-EOF
              #!/bin/bash -ex
              wget https://aws-tc-largeobjects.s3-ap-southeast-1.amazonaws.com/DEV-AWS-MO-GCNv2/FlaskApp.zip
              unzip FlaskApp.zip
              cd FlaskApp/
              yum -y install python3-pip
              pip install -r requirements.txt
              yum -y install stress
              export PHOTOS_BUCKET=${SUB_PHOTOS_BUCKET}
              export AWS_DEFAULT_REGION=ap-southeast-1
              export DYNAMO_MODE=on
              FLASK_APP=application.py /usr/local/bin/flask run --host=0.0.0.0 --port=80
              EOF

  tags = {
    Name = "employee-directory-app"
  }
}
```
  - **resource "aws_instance"**: This resource launches a new EC2 instance.
    - **ami**: Specifies the Amazon Machine Image (AMI) ID. Replace ***ami-0abcdef1234567890*** with the latest Amazon Linux 2023 AMI ID from your region.
    - **instance_type**: Defines the instance type as ***t2.micro***, which qualifies for the free tier.
    - **key_name**: References the previously created key pair for SSH access.
    - **subnet_id**: Replace ***<subnet_id>*** with the actual subnet ID where the instance will be launched.
    - **vpc_security_group_ids**: Associates the EC2 instance with the security group created earlier.
    - **user_data**: Contains a script that runs automatically when the instance is launched. This script:
      - Downloads a zip file containing the application.
      - Installs necessary packages and dependencies.
      - Sets environment variables.
      - Starts the Flask application.
### 5. Output Block
```hcl
output "instance_id" {
  value = aws_instance.employee_directory_app.id
}
```
  - **output "instance_id"**: This block outputs the instance ID of the created EC2 instance.
  - **value**: References the ID of the instance we launched, making it easy to access once the resources are created.
### Additional Information
  - **Execution**: After configuring the HCL code, run **terraform init** to initialize the working directory containing Terraform configuration files. After that, **terraform apply** will create the specified resources in AWS.
  - **Dependencies**: Ensure that you have the appropriate AWS credentials set up in your environment, as Terraform uses these credentials to provision resources.
  - **Clean Up**: To delete the resources created, you can simply run **terraform destroy**, which will clean up all resources defined in your Terraform scripts.
