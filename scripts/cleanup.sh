#!/bin/bash

# Cleanup script for CloudHSM Financial Demo
set -e

echo "=== CloudHSM Financial Demo Cleanup ==="
echo "⚠️  WARNING: This will delete all resources created by the demo!"
echo ""

read -p "Are you sure you want to proceed? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo "Starting cleanup process..."

# Delete Application Stack
echo "1. Deleting application stack..."
aws cloudformation delete-stack --stack-name cloudhsm-financial-app || echo "Application stack not found"

echo "Waiting for application stack deletion..."
aws cloudformation wait stack-delete-complete --stack-name cloudhsm-financial-app || echo "Application stack deletion completed"

# Delete Infrastructure Stack
echo "2. Deleting infrastructure stack..."
aws cloudformation delete-stack --stack-name cloudhsm-financial-demo || echo "Infrastructure stack not found"

echo "Waiting for infrastructure stack deletion..."
aws cloudformation wait stack-delete-complete --stack-name cloudhsm-financial-demo || echo "Infrastructure stack deletion completed"

# Clean up any remaining CloudWatch Log Groups
echo "3. Cleaning up CloudWatch log groups..."
aws logs delete-log-group --log-group-name "/aws/ecs/cloudhsm-financial-demo" || echo "ECS log group not found"
aws logs delete-log-group --log-group-name "/aws/cloudhsm/cloudhsm-financial-demo" || echo "CloudHSM log group not found"

# Clean up local files
echo "4. Cleaning up local files..."
rm -f cluster-certificate.crt
rm -f cluster.csr
rm -f cloudhsm_client.cfg

echo "✅ Cleanup completed successfully!"
echo ""
echo "Note: Some resources may take additional time to fully delete."
echo "Check the CloudFormation console to verify all stacks are deleted."
