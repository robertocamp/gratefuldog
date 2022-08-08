# golang web app

## packages
- Go programs are organized into packages. 
- A package is a collection of source files in the same directory that are compiled together. 
- Functions, types, variables, and constants defined in one source file are visible to all other source files within the same package.

## modules
- A repository contains one or more modulesA module is a collection of related Go packages that are released together. 
- A Go repository typically contains only one module, located at the root of the repository. 
- A file named go.mod there declares the module path: the import path prefix for all packages within the module. 
- The module contains the packages in the directory containing its go.mod file as well as subdirectories of that directory, up to the next subdirectory containing another go.mod file (if any)


## Docker
- example Dockerfile
```
FROM golang:1.18

WORKDIR /usr/src/app

# pre-copy/cache go.mod for pre-downloading dependencies and only redownloading them in subsequent builds if they change
COPY go.mod go.sum ./
RUN go mod download && go mod verify

COPY . .
RUN go build -v -o /usr/local/bin/app ./...

CMD ["app"]
```
### Docker build and run local
#### local build
- `docker build -t gratefuldog-v001 .`
- `docker run -p 3000:3000  gratefuldog-v002`
#### deployment build:
- `docker build -t grateful-dog-eks:001 .`


## ECR
### create container repository
- Now that we have an image to push to Amazon ECR, we must create a repository to hold it
- create a repository called `gratefuldog` to which you later push the `grateful-dog-eks:001` image
```
aws ecr create-repository \
    --repository-name gratefuldog \
    --image-scanning-configuration scanOnPush=true \
    --region us-east-2
```
- record the output:
```
{
    "repository": {
        "repositoryArn": "arn:aws:ecr:us-east-2:240195868935:repository/gratefuldog",
        "registryId": "240195868935",
        "repositoryName": "gratefuldog",
        "repositoryUri": "240195868935.dkr.ecr.us-east-2.amazonaws.com/gratefuldog",
        "createdAt": "2022-08-07T19:29:37-05:00",
        "imageTagMutability": "MUTABLE",
        "imageScanningConfiguration": {
            "scanOnPush": true
        },
        "encryptionConfiguration": {
            "encryptionType": "AES256"
        }
    }
}
```
### authenticate Docker to the ECR registry we just created
- the docker command needs to authenticate before it can push and pull images with Amazon ECR
- The `get-login-password` is the preferred method for authenticating to an Amazon ECR private registry when using the AWS CLI
- Use the following command to view your user ID, account ID, and your user ARN: `aws sts get-caller-identity`
- syntax for `get-login-password`: `aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.<region>.amazonaws.com`
  + you should get: "Login Succeeded"
### tag and push Docker image
- **TAG:** `docker tag <local-image:tag> <accountID>.dkr.ecr.<region>.amazonaws.com/<local-image:tag>`
- **PUSH:** docker push <accountID>.dkr.ecr.<region>.amazonaws.com/<local-image:tag>
- **IMPORTANT** THE IMAGE NAME MUST MATCH THE NAME OF THE ECR REPOSITORY
  + `docker tag gratefuldog:001 240195868935.dkr.ecr.us-east-2.amazonaws.com/gratefuldog:001`
  + `docker push  240195868935.dkr.ecr.us-east-2.amazonaws.com/gratefuldog:001`


## links
- https://docs.gofiber.io/
- https://github.com/golang-standards/project-layout
- https://www.bogotobogo.com/index.php