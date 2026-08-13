# Amazon Microservices Terraform

Creates:

- VPC
- 3 public subnets
- 3 private subnets
- Internet Gateway
- 3 NAT Gateways
- IAM roles for EKS cluster and worker nodes
- EBS CSI Pod Identity role
- EKS cluster
- EKS managed node group
- EKS Pod Identity Agent
- VPC CNI
- CoreDNS
- kube-proxy
- AWS EBS CSI driver
- EKS Access Entry for the IAM principal in `admin_principal_arn`
- 15 ECR repositories

## Important

The IAM user in `admin_principal_arn` must exist already:

`arn:aws:iam::047385030300:user/Zeshan`

This Terraform configuration does not create that IAM user.

## Deploy

```powershell
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

## Configure kubectl

After the cluster is created:

```powershell
aws eks update-kubeconfig --region us-east-1 --name microservices-dev-eks
kubectl get nodes
kubectl get pods -A
```

## ECR login

```powershell
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
```

## Notes

- The private EKS nodes use the NAT gateways for outbound AWS/internet access.
- Three NAT gateways are created, one per AZ, for better availability but higher cost.
- `force_delete = false` is used for ECR repositories to avoid accidental deletion.
- `AmazonEKSClusterAdminPolicy` grants full Kubernetes cluster administration to the configured principal.
