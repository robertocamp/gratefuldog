1. have your sts info handy:
```
{
    "UserId": "AIDATP3GKDEDUSV4NBFRB",
    "Account": "240195868935",
    "Arn": "arn:aws:iam::240195868935:user/robertc"
}
```

2. get the cluster name: `aws eks list-clusters`
- output
```
{
    "clusters": [
        "gratefuldog-dev-terraform-cluster"
    ]
}
```

3. get the  cluster's OIDC provider URL:
```
aws eks describe-cluster \
  --name gratefuldog-dev-terraform-cluster \
  --query "cluster.identity.oidc.issuer" \
  --output text
```
- https://oidc.eks.us-east-2.amazonaws.com/id/41117CDDF9D73604B31CC3A911FDE844

4. update the json policy file: docs/aws-ebs-csi-driver-trust-policy.json
5. create the role:

```
aws iam create-role \
  --role-name AmazonEKS_EBS_CSI_DriverRole \
  --assume-role-policy-document file://"aws-ebs-csi-driver-trust-policy.json"
```
- output:
```
{
    "Role": {
        "Path": "/",
        "RoleName": "AmazonEKS_EBS_CSI_DriverRole",
        "RoleId": "AROATP3GKDEDYBUELQN3N",
        "Arn": "arn:aws:iam::240195868935:role/AmazonEKS_EBS_CSI_DriverRole",
        "CreateDate": "2022-08-09T18:57:02+00:00",
        "AssumeRolePolicyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "Federated": "arn:aws:iam::240195868935:oidc-provider/oidc.eks.us-east-2.amazonaws.com/id/41117CDDF9D73604B31CC3A911FDE844"
                    },
                    "Action": "sts:AssumeRoleWithWebIdentity",
                    "Condition": {
                        "StringEquals": {
                            "oidc.eks.us-east-2.amazonaws.com/id/41117CDDF9D73604B31CC3A911FDE844:aud": "sts.amazonaws.com",
                            "oidc.eks.us-east-2.amazonaws.com/id/41117CDDF9D73604B31CC3A911FDE844:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
                        }
                    }
                }
            ]
        }
    }
}
```

6. Attach the required AWS managed policy to the role:

```
aws iam attach-role-policy \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --role-name AmazonEKS_EBS_CSI_DriverRole
```

7. create the add-on:
```
aws eks create-addon \
  --cluster-name gratefuldog-dev-terraform-cluster \
  --addon-name aws-ebs-csi-driver \
  --service-account-role-arn arn:aws:iam::240195868935:role/AmazonEKS_EBS_CSI_DriverRole
```

{
    "addon": {
        "addonName": "aws-ebs-csi-driver",
        "clusterName": "gratefuldog-dev-terraform-cluster",
        "status": "CREATING",
        "addonVersion": "v1.10.0-eksbuild.1",
        "health": {
            "issues": []
        },
        "addonArn": "arn:aws:eks:us-east-2:240195868935:addon/gratefuldog-dev-terraform-cluster/aws-ebs-csi-driver/16c14203-3f1e-2be1-6203-212eb356bc6d",
        "createdAt": "2022-08-09T14:13:14.437000-05:00",
        "modifiedAt": "2022-08-09T14:13:14.459000-05:00",
        "serviceAccountRoleArn": "arn:aws:iam::240195868935:role/AmazonEKS_EBS_CSI_DriverRole",
        "tags": {}
    }
}

8. VERIFICATION COMMANDS:
`aws eks list-addons --cluster-name gratefuldog-dev-terraform-cluster`
aws eks describe-addon \
  --cluster-name gratefuldog-dev-terraform-cluster \
  --addon-name aws-ebs-csi-driver \
  --query "addon.addonVersion" \
  --output text
- example output: `v1.10.0-eksbuild.1`

## links
https://docs.aws.amazon.com/eks/latest/userguide/csi-iam-role.html
https://docs.aws.amazon.com/eks/latest/userguide/managing-ebs-csi.html