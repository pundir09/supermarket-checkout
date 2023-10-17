#!/bin/bash
set -e
buildJar(){
	echo "Running 'mvn clean install'..."
	mvn clean install
}
buildDockerImage(){
	echo "Building Docker image..."
	docker build -t supermarket-checkout -f Dockerfile .
	echo "Docker Image created successfully!"
}
pushDockerImage(){
	echo "Logging into ECR"
	aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin xxxxxxxxxx.dkr.ecr.ap-south-1.amazonaws.com
	echo "Pushing Docker Image To ECR"
	docker tag supermarket-checkout:latest xxxxxxxxxx.dkr.ecr.ap-south-1.amazonaws.com/testkred-checkout:latest
	docker push xxxxxxxxxx.dkr.ecr.ap-south-1.amazonaws.com/testkred-checkout:latest
}
deployApplication(){
	echo "Deploying application stack"
	cd terraform
	terraform init
	terraform apply -auto-approve
}
buildJar
buildDockerImage
pushDockerImage
deployApplication
