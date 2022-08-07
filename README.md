# gratefuldog

## Overview
### KMS key
- KMS is replacing the term customer master key (CMK) with KMS key and KMS key
- *If you need a key for basic encryption and decryption or you are creating a KMS key to protect your resources in an Amazon Web Services service, create a symmetric encryption KMS key*
- The concept has not changed. To prevent breaking changes, KMS is keeping some variations of this term
- To create a symmetric encryption KMS key, you aren’t required to specify any parameters. 
- The default value for `KeySpec` , `SYMMETRIC_DEFAULT` , and the default value for `KeyUsage` , `ENCRYPT_DECRYPT` , create a symmetric encryption KMS key
- The key material in a symmetric encryption key never leaves KMS unencrypted. 
- You can use a symmetric encryption KMS key to encrypt and decrypt data up to 4,096 bytes, but they are typically used to generate data keys and data keys pairs

### Cluster Deployment
1. copy files from: https://github.com/cloudposse/terraform-aws-eks-cluster/tree/master/examples/complete into current project
2. update main.tf to pull eks module from remote src:

```
module "eks_cluster" {
  source  = "cloudposse/eks-cluster/aws"
  version = "2.3.2"
  # insert the 3 required variables here
}
```

3. create key
```
aws kms create-key \
    --tags TagKey=Purpose,TagValue=gratefuldog \
    --description "eks symetric kms key"
```
- returns
{
    "KeyMetadata": {
        "AWSAccountId": "240195868935",
        "KeyId": "a1a1cd3b-19ac-4727-9887-22acaafa561b",
        "Arn": "arn:aws:kms:us-east-2:240195868935:key/a1a1cd3b-19ac-4727-9887-22acaafa561b",
        "CreationDate": "2022-08-06T19:54:02.171000-05:00",
        "Enabled": true,
        "Description": "eks symetric kms key",
        "KeyUsage": "ENCRYPT_DECRYPT",
        "KeyState": "Enabled",
        "Origin": "AWS_KMS",
        "KeyManager": "CUSTOMER",
        "CustomerMasterKeySpec": "SYMMETRIC_DEFAULT",
        "KeySpec": "SYMMETRIC_DEFAULT",
        "EncryptionAlgorithms": [
            "SYMMETRIC_DEFAULT"
        ],
        "MultiRegion": false
    }
}
4. export the key as a local env var that Terraform will pick up: `export TF_VAR_cluster_encryption_config_kms_key_id=arn:aws:kms:us-east-2:240195868935:key/a1a1cd3b-19ac-4727-9887-22acaafa561b`
5. create `eks/terraform.tfvars` and create variable values for anything in variables.tf that will deviate from the defaults
6. `plan: terraform plan -no-color > plans/gratefuldog-initial-eks-7-aug-2022`
7. once this plan has been vetted , add the ALB module to complete the initial cluster build:
```
module "alb" {
  source  = "cloudposse/alb/aws"
  version = "1.4.0"
  # insert the 20 required variables here
}
```
  - many of the vars that alb requires will have already been defined in the eks design
  - copy the variables.tf from the alb source code into the project's variables.tf file and comment out any duplicates that are already active
  - add sensible defaults to `variables.tf` , for ALB, with the plan to add customizations to `terraform.tfvars` at a later date
    + use the values at https://github.com/cloudposse/terraform-aws-alb/blob/master/examples/complete/fixtures.us-east-2.tfvars for reference
8. `terraform apply`
- capture the relavant output
```
Apply complete! Resources: 9 added, 0 changed, 0 destroyed.

Outputs:

eks_cluster_arn = "arn:aws:eks:us-east-2:240195868935:cluster/gratefuldog-dev-gratefuldog-tf-cluster"
eks_cluster_endpoint = "https://6AD74395FBFDAC7F5A3C207BD4EAAC2C.gr7.us-east-2.eks.amazonaws.com"
eks_cluster_id = "gratefuldog-dev-gratefuldog-tf-cluster"
eks_cluster_identity_oidc_issuer = "https://oidc.eks.us-east-2.amazonaws.com/id/6AD74395FBFDAC7F5A3C207BD4EAAC2C"
eks_cluster_managed_security_group_id = "sg-0379141a7d95f742a"
eks_cluster_version = "1.22"
eks_node_group_arn = "arn:aws:eks:us-east-2:240195868935:nodegroup/gratefuldog-dev-gratefuldog-tf-cluster/gratefuldog-dev-gratefuldog-tf-workers/06c13cb0-0908-91fe-171c-4fee95c89b23"
eks_node_group_id = "gratefuldog-dev-gratefuldog-tf-cluster:gratefuldog-dev-gratefuldog-tf-workers"
eks_node_group_resources = tolist([
  tolist([
    {
      "autoscaling_groups" = tolist([
        {
          "name" = "eks-gratefuldog-dev-gratefuldog-tf-workers-06c13cb0-0908-91fe-171c-4fee95c89b23"
        },
      ])
      "remote_access_security_group_id" = ""
    },
  ]),
])
eks_node_group_role_arn = "arn:aws:iam::240195868935:role/gratefuldog-dev-gratefuldog-tf-workers"
eks_node_group_role_name = "gratefuldog-dev-gratefuldog-tf-workers"
eks_node_group_status = "ACTIVE"
private_subnet_cidrs = tolist([
  "172.16.0.0/19",
  "172.16.32.0/19",
])
public_subnet_cidrs = tolist([
  "172.16.96.0/19",
  "172.16.128.0/19",
])
vpc_cidr = "172.16.0.0/16"
```


## cluster checkout

1. update kubectl with new cluster id: `aws eks update-kubeconfig --region us-east-2 --name gratefuldog-dev-gratefuldog-tf-cluster`
2. `kubectl version -o json`
 + validate "client" and "server" version are expected
3. `kubectl get namespaces`
```
NAME              STATUS   AGE
default           Active   18m
kube-node-lease   Active   18m
kube-public       Active   18m
kube-system       Active   18m
```
4. `aws cloudtrail lookup-events --region us-east-2 --lookup-attributes AttributeKey=EventName,AttributeValue=CreateCluster`
  + this shoudl indicate the user who created the cluster and the user who will be deploying the kubernetes manifiests for app deployments
5. test the cluster endpoint in a browser:  https://6AD74395FBFDAC7F5A3C207BD4EAAC2C.gr7.us-east-2.eks.amazonaws.com
- you should see message like this:

```
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {
    
  },
  "status": "Failure",
  "message": "forbidden: User \"system:anonymous\" cannot get path \"/\"",
  "reason": "Forbidden",
  "details": {
    
  },
  "code": 403
}
```

## issues
1. `terraform init` gives this error:

```
Initializing modules...
There are some problems with the configuration, described below.

The Terraform configuration must be valid before initialization so that
Terraform can determine which modules and providers need to be installed.
╷
│ Error: Unsupported block type
│ 
│   on .terraform/modules/subnets/moved.tf line 3:
│    3: moved {
│ 
│ Blocks of type "moved" are not expected here.
```
> **solution:** `brew upgrade terraform`

2. `terraform plan` gives this error:
```
  eks git:(eks-cluster-with-alb) ✗ terraform plan
╷
│ Error: Reference to undeclared module
│ 
│   on main.tf line 107, in module "eks_node_group":
│  107:   cluster_name      = module.eks_cluster.eks_cluster_id
│ 
│ No module call named "eks_cluster" is declared in the root module. Did you mean "eks-cluster"?
```

> **solution:** there appears to be typo in main.tf:  search and replace eks_cluster/eks-cluster
