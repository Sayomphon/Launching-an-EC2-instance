provider "aws" {
  region = "ap-southeast-1" # Change this to your desired region
}

resource "aws_key_pair" "app_key_pair" {
  key_name   = "app-key-pair"
  public_key = file("<path-to-your-public-key>.pem") # Replace with the path to your public key file
}

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

output "instance_id" {
  value = aws_instance.employee_directory_app.id
}