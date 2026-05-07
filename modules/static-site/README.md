# static-site

A private S3 bucket served through a CloudFront distribution that uses **Origin Access Control (OAC)** so the bucket is never directly reachable from the internet. Use this for any static site: a Hugo/Jekyll blog, a built React/Vue/Svelte SPA, plain HTML/CSS/JS, or generated documentation.

## Architecture

```
                         ┌──────────────────────┐
   browser  ──── HTTPS ──▶  CloudFront (CDN)   │
                         │  - global edge cache │
                         │  - free TLS cert     │
                         └──────────┬───────────┘
                                    │ signed S3 request
                                    │ (Origin Access Control)
                                    ▼
                         ┌──────────────────────┐
                         │  S3 bucket (private) │
                         │  - no public access  │
                         │  - encrypted at rest │
                         └──────────────────────┘
```

The bucket is **not** public. CloudFront is the only thing that can read it, enforced by a bucket policy that checks `aws:SourceArn`.

## Usage

```hcl
module "site" {
  source = "../../modules/static-site"

  bucket_name = "my-unique-static-site-bucket-20260507"
  spa_mode    = true
  tags        = { Project = "my-site" }
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| bucket_name | string | — | Globally unique S3 bucket name. |
| default_root_object | string | `"index.html"` | Object served when a viewer requests `/`. |
| price_class | string | `"PriceClass_100"` | `PriceClass_100` / `PriceClass_200` / `PriceClass_All`. |
| enable_versioning | bool | `false` | Enable S3 versioning for rollback. |
| spa_mode | bool | `false` | If true, CloudFront returns the root object on 403/404. Use for SPAs. |
| tags | map(string) | `{}` | Tags applied to all resources. |

## Outputs

| Name | Description |
|---|---|
| bucket_id | S3 bucket name. |
| bucket_arn | S3 bucket ARN. |
| bucket_regional_domain_name | Regional S3 domain (used by the origin). |
| cloudfront_distribution_id | CloudFront distribution ID (for invalidations). |
| cloudfront_distribution_arn | CloudFront distribution ARN. |
| cloudfront_domain_name | The `xxxx.cloudfront.net` domain. |
| cloudfront_url | Full `https://...` URL of the site. |

## How to deploy and test this

### 1. Prerequisites check

```sh
terraform -version              # need >= 1.5
aws --version                   # need v2
aws sts get-caller-identity     # confirm you are logged in
```

### 2. Edit the example

```sh
cd examples/static-site
```

Open `main.tf` and change the `bucket_name` to something globally unique — bucket names are shared across **every AWS account in the world**. Add your username and today's date to be safe.

### 3. Init, plan, apply

```sh
terraform init
terraform plan
terraform apply       # type: yes
```

Apply takes ~3–5 minutes — most of that is CloudFront propagating to edge locations.

### 4. Upload a test page and verify

```sh
# Get the bucket name and CloudFront URL from the outputs
BUCKET=$(terraform output -raw bucket_id)
URL=$(terraform output -raw cloudfront_url)

# Create and upload a tiny HTML file
echo "<h1>It works.</h1>" > index.html
aws s3 cp index.html s3://$BUCKET/index.html

# Open the URL — first request may take ~1 minute as CloudFront warms up
echo $URL
curl -L $URL
```

You should see `<h1>It works.</h1>`. The bucket itself is **not** browsable — try `aws s3 ls s3://$BUCKET --no-sign-request` and it will be denied. That is the security feature.

### 5. Destroy

```sh
terraform destroy     # type: yes
```

If destroy complains the bucket is not empty, run `aws s3 rm s3://$BUCKET --recursive` then re-run destroy.

## Cost warning

| Service | Free tier? | Approx cost if left running 24h |
|---|---|---|
| S3 storage | 5 GB free for 12 months | ~$0.00 for a few HTML files |
| S3 requests | 20k GET / 2k PUT free for 12 months | ~$0.00 |
| CloudFront | 1 TB out + 10M requests free for 12 months | ~$0.00 |

This architecture is essentially **free at hobby traffic levels**, even outside the free tier — typically pennies per month. Still: run `terraform destroy` when you are done practicing so you do not forget about the bucket entirely.
