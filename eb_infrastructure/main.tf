terraform {
  required_providers {
    aws = { # Specify required AWS provider version
      source  = "hashicorp/aws"
      version = ">= 5.1"
    }
  }
  required_version = ">= 1.2.0" # Specify required Terraform version
}

provider "aws" {
  region = "us-east-1" # Set AWS provider configuration for the us-east-1 region.
}

resource "local_file" "docker_run_config" {
  content = jsonencode({
    AWSEBDockerrunVersion = 2
    containerDefinitions = [
      {
        name      = "backend"
        image     = "m4tth3wg/tic-tac-toe-cloud-backend:latest"
        memory    = 128
        essential = true
        portMappings = [{
          hasPort       = 8080 # potential error
          containerPort = 8080
        }]
      },
      {
        name      = "frontend"
        image     = "m4tth3wg/tic-tac-toe-cloud-frontend:latest"
        memory    = 128
        essential = true
      }
    ]
  })
  filename = "${path.module}/Dockerrun.aws.json"
}

# Compress the docker run config file
# Refer to data referenece setup

# Create s3 bucket to store docker run config
resource "aws_s3_bucket" "docker_run_bucket" {
  bucket = "docker-run-bucket"
  tags   = local.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption" {
  bucket = aws_s3_bucket.docker_run_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.docker_run_bucket.id
  acl    = "private"
}

# Create s3 object from the compressed docker run config

resource "aws_s3_object" "docker_run_object" {
  key    = "${local.docker_run_config_sha}.zip"
  bucket = aws_s3_bucket.docker_run_bucket.id
  source = data.archive_file.docker_run.output_path
  tags   = local.tags
}

# Create instance profile
resource "aws_iam_instance_profile" "ec2_eb_profile" {
  name = "ec2-profile"
  role = aws_iam_role.ec2_role.name
  tags = local.tags
}

resource "aws_iam_role" "ec2_role" {
  name               = "ec2-role"
  assume_role_policy = data.aws_iam_policy_document.assume_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier",
    "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker",
    "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier",
    "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
  ]

  inline_policy {
    name   = "eb-application-permissions"
    policy = data.aws_iam_policy_document.permissions.json
  }
  tags = local.tags
}

# Create eb app
resource "aws_elastic_beanstalk_application" "eb_app" {
  name        = "tic-tac-toe-app"
  description = "tic-tac-toe-app beanstalk deployment"
  tags        = local.tags
}

# Create eb version
resource "aws_elastic_beanstalk_application_version" "eb_version" {
  name        = local.docker_run_config_sha
  application = aws_elastic_beanstalk_application.eb_app.name
  description = "application version created by terraform"
  bucket      = aws_s3_bucket.docker_run_bucket.id
  key         = aws_s3_object.docker_run_object.id
  tags        = local.tags
}

# Create eb environment
resource "aws_elastic_beanstalk_environment" "eb_env" {
  name          = "eb-env"
  application   = aws_elastic_beanstalk_application.eb_app.name
  platform_arn  = "arn:aws:elasticbeanstalk:us-east-1::platform/Multi-container Docker running on 64bit Amazon Linux/2.26.4" # potential error
  version_label = aws_elastic_beanstalk_application_version.eb_version.name
  cname_prefix  = "tic-tac-toe-app"
  tags          = local.tags

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.ec2_eb_profile.name
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.instance_type
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = var.max_instance_count
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBScheme"
    value     = "internet facing"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "MatcherHTTPCode"
    value     = 200
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckPath"
    value     = "/docs"
  }

  dynamic "setting" {
    for_each = var.environment_variables_map
    content {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = setting.key
      value     = setting.value
    }
  }
}