resource "aws_instance" "tf_private_instance" {
  ami                         = "ami-08ca1d1e465fbfe0c"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.tf_private_subnet.id
  associate_public_ip_address = false
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.tf_private_instance_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.tf_private_instance_profile.name
  user_data                   = <<-EOF
            #!/bin/bash
            yum -y update
            yum -y install python3-pip
            pip3 install flask boto3

            cat > /home/ec2-user/backend.py << 'END'
            ${file("app/backend.py")}
            END

            export BUCKET="${aws_s3_bucket.tf_bucket.bucket}"
            export KEY="tf-obj"
            python3 /home/ec2-user/backend.py &
  EOF

  tags = {
    Name = "tf-private-instance"
  }

  depends_on = [
    aws_s3_bucket.tf_bucket,
  ]
}


resource "aws_instance" "tf_public_instance_1" {
  ami                         = "ami-08ca1d1e465fbfe0c"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.tf_public_subnet_1.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.tf_public_instance_sg.id]
  user_data                   = <<-EOF
            #!/bin/bash
            yum -y update
            yum -y install python3-pip
            pip3 install flask requests

            cat > /home/ec2-user/frontend.py << 'END'
            ${file("app/frontend.py")}
            END

            export PRIVATE_API="http://${aws_instance.tf_private_instance.private_ip}"
            export INSTANCE_ID="1"

            python3 /home/ec2-user/frontend.py &
            EOF

  tags = {
    Name = "tf-public-instance-1"
  }

  depends_on = [
    aws_instance.tf_private_instance
  ]
}


resource "aws_instance" "tf_public_instance_2" {
  ami                         = "ami-08ca1d1e465fbfe0c"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.tf_public_subnet_2.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.tf_public_instance_sg.id]
  user_data                   = <<-EOF
            #!/bin/bash
            yum -y update
            yum -y install python3-pip
            pip3 install flask requests
            
            cat > /home/ec2-user/frontend.py << 'END'
            ${file("app/frontend.py")}
            END

            export PRIVATE_API="http://${aws_instance.tf_private_instance.private_ip}"
            export INSTANCE_ID="2"

            python3 /home/ec2-user/frontend.py &
  EOF

  tags = {
    Name = "tf-public-instance-2"
  }

  depends_on = [
    aws_instance.tf_private_instance
  ]
}
