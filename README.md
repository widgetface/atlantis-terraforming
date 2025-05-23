# atlantis-terraforming
A project to look into atlantis and terraform

### Steps
## 1. Create an EC2 instance
Log in to AWS Console and navigate to EC2.
Click Launch Instance and choose Amazon Linux 3 as the AMI.
Select an Instance Type (e.g., t2.micro or higher).
Configure Security Group to allow inbound traffic on:
SSH (22)
Atlantis (4000)

ec2 instance needs a role with
DynamoDB access to the lock table 
AmazonEC2FullAccess 
AmazonS3FullAccess (probably just create buckets here)
Access the statefile bucket a policy like
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "TerraformS3Access",
			"Effect": "Allow",
			"Action": [
				"s3:GetObject",
				"s3:PutObject",
				"s3:DeleteObject",
				"s3:ListBucket",
				"s3:GetBucketLocation"
			],
			"Resource": [
				"arn:aws:s3:::<statefile-bucket>",
				"arn:aws:s3:::<statefile-bucket>/*"
			]
		}
	]
}

Add useful tags, such as 
environment, purpose, description, project, cost-center, back-up (true), delete (false), versioning (enabled), data-type (terraform state)

Next, you need a key pair for SSH access
In EC2 instance -> Launch the instance and download the key pair for SSH access.
Download the pem file
Put it in the root of the folder your going to use to SSH into your ec2 instance
Note:
If you have trouble SSH'ing in , check the .pem file is in the directory your SSHing from

## 2. Generate a Github Token
You need a GitHub token
Go to your profile image -> settings -> developer settings -> personal 
access tokens -> classic
Generate a  token.
You'll use this when running the Atlantis image

## 3. Install Atlantis on the EC2 instance
SSH into your EC2 instance
Go to the running instance -> connect -> SSH client
Copy the command (should be like ssh -i your-key.pem ec2-user@your-ec2-public-ip)
Note 


Install docker
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker

Check docker installed
docker --version

create a docker file as below
sudo nano Dockerfile

FROM ghcr.io/runatlantis/atlantis:latest

USER root
RUN apk add --no-cache aws-cli

# Ensure the 'atlantis' user exists before changing ownership
RUN id atlantis || adduser -D atlantis

RUN mkdir -p /home/atlantis/.aws
RUN touch /home/atlantis/.aws/credentials

RUN chown -R atlantis:atlantis /home/atlantis/

USER atlantis


Then
docker build -t atlantis .

Then
docker run -itd -p 4000:4141 --name atlantis atlantis server --automerge --autoplan-modules --gh-user=<github-account-username> --gh-token=<github-usr-access-token> --repo-allowlist=<list of allowed repos>

So your Atlantis is running inside a Docker container
You can open an interactive session within the running container
docker exec -it <container_id_or_name> sh

## 4. Set up a GitHub webhook
Get the  Public IPv4 address of the running instance 
Open your GitHub repository that contains your Terraform code.
Go to Settings → Webhooks.
Click Add webhook.
Set the Payload URL to:
http://Public IPv4 address:4000/events

# REMEMBER IF YOU stop the instance you'll have to edit this url

Set Content type to application/json.

Select Let me select individual events and check the following options:
Issue comments
Pull request reviews
Pull requests

Ensure that Active is checked.

## 5. Create a user in Identity center
To avoid having long lived access keys on your local machine
You need to create a user in Identity Center

Add permission sets - what the user can do 
Add accounts

The user receives an email with:

A login link

A temporary password

They can log in and set a new password.
Enable MFA for users in IAM Identity Center.

Once logged in, they’ll see the AWS account(s) and roles they’ve been assigned.

## 6. Create an sso login pofile on your local machine
In VSCODE terminal
AS CLI V2 installed
Terraorm installed
do the commands 
 
aws configure sso
fill in prompts for SSO start URL (from Identity Center) and Region (e.g., us-west-2)
Anything else just press enter EXCEPT add a useful profile name
Then next time you can use
aws sso login --profile <your-profile-name>

Check you can do something like 
aws sts get-caller-identity --profile <your-profile-name>

Now you can run aws cli instructions into the account

## 7. Terraform
Use an approach to bootstrap (in the account with the EC2 instance running)
S3 state file bucket
DynamoDB table for locking

Set up the backend  and provider
provider "aws" {
  region = "your-region"
}

and a backend
terraform {
  backend "s3" {
    bucket         = "sdds-terraform-state-bucket"
    key            = "envs/dev/terraform.tfstate"  # Adjust path if needed
    region         = "region"
    dynamodb_table = "terraform-locks"             # Optional but recommended
    encrypt        = true
  }
}
# Make Teraform aware of your profile
# export AWS_PROFILE=dev-sso

Now you should be able to plan locally
Run terraform init locally

Create a branch
write some Iac
Commit
Create pull request
You should see Atlantis planning your Iac
If it fails -> SSH into your EC2 -> if it failed on plan use
docker logs <container-name> 2>&1 | grep "plan"
This will highlight where plan is appearing and you should be able to track down an error , 
e.g. not having permissions to access the DynamoDB lock table etc

If plan OK 
Comment 
"atlantis apply"

You should see apply kick off


### Multi account setup
To use **Atlantis on an EC2 instance in one AWS account** to deploy Terraform-managed infrastructure to a **separate AWS account**, you need to configure **cross-account IAM access**. This is a common pattern for centralized CI/CD pipelines.

---

## ✅ Overview of the Approach

Atlantis must assume a **role in the target AWS account** using AWS STS. The process typically works like this:

1. Atlantis runs in **Account A** (on EC2)
2. Terraform deploys infrastructure in **Account B**
3. Atlantis uses an **IAM role in Account B** via `assume_role` in Terraform or AWS CLI

---

## 🔐 Prerequisites

* Atlantis is set up and running in EC2 (Account A)
* You have **IAM permissions** to create roles in both Account A and B
* Terraform is using an AWS provider block that allows assuming roles

---

## 🧱 Step-by-Step Guide

### ### 1. 🛡 Create IAM Role in **Target Account (Account B)**

This role is what Terraform (via Atlantis) will assume.

**In Account B:**

Create an IAM role named (e.g.) `AtlantisDeployRole` with:

* **Trust policy** allowing Atlantis’s EC2 instance role from Account A to assume it.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::<ACCOUNT_A_ID>:role/AtlantisEC2Role"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

* **Permissions policy** granting access to resources in Account B (e.g., S3, VPC, etc.)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
```

> 🔐 Scope this down to only what’s needed.

---

### 2. 🤖 Add `assume_role` block to Terraform AWS Provider

In your **Terraform code** (used by Atlantis):

```hcl
provider "aws" {
  region  = "us-west-2"
  assume_role {
    role_arn = "arn:aws:iam::<ACCOUNT_B_ID>:role/AtlantisDeployRole"
  }
}
```

This tells Terraform to use the **default credentials** from the EC2 instance (Account A), but then **assume the target role** in Account B.

---

### 3. ✅ Ensure Atlantis EC2 IAM Role (Account A) Has AssumeRole Permission

In Account A, attach a policy to the EC2 instance profile (Atlantis EC2 role):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "arn:aws:iam::<ACCOUNT_B_ID>:role/AtlantisDeployRole"
    }
  ]
}
```

---

### 4. 🔄 Restart or Reload Atlantis (if you changed the EC2 role)

```bash
sudo systemctl restart docker
docker restart atlantis
```

Or however you're managing the container.

---

## ✅ Verification

1. Open a PR in GitHub with Terraform that targets Account B.
2. Check the Atlantis output in the PR and verify:

   * It assumes the correct role
   * It deploys resources in the correct account
3. Run:

```bash
aws sts get-caller-identity
```

Inside the Atlantis container if you need to verify current credentials.

---

## 📦 Optional: Use Terraform Workspaces or Separate Projects

If you're deploying to multiple accounts, structure your repo to have:

```bash
/prod       --> Account B
/staging    --> Account C
```

Then configure Atlantis `atlantis.yaml` to run in those directories with different provider blocks.

---


