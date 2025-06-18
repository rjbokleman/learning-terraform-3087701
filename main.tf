data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["979382823631"] # Bitnami
}

# # Default vpc created when the aws account was created.
# data "aws_vpc" "default" {
#   default = true
# }

module "blog_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "dev"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  # private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  # enable_nat_gateway = true
  # enable_vpn_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}


resource "aws_instance" "blog" {
  ami           = data.aws_ami.app_ami.id
  instance_type = var.instance_type

  # # Add aws security group to the VPC the EC2 instance lives in as defined below.
  # vpc_security_group_ids = [aws_security_group.blog.id]

  # Add aws security group to the VPC the EC2 instance lives in as defined using the module.
  vpc_security_group_ids = [module.blog-sg.security_group_id]

  subnet_id = module.blog_vpc.public_subnets[0]
  
  tags = {
    Name = "Learning Terraform"
  }
}

module "blog-sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"
  name = "blog_new"

  #vpc_id              = data.aws_vpc.default.id
  #Using the aws/vpc module instead of the above.

  vpc_id = module.blog_vpc.default_vpc_id

  ingress_rules       = ["http-80-tcp","https-443-tcp"]
  ingress_cidr_blocks = [ "0.0.0.0/0" ]

  egress_rules       = ["all-all"]
  egress_cidr_blocks = [ "0.0.0.0/0" ]
}


# # Create new aws_security_group in the default vpc.
# resource "aws_security_group" "blog" {
#   name        = "blob"
#   description = "Allow http and https in.  Allow everything out."

#   vpc_id = data.aws_vpc.default.id
# }

# # Create new security group ingress rule for default vpc 80.
# resource "aws_security_group_rule" "blog_http_in" {
#   type        = "ingress"
#   from_port   = 80
#   to_port     = 80
#   protocol    = "tcp"
#   cidr_blocks = [ "0.0.0.0/0" ]

#   security_group_id = aws_security_group.blog.id
# }

# # Create new security group ingress rule for default vpc 443.
# resource "aws_security_group_rule" "blog_https_in" {
#   type        = "ingress"
#   from_port   = 443
#   to_port     = 443
#   protocol    = "tcp"
#   cidr_blocks = [ "0.0.0.0/0" ]

#   security_group_id = aws_security_group.blog.id
# }

# # Create new security group egress rule for default vpc.
# resource "aws_security_group_rule" "blog_everything_out" {
#   type        = "egress"
#   from_port   = 0
#   to_port     = 0
#   protocol    = "-1"
#   cidr_blocks = [ "0.0.0.0/0" ]

#   security_group_id = aws_security_group.blog.id
# }
