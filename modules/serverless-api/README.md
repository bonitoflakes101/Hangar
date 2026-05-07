# serverless-api

A Lambda function exposed through an API Gateway **HTTP API** (the v2, cheaper, simpler successor to the original REST API). Use this for JSON APIs, webhooks, and event-driven services that should scale to zero when idle and you do not want to pay for a load balancer or always-on server.

If you do not provide your own zipped code, the module ships a tiny "Hello from Lambda" Node.js handler so you can verify the whole wiring end to end before plugging in your real app.

## Architecture

```
                Internet
                   │
                   ▼
       ┌──────────────────────┐
       │ API Gateway HTTP API │   ← https://<id>.execute-api.<region>.amazonaws.com
       │  - $default stage    │
       │  - ANY / and /{*}    │
       └──────────┬───────────┘
                  │  AWS_PROXY (payload v2)
                  ▼
       ┌──────────────────────┐
       │   Lambda function    │
       │   - Node.js 20.x     │
       │   - basic exec role  │
       └──────────┬───────────┘
                  ▼
        CloudWatch Logs
        (/aws/lambda/<name>)
```

## Usage

```hcl
module "api" {
  source = "../../modules/serverless-api"

  name = "my-api"

  # Optional — drop in your own zip:
  # lambda_zip_path = "${path.module}/dist/lambda.zip"
  # handler         = "app.handler"
  # runtime         = "nodejs20.x"

  environment_variables = {
    STAGE = "dev"
  }

  tags = { Project = "my-api" }
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| name | string | — | Name prefix for all resources. |
| lambda_zip_path | string | `null` | Path to your .zip code. If null, a built-in demo handler is used. |
| handler | string | `"index.handler"` | Lambda handler (`<file>.<export>`). |
| runtime | string | `"nodejs20.x"` | Lambda runtime. |
| memory_size | number | `128` | Memory in MB. |
| timeout | number | `10` | Timeout in seconds. |
| environment_variables | map(string) | `{}` | Env vars on the function. |
| cors_allow_origins | list(string) | `["*"]` | Origins allowed by CORS. |
| log_retention_days | number | `7` | CloudWatch log retention. |
| tags | map(string) | `{}` | Tags applied to all resources. |

## Outputs

| Name | Description |
|---|---|
| lambda_function_name | Lambda function name. |
| lambda_function_arn | Lambda function ARN. |
| lambda_role_arn | IAM execution role ARN. |
| log_group_name | CloudWatch log group. |
| api_id | API Gateway ID. |
| api_endpoint | Base URL — `curl` this to test. |
| api_arn | API Gateway ARN. |

## How to deploy and test this

### 1. Prerequisites check

```sh
terraform -version
aws --version
aws sts get-caller-identity
```

### 2. Edit the example

```sh
cd examples/serverless-api
```

Open `main.tf`. Change `name` if you want to namespace resources. The default uses the bundled hello-world Lambda — you do not need to provide any code yet.

### 3. Init, plan, apply

```sh
terraform init
terraform plan
terraform apply       # type: yes
```

Apply takes ~30–60 seconds. Lambda + API Gateway are fast.

### 4. Verify

```sh
URL=$(terraform output -raw api_endpoint)

curl $URL
# => {"message":"Hello from Lambda!","path":"/","method":"GET","time":"..."}

curl $URL/anything/here
# => {"message":"Hello from Lambda!","path":"/anything/here",...}
```

To watch logs while invoking:

```sh
LOG_GROUP=$(terraform output -raw log_group_name)
aws logs tail $LOG_GROUP --follow
```

### 5. Destroy

```sh
terraform destroy     # type: yes
```

Destroy takes ~30 seconds.

## Cost warning

| Service | Free tier? | Approx cost if left running 24h |
|---|---|---|
| Lambda | 1M requests + 400k GB-s/month free **forever** | $0 at hobby traffic |
| API Gateway HTTP API | 1M requests/month free for 12 months, then $1.00 per million | $0 at hobby traffic |
| CloudWatch Logs | 5 GB/mo free for 12 months | ~$0 |

Idle, this stack costs **$0**. You only pay per request. It is the safest architecture in this repo to leave running by accident — but still destroy it when finished, to keep your account tidy.
