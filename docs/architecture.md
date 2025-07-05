# Architecture Documentation

## Overview

The CloudHSM Financial Transaction Processing Demo implements a secure, scalable architecture for processing financial transactions using AWS CloudHSM for hardware-based cryptographic operations.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Internet                                 │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────┴───────────────────────────────────────────┐
│                   AWS Cloud                                    │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    VPC (10.0.0.0/16)                   │    │
│  │                                                         │    │
│  │  ┌──────────────┐    ┌──────────────┐    ┌──────────┐  │    │
│  │  │Public Subnet │    │Private Subnet│    │Private   │  │    │
│  │  │10.0.3.0/24   │    │10.0.1.0/24   │    │Subnet    │  │    │
│  │  │              │    │              │    │10.0.2.0/24│ │    │
│  │  │ ┌──────────┐ │    │ ┌──────────┐ │    │          │  │    │
│  │  │ │   ALB    │ │    │ │CloudHSM  │ │    │ ┌──────┐ │  │    │
│  │  │ │          │ │    │ │Instance 1│ │    │ │CloudHSM│ │    │
│  │  │ └──────────┘ │    │ └──────────┘ │    │ │Instance│ │    │
│  │  │              │    │              │    │ │   2    │ │    │
│  │  │ ┌──────────┐ │    │ ┌──────────┐ │    │ └──────┘ │  │    │
│  │  │ │NAT Gateway│ │    │ │ECS Tasks │ │    │          │  │    │
│  │  │ └──────────┘ │    │ └──────────┘ │    │ ┌──────┐ │  │    │
│  │  └──────────────┘    │              │    │ │ RDS  │ │  │    │
│  │                      │ ┌──────────┐ │    │ │      │ │  │    │
│  │                      │ │Lambda    │ │    │ └──────┘ │  │    │
│  │                      │ │Functions │ │    │          │  │    │
│  │                      │ └──────────┘ │    └──────────┘  │    │
│  │                      └──────────────┘                  │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                External Services                        │    │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐   │    │
│  │  │CloudWatch│ │   KMS   │  │Secrets  │  │   IAM   │   │    │
│  │  │  Logs    │  │         │  │Manager  │  │         │   │    │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘   │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Network Layer

#### VPC Configuration
- **CIDR Block**: 10.0.0.0/16
- **Multi-AZ Deployment**: Spans 2 Availability Zones
- **DNS Resolution**: Enabled for service discovery

#### Subnets
- **Public Subnet (10.0.3.0/24)**: 
  - Hosts Application Load Balancer
  - NAT Gateway for outbound internet access
- **Private Subnet 1 (10.0.1.0/24)**:
  - Primary CloudHSM instance
  - ECS tasks and Lambda functions
- **Private Subnet 2 (10.0.2.0/24)**:
  - Secondary CloudHSM instance (HA)
  - RDS database instance

### 2. Security Layer

#### Security Groups
```
┌─────────────────────────────────────────────────────────────┐
│                    Security Groups                          │
├─────────────────────────────────────────────────────────────┤
│ ALB Security Group                                          │
│ ├─ Inbound: 80/443 from 0.0.0.0/0                         │
│ └─ Outbound: 8080 to Application SG                        │
├─────────────────────────────────────────────────────────────┤
│ Application Security Group                                  │
│ ├─ Inbound: 8080 from ALB SG                              │
│ └─ Outbound: 2223-2225 to CloudHSM SG, 5432 to DB SG     │
├─────────────────────────────────────────────────────────────┤
│ CloudHSM Security Group                                     │
│ ├─ Inbound: 2223-2225 from Application SG                 │
│ └─ Outbound: None                                          │
├─────────────────────────────────────────────────────────────┤
│ Database Security Group                                     │
│ ├─ Inbound: 5432 from Application SG                      │
│ └─ Outbound: None                                          │
└─────────────────────────────────────────────────────────────┘
```

#### IAM Roles and Policies
- **CloudHSM Service Role**: Manages HSM cluster operations
- **Application Execution Role**: ECS task and Lambda execution
- **CloudHSM Client Policy**: Allows applications to interact with HSM

### 3. Compute Layer

#### ECS Cluster
- **Launch Type**: Fargate for serverless containers
- **Capacity Providers**: Mix of Fargate and Fargate Spot
- **Service Discovery**: Integrated with AWS Cloud Map
- **Auto Scaling**: Based on CPU and memory utilization

#### Task Definition
```yaml
CPU: 1024 (1 vCPU)
Memory: 2048 MB
Network Mode: awsvpc
Container:
  - Name: financial-processor
    Image: Custom Python application
    Port: 8080
    Environment:
      - CLOUDHSM_CLUSTER_ID
      - DATABASE_ENDPOINT
      - FRAUD_THRESHOLD
```

#### Lambda Functions
- **HSM Key Management**: Automated key rotation and backup
- **Compliance Reporting**: Generate audit reports
- **Monitoring**: Custom metrics and alerting

### 4. Data Layer

#### CloudHSM Cluster
- **Instance Type**: hsm1.medium
- **Deployment**: Multi-AZ for high availability
- **Security**: FIPS 140-2 Level 3 certified
- **Key Operations**:
  - Master key generation and storage
  - PIN verification
  - Transaction signing
  - Data encryption/decryption

#### RDS Database
- **Engine**: PostgreSQL 13.7
- **Instance Class**: db.t3.micro (demo sizing)
- **Storage**: 20GB GP2, encrypted at rest
- **Backup**: 7-day retention period
- **Multi-AZ**: Disabled for cost optimization (demo)

### 5. Application Layer

#### Financial Transaction Processor
```python
# Core Components
├── HSM Operations
│   ├── encrypt_pan()
│   ├── verify_pin()
│   └── sign_transaction()
├── Fraud Detection
│   ├── calculate_fraud_score()
│   ├── velocity_check()
│   └── geographic_analysis()
└── Transaction Processing
    ├── validate_input()
    ├── process_payment()
    └── log_transaction()
```

#### API Endpoints
- `GET /health`: Health check and system status
- `POST /process-transaction`: Main transaction processing
- `GET /hsm-status`: CloudHSM cluster status
- `GET /metrics`: Application performance metrics

### 6. Monitoring and Logging

#### CloudWatch Integration
- **Log Groups**:
  - `/aws/ecs/cloudhsm-financial-demo`: Application logs
  - `/aws/cloudhsm/cloudhsm-financial-demo`: HSM operation logs
- **Metrics**:
  - Transaction throughput
  - HSM operation latency
  - Error rates and fraud detection
- **Dashboards**: Real-time monitoring and alerting

#### Audit Trail
```json
{
  "transaction_id": "TXN_20250705_001",
  "timestamp": "2025-07-05T07:00:00Z",
  "hsm_operations": [
    {
      "operation": "encrypt_pan",
      "key_handle": "master_key_001",
      "result": "success",
      "latency_ms": 45
    }
  ],
  "compliance_flags": {
    "pci_dss": true,
    "fips_140_2": true
  }
}
```

## Data Flow

### Transaction Processing Flow
1. **Request Ingestion**: ALB receives transaction request
2. **Load Balancing**: Route to healthy ECS task
3. **Input Validation**: Validate transaction data
4. **HSM Operations**:
   - Encrypt PAN using master key
   - Verify PIN against stored hash
   - Generate transaction signature
5. **Fraud Detection**: Calculate risk score
6. **Authorization Decision**: Approve or decline
7. **Audit Logging**: Record all operations
8. **Response**: Return result to client

### Key Management Flow
1. **Key Generation**: HSM generates master keys
2. **Key Derivation**: Derive session keys as needed
3. **Key Rotation**: Automated rotation schedule
4. **Key Backup**: Secure backup to encrypted storage
5. **Key Recovery**: Disaster recovery procedures

## Security Considerations

### Encryption
- **Data in Transit**: TLS 1.2+ for all communications
- **Data at Rest**: AES-256 encryption for database and logs
- **Key Management**: Hardware-based key generation and storage

### Access Control
- **Network Isolation**: Private subnets for sensitive components
- **IAM Policies**: Least privilege access principles
- **Security Groups**: Restrictive firewall rules
- **VPC Endpoints**: Private connectivity to AWS services

### Compliance
- **PCI DSS**: Level 1 compliance for cardholder data
- **FIPS 140-2**: Level 3 cryptographic module
- **SOX**: Financial reporting controls
- **Audit Trails**: Immutable transaction logs

## Performance Characteristics

### Throughput
- **Target**: 1,000 transactions per second
- **HSM Capacity**: 10,000 operations per second per instance
- **Database**: 1,000 IOPS baseline performance

### Latency
- **End-to-End**: < 200ms for transaction processing
- **HSM Operations**: < 50ms per cryptographic operation
- **Database Queries**: < 10ms for simple operations

### Availability
- **Target SLA**: 99.95% uptime
- **RTO**: < 5 minutes (Recovery Time Objective)
- **RPO**: < 1 minute (Recovery Point Objective)

## Scalability

### Horizontal Scaling
- **ECS Services**: Auto-scaling based on metrics
- **CloudHSM**: Add instances to cluster for capacity
- **Database**: Read replicas for read scaling

### Vertical Scaling
- **ECS Tasks**: Increase CPU/memory allocation
- **Database**: Upgrade instance class
- **HSM**: Upgrade to larger instance types

## Disaster Recovery

### Backup Strategy
- **Database**: Automated daily backups with 7-day retention
- **HSM Keys**: Encrypted backup to S3
- **Application Code**: Version control and CI/CD pipeline

### Recovery Procedures
1. **Infrastructure**: CloudFormation stack recreation
2. **HSM Cluster**: Restore from backup certificates
3. **Database**: Point-in-time recovery
4. **Application**: Deploy from container registry

This architecture provides a robust, secure, and scalable foundation for financial transaction processing while maintaining compliance with industry standards and regulations.
