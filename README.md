# CloudHSM Financial Transaction Processing Demo

[![AWS](https://img.shields.io/badge/AWS-CloudHSM-orange.svg)](https://aws.amazon.com/cloudhsm/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![CloudFormation](https://img.shields.io/badge/Infrastructure-CloudFormation-yellow.svg)](https://aws.amazon.com/cloudformation/)
[![Security](https://img.shields.io/badge/Security-FIPS%20140--2%20Level%203-green.svg)](https://csrc.nist.gov/publications/detail/fips/140/2/final)

A comprehensive demonstration of secure financial transaction processing using AWS CloudHSM, showcasing enterprise-grade cryptographic operations, PCI DSS compliance, and real-time fraud detection.

## 🏗️ Architecture Overview

![AWS Architecture](https://img.shields.io/badge/AWS-Architecture-orange?style=for-the-badge&logo=amazon-aws)

```mermaid
graph TB
    subgraph "🌐 Internet"
        Client[👤 Client/POS Terminal]
    end
    
    subgraph "☁️ AWS Cloud"
        subgraph "🏢 VPC (10.0.0.0/16)"
            subgraph "🌍 Public Subnet (10.0.3.0/24)"
                ALB[<img src='https://icon.icepanel.io/AWS/svg/Networking-Content-Delivery/Elastic-Load-Balancing.svg' width='20'/><br/>Application Load Balancer]
                NAT[<img src='https://icon.icepanel.io/AWS/svg/Networking-Content-Delivery/VPC-NAT-Gateway.svg' width='20'/><br/>NAT Gateway]
            end
            
            subgraph "🔒 Private Subnet 1 (10.0.1.0/24)"
                HSM1[<img src='https://icon.icepanel.io/AWS/svg/Security-Identity-Compliance/CloudHSM.svg' width='20'/><br/>CloudHSM Instance 1<br/>FIPS 140-2 Level 3]
                ECS1[<img src='https://icon.icepanel.io/AWS/svg/Containers/Elastic-Container-Service.svg' width='20'/><br/>ECS Tasks<br/>Financial Processor]
                Lambda1[<img src='https://icon.icepanel.io/AWS/svg/Compute/Lambda.svg' width='20'/><br/>Lambda Functions<br/>Key Management]
            end
            
            subgraph "🔒 Private Subnet 2 (10.0.2.0/24)"
                HSM2[<img src='https://icon.icepanel.io/AWS/svg/Security-Identity-Compliance/CloudHSM.svg' width='20'/><br/>CloudHSM Instance 2<br/>FIPS 140-2 Level 3]
                RDS[<img src='https://icon.icepanel.io/AWS/svg/Database/RDS.svg' width='20'/><br/>RDS PostgreSQL<br/>Encrypted Database]
            end
        end
        
        subgraph "🛠️ AWS Services"
            CloudWatch[<img src='https://icon.icepanel.io/AWS/svg/Management-Governance/CloudWatch.svg' width='20'/><br/>CloudWatch<br/>Monitoring & Logs]
            KMS[<img src='https://icon.icepanel.io/AWS/svg/Security-Identity-Compliance/Key-Management-Service.svg' width='20'/><br/>AWS KMS<br/>Key Management]
            Secrets[<img src='https://icon.icepanel.io/AWS/svg/Security-Identity-Compliance/Secrets-Manager.svg' width='20'/><br/>Secrets Manager<br/>Credentials]
            IAM[<img src='https://icon.icepanel.io/AWS/svg/Security-Identity-Compliance/IAM-Identity-and-Access-Management.svg' width='20'/><br/>AWS IAM<br/>Access Control]
        end
    end
    
    Client --> ALB
    ALB --> ECS1
    ECS1 --> HSM1
    ECS1 --> HSM2
    ECS1 --> RDS
    ECS1 --> CloudWatch
    Lambda1 --> HSM1
    Lambda1 --> HSM2
    Lambda1 --> KMS
    ECS1 --> Secrets
    
    style HSM1 fill:#ff6b6b,stroke:#d63031,stroke-width:3px
    style HSM2 fill:#ff6b6b,stroke:#d63031,stroke-width:3px
    style ALB fill:#74b9ff,stroke:#0984e3,stroke-width:2px
    style ECS1 fill:#fd79a8,stroke:#e84393,stroke-width:2px
    style RDS fill:#00b894,stroke:#00a085,stroke-width:2px
```

> 📊 **[View Detailed Architecture Diagrams](docs/diagrams.md)** - Interactive diagrams with transaction flows, security layers, and compliance frameworks

## 💳 Transaction Processing Flow

```mermaid
sequenceDiagram
    participant C as 👤 Customer
    participant P as 🏪 POS Terminal  
    participant A as ⚖️ ALB
    participant E as 📦 ECS Service
    participant H as 🔐 CloudHSM
    participant D as 🗄️ Database
    
    C->>P: 1. Swipe Card & Enter PIN
    P->>A: 2. Send Transaction Request
    A->>E: 3. Route to ECS Task
    
    Note over E,H: 🔐 HSM Cryptographic Operations
    E->>H: 4a. Encrypt PAN
    H-->>E: 4b. Encrypted PAN
    E->>H: 5a. Verify PIN  
    H-->>E: 5b. PIN Valid ✅
    E->>H: 6a. Sign Transaction
    H-->>E: 6b. Digital Signature ✍️
    
    Note over E: 🕵️ Fraud Detection Analysis
    E->>E: 7. Calculate Risk Score
    
    alt ✅ Transaction Approved
        E->>D: 8a. Store Transaction
        E-->>A: 9a. APPROVED Response
    else ❌ Transaction Declined  
        E-->>A: 9b. DECLINED Response
    end
    
    A-->>P: 10. Authorization Response
    P-->>C: 11. Display Result
```

## 🎯 Key Features

### 🔐 Security Features
- ![CloudHSM](https://img.shields.io/badge/CloudHSM-FIPS%20140--2%20Level%203-red?logo=amazon-aws) **Hardware-based cryptographic operations**
- ![Security](https://img.shields.io/badge/PIN-Verification-green?logo=shield) **Secure PIN validation without exposure**
- ![Encryption](https://img.shields.io/badge/PAN-Encryption-blue?logo=lock) **Card data encryption using HSM-protected keys**
- ![Signature](https://img.shields.io/badge/Digital-Signatures-purple?logo=certificate) **Non-repudiation for all transactions**
- ![Audit](https://img.shields.io/badge/Audit-Trails-orange?logo=clipboard-list) **Immutable logging of all cryptographic operations**

### 💳 Financial Processing
- ![Performance](https://img.shields.io/badge/Latency-Sub%20200ms-brightgreen?logo=speedometer) **Real-time authorization processing**
- ![Fraud](https://img.shields.io/badge/Fraud-Detection-red?logo=shield-check) **Cryptographic validation and risk scoring**
- ![Compliance](https://img.shields.io/badge/PCI%20DSS-Level%201-gold?logo=credit-card) **Complete cardholder data protection**
- ![Auth](https://img.shields.io/badge/Multi--Factor-Authentication-blue?logo=key) **PIN + cryptogram validation**
- ![Keys](https://img.shields.io/badge/Key-Management-purple?logo=key) **Automated rotation and secure backup**

### 🏢 Enterprise Features
- ![HA](https://img.shields.io/badge/High-Availability-green?logo=server) **Multi-AZ deployment with automatic failover**
- ![Scale](https://img.shields.io/badge/Auto-Scaling-blue?logo=trending-up) **ECS services and HSM cluster expansion**
- ![Monitor](https://img.shields.io/badge/CloudWatch-Monitoring-orange?logo=amazon-aws) **Comprehensive dashboards and alerting**
- ![Reports](https://img.shields.io/badge/Compliance-Reporting-purple?logo=file-text) **Automated audit and compliance reports**

## 📋 Prerequisites

- AWS CLI configured with appropriate permissions
- Docker installed (for local testing)
- OpenSSL for certificate operations
- Basic understanding of PKI and cryptographic operations

### Required AWS Permissions
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudhsm:*",
                "cloudformation:*",
                "ecs:*",
                "ec2:*",
                "iam:*",
                "rds:*",
                "elasticloadbalancing:*",
                "logs:*",
                "secretsmanager:*"
            ],
            "Resource": "*"
        }
    ]
}
```

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/YOUR_USERNAME/cloudhsm-financial-transaction-demo.git
cd cloudhsm-financial-transaction-demo
```

### 2. Deploy Infrastructure
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Deploy the complete infrastructure
./scripts/deploy-and-test.sh
```

### 3. Initialize CloudHSM
```bash
# Initialize the HSM cluster
./scripts/initialize-hsm.sh
```

### 4. Test the System
```bash
# Run comprehensive tests
./scripts/run-tests.sh
```

## 📁 Project Structure

```
cloudhsm-financial-transaction-demo/
├── README.md
├── LICENSE
├── .gitignore
├── infrastructure/
│   ├── cloudhsm-financial-demo.yaml      # Main infrastructure stack
│   ├── financial-app-stack.yaml          # Application deployment stack
│   └── monitoring-dashboard.json         # CloudWatch dashboard
├── scripts/
│   ├── deploy-and-test.sh                # Complete deployment script
│   ├── initialize-hsm.sh                 # HSM initialization
│   ├── run-tests.sh                      # Test suite
│   └── cleanup.sh                        # Resource cleanup
├── src/
│   ├── financial-processor/              # Main application code
│   ├── hsm-client/                       # CloudHSM client utilities
│   └── fraud-detection/                  # Fraud detection algorithms
├── tests/
│   ├── unit/                             # Unit tests
│   ├── integration/                      # Integration tests
│   └── load/                             # Load testing scripts
├── docs/
│   ├── architecture.md                   # Detailed architecture
│   ├── security.md                       # Security implementation
│   ├── compliance.md                     # Compliance guide
│   └── troubleshooting.md                # Common issues and solutions
└── examples/
    ├── transaction-samples.json          # Sample transactions
    └── api-examples.md                   # API usage examples
```

## 🔧 Configuration

### Environment Variables
```bash
export CLOUDHSM_CLUSTER_ID="cluster-xxxxxxxxx"
export AWS_REGION="us-east-1"
export DATABASE_ENDPOINT="your-db-endpoint"
export FRAUD_THRESHOLD="75"
```

### CloudHSM Client Configuration
```json
{
  "cluster_id": "cluster-xxxxxxxxx",
  "region": "us-east-1",
  "server_client_cert_file": "/opt/cloudhsm/etc/server-client.crt",
  "server_client_key_file": "/opt/cloudhsm/etc/server-client.key",
  "trust_store": "/opt/cloudhsm/etc/trust-store"
}
```

## 🧪 Testing

### Unit Tests
```bash
cd tests/unit
python -m pytest test_financial_processor.py -v
```

### Integration Tests
```bash
cd tests/integration
python -m pytest test_hsm_operations.py -v
```

### Load Testing
```bash
cd tests/load
./load_test.sh 1000 # 1000 concurrent transactions
```

## 📊 Monitoring and Observability

![CloudWatch Dashboard](https://img.shields.io/badge/CloudWatch-Dashboard-orange?style=for-the-badge&logo=amazon-aws)

```mermaid
graph TB
    subgraph "📊 Monitoring Stack"
        subgraph "📈 Metrics Collection"
            CW[<img src='https://icon.icepanel.io/AWS/svg/Management-Governance/CloudWatch.svg' width='15'/> CloudWatch Metrics<br/>System Performance]
            XR[<img src='https://icon.icepanel.io/AWS/svg/Developer-Tools/X-Ray.svg' width='15'/> X-Ray Tracing<br/>Request Tracking]
            CI[📊 Container Insights<br/>ECS Monitoring]
        end
        
        subgraph "📝 Log Aggregation"
            CWL[<img src='https://icon.icepanel.io/AWS/svg/Management-Governance/CloudWatch.svg' width='15'/> CloudWatch Logs<br/>Application Logs]
            HSM_L[<img src='https://icon.icepanel.io/AWS/svg/Security-Identity-Compliance/CloudHSM.svg' width='15'/> HSM Audit Logs<br/>Crypto Operations]
            ALB_L[<img src='https://icon.icepanel.io/AWS/svg/Networking-Content-Delivery/Elastic-Load-Balancing.svg' width='15'/> ALB Access Logs<br/>Request Patterns]
        end
        
        subgraph "🚨 Alerting & Dashboards"
            SNS[<img src='https://icon.icepanel.io/AWS/svg/Application-Integration/Simple-Notification-Service.svg' width='15'/> SNS Notifications<br/>Alert Delivery]
            DASH[📊 CloudWatch Dashboards<br/>Real-time Monitoring]
            ALARM[🚨 CloudWatch Alarms<br/>Threshold Monitoring]
        end
    end
    
    CW --> DASH
    CWL --> DASH
    HSM_L --> DASH
    CW --> ALARM
    ALARM --> SNS
    
    style HSM_L fill:#ff6b6b,stroke:#d63031,stroke-width:3px
    style DASH fill:#74b9ff,stroke:#0984e3,stroke-width:2px
```

### Key Metrics
- **Transaction Throughput**: Transactions per second
- **HSM Latency**: Cryptographic operation response time
- **Error Rates**: Failed transactions and HSM operations
- **Fraud Detection**: Blocked transactions and false positives

### CloudWatch Dashboards
- **Application Performance**: ECS metrics, ALB performance
- **HSM Operations**: Cluster health, operation latency
- **Security Events**: Failed authentications, fraud attempts
- **Compliance**: Audit trail completeness, key rotation status

### Alerts
- HSM cluster health degradation
- High transaction error rates
- Unusual fraud detection patterns
- Key rotation failures

## 🔒 Security Considerations

### Data Protection
- All sensitive data encrypted at rest and in transit
- HSM keys never leave the hardware boundary
- PIN blocks use industry-standard formatting (ISO 9564)
- Database encryption using AWS KMS

### Network Security
- Private subnets for all sensitive components
- Security groups with least-privilege access
- VPC endpoints for AWS service communication
- WAF protection for public endpoints

### Compliance
- ![PCI DSS](https://img.shields.io/badge/PCI%20DSS-Level%201-gold?logo=credit-card) **Cardholder data protection**
- ![SOX](https://img.shields.io/badge/SOX-Compliance-blue?logo=balance-scale) **Financial reporting controls**
- ![GDPR](https://img.shields.io/badge/GDPR-Ready-green?logo=shield-check) **Data protection and privacy**
- ![FIPS](https://img.shields.io/badge/FIPS%20140--2-Level%203-red?logo=certificate) **Cryptographic module security**

## 💰 Cost Optimization

![Cost Optimization](https://img.shields.io/badge/Cost-Optimized-green?style=for-the-badge&logo=dollar-sign)

```mermaid
pie title Monthly Cost Breakdown ($2,500 Total)
    "CloudHSM Cluster (2 instances)" : 2400
    "ECS Fargate" : 50
    "RDS Database" : 25
    "Application Load Balancer" : 20
    "Data Transfer & Misc" : 5
```

### Infrastructure Costs (Monthly Estimates)
- **CloudHSM Cluster**: ~$2,400 (2 instances)
- **ECS Fargate**: ~$50-200 (depending on load)
- **RDS**: ~$25-50 (db.t3.micro)
- **ALB**: ~$20-30
- **Data Transfer**: ~$10-50

### Cost Optimization Strategies
- ![Fargate Spot](https://img.shields.io/badge/Fargate%20Spot-70%25%20Savings-brightgreen?logo=amazon-aws) **Use Fargate Spot for non-critical workloads**
- ![Right-sizing](https://img.shields.io/badge/Right--sizing-Resource%20Optimization-blue?logo=resize) **Optimize RDS instances based on actual usage**
- ![Log Retention](https://img.shields.io/badge/Log%20Retention-Policy%20Management-orange?logo=file-text) **Implement CloudWatch log retention policies**
- ![Reserved](https://img.shields.io/badge/Reserved%20Instances-Predictable%20Workloads-purple?logo=calendar) **Use reserved instances for predictable workloads**

## 🚨 Troubleshooting

### Common Issues

#### HSM Cluster Initialization Fails
```bash
# Check cluster state
aws cloudhsmv2 describe-clusters --filters clusterIds=cluster-xxxxxxxxx

# Verify network connectivity
aws ec2 describe-security-groups --group-ids sg-xxxxxxxxx
```

#### Transaction Processing Errors
```bash
# Check ECS service logs
aws logs get-log-events --log-group-name /aws/ecs/cloudhsm-financial-demo

# Verify HSM connectivity
./scripts/test-hsm-connection.sh
```

#### High Latency Issues
```bash
# Monitor HSM performance
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudHSM \
  --metric-name OperationLatency
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow AWS Well-Architected Framework principles
- Include comprehensive tests for new features
- Update documentation for any API changes
- Ensure security best practices are followed

## 📚 Additional Resources

### AWS Documentation
- [AWS CloudHSM User Guide](https://docs.aws.amazon.com/cloudhsm/)
- [CloudHSM Client SDK](https://docs.aws.amazon.com/cloudhsm/latest/userguide/client-sdk.html)
- [PCI DSS on AWS](https://aws.amazon.com/compliance/pci-dss-level-1-faqs/)

### Industry Standards
- [PCI DSS Requirements](https://www.pcisecuritystandards.org/)
- [FIPS 140-2 Standard](https://csrc.nist.gov/publications/detail/fips/140/2/final)
- [ISO 9564 PIN Management](https://www.iso.org/standard/43897.html)

### Training and Certification
- [AWS Security Specialty Certification](https://aws.amazon.com/certification/certified-security-specialty/)
- [CloudHSM Workshop](https://cloudhsm.workshop.aws/)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

This is a demonstration project for educational purposes. While it follows security best practices, additional hardening and testing would be required for production use. Always consult with security professionals and conduct thorough testing before deploying financial applications.

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/YOUR_USERNAME/cloudhsm-financial-transaction-demo/issues)
- **Discussions**: [GitHub Discussions](https://github.com/YOUR_USERNAME/cloudhsm-financial-transaction-demo/discussions)
- **AWS Support**: For CloudHSM-specific issues, contact AWS Support

---

**Built with ❤️ for secure financial processing on AWS**
