resource "aws_api_gateway_rest_api_policy" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : "execute-api:Invoke",
        "Resource" : "arn:aws:execute-api:eu-west-1:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.this.id}/*/*/*"
      }
    ],
  })
}

resource "aws_api_gateway_rest_api" "this" {
  name        = "${local.resource_prefix}-api"
  description = "Allows access to the Metadata service RDS instance"

  endpoint_configuration {
    types = ["EDGE"]
  }

  tags = {
    Metaflow = "true"
  }
}

resource "aws_api_gateway_resource" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_resource" "db" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "db_schema_status"
}

resource "aws_api_gateway_vpc_link" "this" {
  name        = "${local.resource_prefix}-vpclink"
  target_arns = [aws_lb.this.arn]

  tags = {
    Metaflow = "true"
  }
}

resource "aws_api_gateway_method" "this" {
  http_method      = "ANY"
  resource_id      = aws_api_gateway_resource.this.id
  rest_api_id      = aws_api_gateway_rest_api.this.id
  authorization    = "NONE"
  api_key_required = false

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_method" "db" {
  http_method      = "GET"
  resource_id      = aws_api_gateway_resource.db.id
  rest_api_id      = aws_api_gateway_rest_api.this.id
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_integration_response" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.this.id
  http_method = aws_api_gateway_method.this.http_method
  status_code = 200
  depends_on  = [aws_api_gateway_integration.this]
}

resource "aws_api_gateway_integration" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.this.id
  http_method = aws_api_gateway_method.this.http_method

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }

  type                    = "HTTP_PROXY"
  uri                     = "http://${aws_lb.this.dns_name}/{proxy}"
  integration_http_method = "ANY"
  passthrough_behavior    = "WHEN_NO_MATCH"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.this.id
}

resource "aws_api_gateway_integration" "db" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.db.id
  http_method = aws_api_gateway_method.db.http_method


  type                    = "HTTP_PROXY"
  uri                     = "http://${aws_lb.this.dns_name}:8082/db_schema_status"
  integration_http_method = "GET"
  passthrough_behavior    = "WHEN_NO_MATCH"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.this.id
}

resource "aws_api_gateway_method_response" "this" {

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.this.id
  http_method = aws_api_gateway_method.this.http_method
  status_code = "200"
  depends_on  = [aws_api_gateway_integration.this]
}

resource "aws_api_gateway_method_response" "db" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.db.id
  http_method = aws_api_gateway_method.db.http_method
  status_code = "200"
  depends_on  = [aws_api_gateway_integration.db]
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  # explicit depends_on required to ensure module stands up on first `apply`
  # otherwise a second followup `apply` would be required
  # can read more here: https://stackoverflow.com/a/42783769
  depends_on = [
    aws_api_gateway_method.this,
    aws_api_gateway_integration.this,
    aws_api_gateway_method.db,
    aws_api_gateway_integration.db
  ]

  # ensures properly ordered re-deployments occur
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = "api"

  tags = {
    Metaflow = "true"
  }
}
