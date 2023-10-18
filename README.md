# Supermarket Checkout Deployment

## Description
The following scripts ensure the build and deployment of the latest JAR for the Supermarket Checkout project. Place these files in parallel to the code directory with `pom.xml` and `src` folders.

## Prerequisite
1. This code assumes the existence of an Amazon Elastic Container Registry (ECR) named `testsupermarket-checkout`, where the latest JAR will be pushed.
2. The domain of the website is assumed to be `testsupermarket.kredmint.com`.
3. Replace the string `xxxxxxxxxx` with the AWS account ID.

## Code Files
1. **Dockerfile**
2. **buildDockerImage.sh**
3. **terraform/main.tf**

## Steps for Deployment
To deploy the latest JAR, we need to run the script `buildAnd DeployDockerImage.sh` 

Below are the stages of the script:
1. **buildJar** : 
    Builds the JAR using the `mvn clean install` command.
2. **buildDockerImage** :
    Creates a Docker image with the name supermarket-checkout using the committed Dockerfile.
3. **pushDockerImage** : 
    Tags the Docker image with respect to the AWS ECR and then pushes it.
4. **deployApplication** :
    Now once our latest image is pushed to AWS ECR, we will deploy our application stack using the Terraform script.

## Resources Created By Terraform
The Terraform script will create an AWS ECS cluster, AWS ECS Fargate Task Definition, AWS ECS Fargate service, AWS private ALB, its respective target group, and a CloudFront distribution.

## Screen Shot Of the Deployed Application

<img width="1436" alt="Screenshot 2023-10-18 at 7 41 18 AM" src="https://github.com/pundir09/supermarket-checkout/assets/63442618/40b304af-cfb8-43fc-8fb1-9f28fb4afdca">

