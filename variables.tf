variable "bucket_name" {
  type        = string
  description = "S3 bucket name"
}

variable "domain_name" {
  type        = string
  description = "Website domain name"
}

variable "endpoint" {
  type        = string
  description = "endpoint url"
}

variable "table_name" {
  type        = string
  description = "DynamoDB Table Name"
}


variable "hash_key" {
  type        = string
  description = "DynamoDB hash_key"
}

variable "type" {
  type        = string
  description = "DynamoDB attribute type (S, N, etc.)"
}

variable "lambda_name" {
  type        = string
  description = "Lambda Function Name"
}

variable "repo" {
  type        = string
  description = "AWS ECR repo for lambda function"
}

variable "header" {
  type        = string
  description = "website address for CORS"
}

variable "api_name" {
  type        = string
  description = "API Gateway name"
}