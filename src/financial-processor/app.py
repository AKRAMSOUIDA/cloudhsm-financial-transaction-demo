#!/usr/bin/env python3
"""
CloudHSM Financial Transaction Processor
Secure payment processing with hardware-based cryptography
"""

import os
import json
import time
import hashlib
import logging
from datetime import datetime
from flask import Flask, request, jsonify
import boto3
from botocore.exceptions import ClientError

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Configuration
CLOUDHSM_CLUSTER_ID = os.environ.get('CLOUDHSM_CLUSTER_ID')
DATABASE_ENDPOINT = os.environ.get('DATABASE_ENDPOINT')
AWS_REGION = os.environ.get('AWS_DEFAULT_REGION', 'us-east-1')
FRAUD_THRESHOLD = int(os.environ.get('FRAUD_THRESHOLD', '75'))

# AWS clients
cloudhsm_client = boto3.client('cloudhsmv2', region_name=AWS_REGION)
logs_client = boto3.client('logs', region_name=AWS_REGION)

class HSMOperations:
    """Simulated CloudHSM operations for demo purposes"""
    
    @staticmethod
    def encrypt_pan(pan):
        """Simulate PAN encryption using HSM"""
        # In real implementation, this would use CloudHSM client
        encrypted_pan = hashlib.sha256(pan.encode()).hexdigest()
        logger.info(f"HSM Operation: encrypt_pan - SUCCESS")
        return encrypted_pan
    
    @staticmethod
    def verify_pin(encrypted_pan, pin_block):
        """Simulate PIN verification using HSM"""
        # In real implementation, this would use CloudHSM for PIN verification
        # Simulate PIN verification logic
        is_valid = pin_block == "1234"  # Demo PIN
        logger.info(f"HSM Operation: verify_pin - {'SUCCESS' if is_valid else 'FAILED'}")
        return is_valid
    
    @staticmethod
    def sign_transaction(transaction_data):
        """Simulate transaction signing using HSM"""
        # In real implementation, this would use CloudHSM for digital signing
        signature = hashlib.sha256(json.dumps(transaction_data, sort_keys=True).encode()).hexdigest()
        logger.info(f"HSM Operation: sign_transaction - SUCCESS")
        return signature

class FraudDetection:
    """Fraud detection with cryptographic validation"""
    
    @staticmethod
    def calculate_fraud_score(transaction_data):
        """Calculate fraud risk score"""
        score = 0
        
        # Amount-based scoring
        amount = float(transaction_data.get('amount', 0))
        if amount > 5000:
            score += 50
        elif amount > 1000:
            score += 25
        
        # Velocity check (simulated)
        # In real implementation, this would check recent transaction history
        score += 10  # Base velocity score
        
        # Geographic anomaly (simulated)
        merchant_id = transaction_data.get('merchant_id', '')
        if 'SUSPICIOUS' in merchant_id:
            score += 40
        
        logger.info(f"Fraud Detection: Score {score} for transaction")
        return min(score, 100)

def log_transaction(transaction_data, signature, auth_code, status):
    """Log transaction to CloudWatch"""
    log_entry = {
        'timestamp': datetime.utcnow().isoformat(),
        'transaction_id': transaction_data.get('transaction_id'),
        'amount': transaction_data.get('amount'),
        'merchant_id': transaction_data.get('merchant_id'),
        'status': status,
        'auth_code': auth_code,
        'signature': signature[:16] + '...',  # Truncated for logging
        'hsm_cluster_id': CLOUDHSM_CLUSTER_ID
    }
    
    try:
        logs_client.put_log_events(
            logGroupName='/aws/ecs/cloudhsm-financial-demo',
            logStreamName=f'financial-processor-{datetime.now().strftime("%Y-%m-%d")}',
            logEvents=[
                {
                    'timestamp': int(time.time() * 1000),
                    'message': json.dumps(log_entry)
                }
            ]
        )
    except ClientError as e:
        logger.error(f"Failed to log to CloudWatch: {e}")

@app.route('/health')
def health_check():
    """Health check endpoint"""
    try:
        # Check HSM cluster status
        hsm_status = "unknown"
        if CLOUDHSM_CLUSTER_ID:
            try:
                response = cloudhsm_client.describe_clusters(
                    Filters={'clusterIds': [CLOUDHSM_CLUSTER_ID]}
                )
                if response['Clusters']:
                    hsm_status = response['Clusters'][0]['State']
            except ClientError:
                hsm_status = "unavailable"
        
        return jsonify({
            'status': 'healthy',
            'timestamp': time.time(),
            'hsm_cluster_status': hsm_status,
            'database_endpoint': DATABASE_ENDPOINT,
            'version': '1.0.0'
        })
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return jsonify({'status': 'unhealthy', 'error': str(e)}), 500

@app.route('/process-transaction', methods=['POST'])
def process_transaction():
    """Process a financial transaction"""
    try:
        # Parse request data
        data = request.json
        if not data:
            return jsonify({'error': 'No transaction data provided'}), 400
        
        # Generate transaction ID
        transaction_id = hashlib.sha256(
            f"{data.get('card_number', '')}{time.time()}".encode()
        ).hexdigest()[:16]
        
        transaction_data = {
            'transaction_id': transaction_id,
            'amount': data.get('amount'),
            'merchant_id': data.get('merchant_id'),
            'timestamp': datetime.utcnow().isoformat()
        }
        
        # Step 1: Encrypt PAN using HSM
        encrypted_pan = HSMOperations.encrypt_pan(data.get('card_number', ''))
        
        # Step 2: Verify PIN using HSM
        pin_valid = HSMOperations.verify_pin(encrypted_pan, data.get('pin', ''))
        
        if not pin_valid:
            auth_code = f"DECLINED_{transaction_id[:6].upper()}"
            log_transaction(transaction_data, "", auth_code, "DECLINED")
            return jsonify({
                'transaction_id': transaction_id,
                'status': 'DECLINED',
                'reason': 'Invalid PIN',
                'auth_code': auth_code
            })
        
        # Step 3: Sign transaction using HSM
        signature = HSMOperations.sign_transaction(transaction_data)
        
        # Step 4: Fraud detection
        fraud_score = FraudDetection.calculate_fraud_score(transaction_data)
        
        if fraud_score >= FRAUD_THRESHOLD:
            auth_code = f"FRAUD_{transaction_id[:6].upper()}"
            log_transaction(transaction_data, signature, auth_code, "DECLINED")
            return jsonify({
                'transaction_id': transaction_id,
                'status': 'DECLINED',
                'reason': 'Fraud detected',
                'fraud_score': fraud_score,
                'auth_code': auth_code
            })
        
        # Step 5: Approve transaction
        auth_code = f"AUTH_{transaction_id[:6].upper()}"
        log_transaction(transaction_data, signature, auth_code, "APPROVED")
        
        return jsonify({
            'transaction_id': transaction_id,
            'status': 'APPROVED',
            'auth_code': auth_code,
            'fraud_score': fraud_score,
            'hsm_operations': [
                {'operation': 'encrypt_pan', 'status': 'success'},
                {'operation': 'verify_pin', 'status': 'success'},
                {'operation': 'sign_transaction', 'status': 'success'}
            ],
            'processing_time_ms': 150  # Simulated processing time
        })
        
    except Exception as e:
        logger.error(f"Transaction processing failed: {e}")
        return jsonify({
            'error': 'Transaction processing failed',
            'details': str(e)
        }), 500

@app.route('/hsm-status')
def hsm_status():
    """Get CloudHSM cluster status"""
    try:
        if not CLOUDHSM_CLUSTER_ID:
            return jsonify({'error': 'CloudHSM cluster ID not configured'}), 400
        
        response = cloudhsm_client.describe_clusters(
            Filters={'clusterIds': [CLOUDHSM_CLUSTER_ID]}
        )
        
        if not response['Clusters']:
            return jsonify({'error': 'CloudHSM cluster not found'}), 404
        
        cluster = response['Clusters'][0]
        
        return jsonify({
            'cluster_id': CLOUDHSM_CLUSTER_ID,
            'state': cluster['State'],
            'hsm_count': len(cluster.get('Hsms', [])),
            'security_group': cluster.get('SecurityGroup'),
            'vpc_id': cluster.get('VpcId'),
            'creation_timestamp': cluster.get('CreateTimestamp').isoformat() if cluster.get('CreateTimestamp') else None
        })
        
    except ClientError as e:
        logger.error(f"Failed to get HSM status: {e}")
        return jsonify({'error': 'Failed to get HSM status', 'details': str(e)}), 500

@app.route('/metrics')
def metrics():
    """Application metrics endpoint"""
    return jsonify({
        'transactions_processed': 1000,  # Simulated metric
        'average_processing_time_ms': 145,
        'fraud_detection_rate': 0.02,
        'hsm_operations_per_second': 500,
        'uptime_seconds': int(time.time() - app.start_time)
    })

if __name__ == '__main__':
    app.start_time = time.time()
    logger.info("Starting CloudHSM Financial Transaction Processor")
    logger.info(f"CloudHSM Cluster ID: {CLOUDHSM_CLUSTER_ID}")
    logger.info(f"Database Endpoint: {DATABASE_ENDPOINT}")
    logger.info(f"Fraud Threshold: {FRAUD_THRESHOLD}")
    
    app.run(host='0.0.0.0', port=8080, debug=False)
