#!/bin/bash

# CloudHSM Cluster Initialization Script
set -e

CLUSTER_ID=$(aws cloudformation describe-stacks \
  --stack-name cloudhsm-financial-demo \
  --query 'Stacks[0].Outputs[?OutputKey==`CloudHSMClusterId`].OutputValue' \
  --output text)

echo "Initializing CloudHSM Cluster: $CLUSTER_ID"

# Step 1: Get cluster certificate
aws cloudhsmv2 describe-clusters \
  --filters clusterIds=$CLUSTER_ID \
  --query 'Clusters[0].Certificates.ClusterCertificate' \
  --output text > cluster-certificate.crt

echo "Cluster certificate saved to cluster-certificate.crt"

# Step 2: Create cluster CSR (Certificate Signing Request)
aws cloudhsmv2 describe-clusters \
  --filters clusterIds=$CLUSTER_ID \
  --query 'Clusters[0].Certificates.ClusterCsr' \
  --output text > cluster.csr

echo "Cluster CSR saved to cluster.csr"

# Step 3: Initialize cluster (requires manual certificate signing)
echo "Next steps:"
echo "1. Sign the cluster.csr with your root CA"
echo "2. Upload the signed certificate using:"
echo "   aws cloudhsmv2 initialize-cluster --cluster-id $CLUSTER_ID --signed-cert file://signed-cluster-cert.crt --trust-anchor file://root-ca.crt"

# Step 4: Create HSM client configuration
cat > cloudhsm_client.cfg << EOF
{
  "cluster_id": "$CLUSTER_ID",
  "region": "us-east-1",
  "server_client_cert_file": "/opt/cloudhsm/etc/server-client.crt",
  "server_client_key_file": "/opt/cloudhsm/etc/server-client.key",
  "trust_store": "/opt/cloudhsm/etc/trust-store"
}
EOF

echo "CloudHSM client configuration created: cloudhsm_client.cfg"
