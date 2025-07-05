#!/bin/bash

# Complete Deployment and Testing Script
set -e

echo "=== CloudHSM Financial Demo Deployment ==="

# Step 1: Deploy Infrastructure
echo "1. Deploying infrastructure stack..."
aws cloudformation create-stack \
  --stack-name cloudhsm-financial-demo \
  --template-body file://cloudhsm-financial-demo.yaml \
  --parameters ParameterKey=DatabasePassword,ParameterValue=SecurePassword123! \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1

echo "Waiting for infrastructure stack to complete..."
aws cloudformation wait stack-create-complete \
  --stack-name cloudhsm-financial-demo

# Step 2: Deploy Application Stack
echo "2. Deploying application stack..."
aws cloudformation create-stack \
  --stack-name cloudhsm-financial-app \
  --template-body file://financial-app-stack.yaml \
  --parameters ParameterKey=InfrastructureStackName,ParameterValue=cloudhsm-financial-demo \
  --region us-east-1

echo "Waiting for application stack to complete..."
aws cloudformation wait stack-create-complete \
  --stack-name cloudhsm-financial-app

# Step 3: Get ALB DNS name
ALB_DNS=$(aws cloudformation describe-stacks \
  --stack-name cloudhsm-financial-demo \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
  --output text)

echo "Application Load Balancer DNS: $ALB_DNS"

# Step 4: Test the application
echo "3. Testing the financial processing service..."

# Wait for service to be ready
echo "Waiting for ECS service to be stable..."
sleep 60

# Test health endpoint
echo "Testing health endpoint..."
curl -f "http://$ALB_DNS/health" || echo "Health check failed - service may still be starting"

# Test transaction processing
echo "Testing transaction processing..."
curl -X POST "http://$ALB_DNS/process-transaction" \
  -H "Content-Type: application/json" \
  -d '{
    "card_number": "4111111111111111",
    "pin": "1234",
    "amount": 100.00,
    "merchant_id": "MERCHANT_001"
  }' || echo "Transaction test failed - service may still be starting"

# Step 5: Initialize HSM (manual step)
echo "4. HSM Initialization required..."
echo "Run: bash initialize-hsm.sh"

# Step 6: Monitor CloudWatch Logs
echo "5. Monitoring setup..."
echo "CloudWatch Log Groups created:"
echo "- /aws/ecs/cloudhsm-financial-demo"
echo "- /aws/cloudhsm/cloudhsm-financial-demo"

echo "=== Deployment Complete ==="
echo "Next steps:"
echo "1. Initialize CloudHSM cluster with certificates"
echo "2. Configure HSM client on application instances"
echo "3. Load test the transaction processing"
echo "4. Monitor compliance and audit logs"
