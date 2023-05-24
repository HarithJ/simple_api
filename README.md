# Simple API

This repository contains a simple API that provides two endpoints for retrieving information. The first endpoint displays the current timestamp in Unix format, while the second endpoint generates a list of 10 random numbers within the range of 0 to 5.

## Running the Application Locally

To run the application on your local machine, follow these steps:

1. Build the Docker image by executing the following command:

```
docker build -t simple-api .
```

Alternatively, you can directly pull the image from the public registry using this command:

```
docker pull harithj/simple-api
```

2. Start the application by running the Docker container. If you built the image locally, use this command:

```
docker run -p 8080:80 simple-api
```

If you pulled the image from the public registry, use this command instead:

```
docker run -p 8080:80 harithj/simple-api
```

3. You can now access the application in your web browser by visiting `localhost:8080`.

## Accessing the Endpoints

The application exposes two endpoints:

1. **/time**: This endpoint returns the current Unix timestamp.

2. **/random**: This endpoint generates a list of 10 random numbers within the range of 0 to 5.

Feel free to use these endpoints to retrieve the desired information from the API.


## Deploying Application

We have created Terraform files under the terraform folder to help with the deployment. The terraform files will deploy the application to AWS ECS using Fargate.

### Prerequisite

You will need Terraform CLI installed, an AWS account, and you will need to authorize Terraform to communicate with your AWS account. There are two ways to authorize Terraform:

1. **By using Environment Variables**: You can set two environment variables, `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`, and the AWS provider in Terraform will automatically use these.

2. **By using Shared Credentials file**: If you've installed and configured the AWS CLI, it will have created a file at `~/.aws/credentials` (on Unix systems) or `%UserProfile%\.aws\credentials` (on Windows) that stores your credentials. The AWS provider will automatically use this file.

### Downloading AWS Provider

Before you move on to deploying the application, you will need to download the AWS provider which Terraform will use to communicate with AWS. You can do this by running `terraform init` in the **terraform folder**.

### Deploying

While making sure you are in the **terraform folder** run:

```
terraform plan -out="tfplan"
```

This will display what resources will be created when the configuration is applied. After you have confirmed what resources will be created, you can go ahead and actually create the infrastructure:

```
terraform apply "tfplan"
```

This step will likely take a few minutes. After it has done creating the infrastructure, it will print out the Load Balancer's URL, copy it and ppaste it in your browser to access the application.

### Scaling the application

To scale the application, we can specify the number of application instances we need through the `app_count` varible:

```
terraform plan -var app_count=3 -out=tfplan
terraform apply "tfplan".
```
