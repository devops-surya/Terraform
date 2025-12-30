# EKS Cluster Terraform Configuration

This Terraform configuration deploys a production-grade AWS EKS cluster with VPC, subnets, node groups, and implements least privilege IAM policies.

## Architecture Overview

```
VPC (10.0.0.0/16)
├── Public Subnets (3 AZs)
│   ├── Internet Gateway
│   └── NAT Gateways (1 per AZ)
├── Private Subnets (3 AZs)
│   └── EKS Nodes (auto-scaling)
└── EKS Control Plane
    └── OIDC Provider (IRSA support)
```

## Features

### ✅ Networking
- **Multi-AZ Deployment**: Spans 3 availability zones for high availability
- **Public & Private Subnets**: Public for NAT, private for nodes
- **NAT Gateways**: One per AZ for outbound connectivity
- **Security Groups**: Restrictive rules for cluster and nodes

### ✅ Kubernetes
- **Managed EKS**: AWS-managed control plane
- **CloudWatch Logging**: Audit, API, authenticator logs
- **Auto-scaling**: Cluster and horizontal pod autoscaling ready
- **Latest Kubernetes**: Default 1.29, configurable

### ✅ Security (Least Privilege)
- **IMDSv2 Only**: Enforced instance metadata security
- **Encrypted EBS**: All volumes encrypted by default
- **IRSA (IAM Roles for Service Accounts)**: OIDC federation enabled
- **Minimal IAM Policies**: Only required permissions attached
- **Restricted Public Access**: Configurable API endpoint access
- **VPC CNI Plugin**: For secure pod networking

### ✅ Cost Optimization
- **Spot Instances**: Optional spot node group (50-70% savings)
- **Configurable Scaling**: Adjust min/max nodes
- **EBS Optimization**: GP3 volumes with configurable IOPS/throughput

## File Structure

```
├── provider.tf          # AWS provider and Terraform version
├── vpc.tf               # VPC, subnets, gateways, routing
├── eks.tf               # EKS cluster and security groups
├── iam.tf               # IAM roles and policies (least privilege)
├── node_groups.tf       # On-demand and spot node groups
├── variables.tf         # Input variables with validation
├── outputs.tf           # Cluster outputs and kubectl config
├── terraform.tfvars.example  # Example variable values
└── README.md            # This file
```

## Prerequisites

1. **AWS Account**: With appropriate permissions
2. **Terraform**: >= 1.0
3. **AWS CLI**: For kubeconfig setup
4. **kubectl**: For cluster management

## Deployment Steps

### 1. Clone and Setup

```bash
cd d:\Devops\Handon-practice\Terraform\EKS
```

### 2. Configure Variables

```bash
# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
# Important: Update cluster_endpoint_public_access_cidrs for production
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Plan the Deployment

```bash
terraform plan -out=tfplan
```

Review the plan carefully for any unintended changes.

### 5. Apply Configuration

```bash
terraform apply tfplan
```

This typically takes 10-15 minutes.

### 6. Configure kubectl

```bash
# Get the command from outputs or run manually:
aws eks update-kubeconfig \
  --region us-east-1 \
  --name my-eks-cluster

# Verify connection
kubectl get nodes
kubectl get pods -A
```

## Key Security Features Explained

### IAM Least Privilege

**Cluster Role**: Only permissions for EKS service
```
- eks.amazonaws.com can assume role
- AmazonEKSClusterPolicy attached
- AmazonEKS_CNI_Policy attached
```

**Node Role**: Only what nodes need
```
- ec2.amazonaws.com can assume role
- AmazonEKSWorkerNodePolicy (kubelet, node operations)
- AmazonEKS_CNI_Policy (pod networking)
- AmazonEC2ContainerRegistryReadOnly (ECR pull-only)
- AmazonSSMManagedInstanceCore (Systems Manager access)
- Custom autoscaling policy (tag-based scoping)
```

**IRSA (IAM Roles for Service Accounts)**: Pod-level IAM
```
- OIDC provider for Kubernetes service account federation
- Example: Cluster autoscaler with scoped permissions
- Can be used for monitoring, logging, backup tools
```

### IMDSv2 Enforcement

All EC2 instances require IMDSv2 (token-based access to metadata). This prevents:
- SSRF attacks
- Container escape metadata access
- Unauthorized credential theft

### Network Isolation

- Cluster API in security group with restrictive rules
- Nodes in private subnets without direct internet access
- Pod-to-node communication scoped by CIDR
- Optional: Restrict API public access with `cluster_endpoint_public_access_cidrs`

### Encryption

- EBS volumes encrypted by default (KMS)
- Configurable IOPS/throughput for workload optimization

## Customization

### Use Different Instance Types

```hcl
# For general workloads
node_instance_types = ["m6i.large", "m5.large"]

# For compute-heavy
node_instance_types = ["c6i.2xlarge", "c5.2xlarge"]

# For memory-heavy
node_instance_types = ["r6i.2xlarge", "r5.2xlarge"]
```

### Enable Spot Instances

```hcl
create_spot_node_group = true
spot_desired_size      = 2
spot_max_size          = 10
```

### Restrict API Access (Production)

```hcl
# Only allow your company IP ranges
cluster_endpoint_public_access_cidrs = [
  "203.0.113.0/24",  # Your office
  "198.51.100.0/24"  # Your VPN
]
```

### Change Kubernetes Version

```hcl
kubernetes_version = "1.28"
```

## Monitoring and Logging

EKS cluster logs enabled for:
- **api**: API server audit logs
- **audit**: Kubernetes audit logs
- **authenticator**: IAM authentication logs
- **controllerManager**: Controller manager logs
- **scheduler**: Scheduler logs

View logs in CloudWatch:
```bash
aws logs tail /aws/eks/my-eks-cluster/cluster --follow
```

## Adding IRSA for Other Workloads

Example for AWS Load Balancer Controller:

```hcl
# Create service account in Kubernetes
kubectl create namespace kube-system
kubectl create serviceaccount aws-load-balancer-controller -n kube-system

# Create IAM role for the service account (like cluster_autoscaler in iam.tf)
resource "aws_iam_role" "aws_load_balancer_controller" {
  name = "eks-aws-load-balancer-controller"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.cluster.arn
      }
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })
}

# Attach required policy
resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
  role       = aws_iam_role.aws_load_balancer_controller.name
}

# Annotate the service account
kubectl annotate serviceaccount aws-load-balancer-controller \
  -n kube-system \
  eks.amazonaws.com/role-arn=arn:aws:iam::ACCOUNT_ID:role/eks-aws-load-balancer-controller
```

## Scaling Considerations

### Horizontal Scaling (More Nodes)

Modify in `terraform.tfvars`:
```hcl
desired_node_count = 5
max_node_count     = 20
```

### Vertical Scaling (Larger Instances)

```hcl
node_instance_types = ["m6i.xlarge", "m5.xlarge"]
```

### Auto-Scaling with Metrics

Install Cluster Autoscaler and Metrics Server for HPA:
```bash
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm repo update
helm install cluster-autoscaler autoscaler/cluster-autoscaler
```

## Troubleshooting

### Nodes not joining cluster
```bash
# Check node logs
aws ec2 describe-instances --filters "Name=tag:Name,Values=*eks*"

# SSH to node via Systems Manager
aws ssm start-session --target <instance-id>
cat /var/log/messages | grep -i kubelet
```

### API access denied
```bash
# Verify security group rules
aws ec2 describe-security-groups --group-ids <cluster-sg-id>

# Check RBAC
kubectl get rolebindings -A
```

### Pod cannot reach API
```bash
# Check network connectivity
kubectl run -it --rm debug --image=busybox --restart=Never -- sh
# Inside pod: curl https://kubernetes.default.svc
```

## Cleanup

⚠️ **WARNING**: This will delete the entire cluster and all resources.

```bash
terraform destroy
```

Confirm when prompted. The process takes several minutes.

## Cost Estimation

Using AWS Pricing Calculator or:

```bash
terraform plan | grep -i monthly
```

Typical monthly costs:
- EKS Control Plane: ~$73
- 3x t3.large nodes: ~$140
- NAT Gateway: ~$32
- **Total**: ~$245/month (before storage/networking)

## Best Practices Applied

✅ High availability across 3 AZs
✅ Least privilege IAM policies
✅ IMDSv2 enforcement
✅ Encrypted storage
✅ VPC best practices (public/private subnets)
✅ CloudWatch logging and monitoring
✅ IRSA support for pod-level security
✅ Auto-scaling configuration
✅ Security group restrictions
✅ Production-grade settings

## Additional Resources

- [AWS EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [Kubernetes Security Documentation](https://kubernetes.io/docs/concepts/security/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EKS Workshop](https://www.eksworkshop.com/)

## Support

For issues or improvements, check AWS documentation or Terraform registry.
