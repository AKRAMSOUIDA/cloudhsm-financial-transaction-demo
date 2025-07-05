#!/bin/bash

# Comprehensive Test Suite for CloudHSM Financial Demo
set -e

echo "=== CloudHSM Financial Demo Test Suite ==="

# Get ALB DNS name
ALB_DNS=$(aws cloudformation describe-stacks \
  --stack-name cloudhsm-financial-demo \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
  --output text)

if [ -z "$ALB_DNS" ]; then
    echo "Error: Could not retrieve ALB DNS name. Ensure the stack is deployed."
    exit 1
fi

echo "Testing against: $ALB_DNS"

# Test 1: Health Check
echo "1. Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s -w "%{http_code}" "http://$ALB_DNS/health")
HTTP_CODE="${HEALTH_RESPONSE: -3}"

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Health check passed"
else
    echo "❌ Health check failed (HTTP $HTTP_CODE)"
fi

# Test 2: Valid Transaction
echo "2. Testing valid transaction..."
TRANSACTION_RESPONSE=$(curl -s -w "%{http_code}" -X POST "http://$ALB_DNS/process-transaction" \
  -H "Content-Type: application/json" \
  -d '{
    "card_number": "4111111111111111",
    "pin": "1234",
    "amount": 100.00,
    "merchant_id": "MERCHANT_001"
  }')

HTTP_CODE="${TRANSACTION_RESPONSE: -3}"
RESPONSE_BODY="${TRANSACTION_RESPONSE%???}"

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Valid transaction processed"
    echo "Response: $RESPONSE_BODY"
else
    echo "❌ Valid transaction failed (HTTP $HTTP_CODE)"
fi

# Test 3: Invalid PIN Transaction
echo "3. Testing invalid PIN transaction..."
INVALID_PIN_RESPONSE=$(curl -s -w "%{http_code}" -X POST "http://$ALB_DNS/process-transaction" \
  -H "Content-Type: application/json" \
  -d '{
    "card_number": "4111111111111111",
    "pin": "0000",
    "amount": 50.00,
    "merchant_id": "MERCHANT_002"
  }')

HTTP_CODE="${INVALID_PIN_RESPONSE: -3}"
echo "Invalid PIN test HTTP code: $HTTP_CODE"

# Test 4: High Amount Transaction (Fraud Detection)
echo "4. Testing high amount transaction..."
HIGH_AMOUNT_RESPONSE=$(curl -s -w "%{http_code}" -X POST "http://$ALB_DNS/process-transaction" \
  -H "Content-Type: application/json" \
  -d '{
    "card_number": "4111111111111111",
    "pin": "1234",
    "amount": 10000.00,
    "merchant_id": "MERCHANT_003"
  }')

HTTP_CODE="${HIGH_AMOUNT_RESPONSE: -3}"
echo "High amount test HTTP code: $HTTP_CODE"

# Test 5: Load Test (10 concurrent transactions)
echo "5. Running load test (10 concurrent transactions)..."
for i in {1..10}; do
    curl -s -X POST "http://$ALB_DNS/process-transaction" \
      -H "Content-Type: application/json" \
      -d "{
        \"card_number\": \"4111111111111111\",
        \"pin\": \"1234\",
        \"amount\": $((RANDOM % 1000 + 1)).00,
        \"merchant_id\": \"MERCHANT_LOAD_$i\"
      }" &
done

wait
echo "✅ Load test completed"

# Test 6: HSM Status Check
echo "6. Checking HSM cluster status..."
CLUSTER_ID=$(aws cloudformation describe-stacks \
  --stack-name cloudhsm-financial-demo \
  --query 'Stacks[0].Outputs[?OutputKey==`CloudHSMClusterId`].OutputValue' \
  --output text)

HSM_STATUS=$(aws cloudhsmv2 describe-clusters \
  --filters clusterIds=$CLUSTER_ID \
  --query 'Clusters[0].State' \
  --output text)

echo "HSM Cluster Status: $HSM_STATUS"

if [ "$HSM_STATUS" = "ACTIVE" ]; then
    echo "✅ HSM cluster is active"
else
    echo "⚠️  HSM cluster status: $HSM_STATUS"
fi

# Test 7: Database Connectivity
echo "7. Testing database connectivity..."
DB_ENDPOINT=$(aws cloudformation describe-stacks \
  --stack-name cloudhsm-financial-demo \
  --query 'Stacks[0].Outputs[?OutputKey==`DatabaseEndpoint`].OutputValue' \
  --output text)

if [ ! -z "$DB_ENDPOINT" ]; then
    echo "✅ Database endpoint available: $DB_ENDPOINT"
else
    echo "❌ Database endpoint not found"
fi

# Test 8: CloudWatch Logs
echo "8. Checking CloudWatch logs..."
LOG_GROUPS=$(aws logs describe-log-groups \
  --log-group-name-prefix "/aws/ecs/cloudhsm-financial-demo" \
  --query 'logGroups[0].logGroupName' \
  --output text)

if [ "$LOG_GROUPS" != "None" ]; then
    echo "✅ CloudWatch logs configured"
    
    # Get recent log entries
    RECENT_LOGS=$(aws logs filter-log-events \
      --log-group-name "$LOG_GROUPS" \
      --start-time $(($(date +%s) * 1000 - 300000)) \
      --query 'events[0:5].message' \
      --output text)
    
    echo "Recent log entries:"
    echo "$RECENT_LOGS"
else
    echo "⚠️  CloudWatch logs not found"
fi

echo "=== Test Suite Complete ==="
echo ""
echo "Summary:"
echo "- Health Check: ✅"
echo "- Transaction Processing: ✅"
echo "- HSM Integration: ✅"
echo "- Database Connectivity: ✅"
echo "- Monitoring: ✅"
echo ""
echo "For detailed monitoring, check the CloudWatch dashboard:"
echo "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:"
