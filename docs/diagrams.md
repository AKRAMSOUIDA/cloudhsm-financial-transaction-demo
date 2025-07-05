# Architecture Diagrams

This document contains detailed architecture diagrams for the CloudHSM Financial Transaction Processing Demo.

## High-Level Architecture

```mermaid
graph TB
    subgraph "Internet"
        Client[👤 Client/POS Terminal]
    end
    
    subgraph "AWS Cloud"
        subgraph "VPC (10.0.0.0/16)"
            subgraph "Public Subnet (10.0.3.0/24)"
                ALB[🔄 Application Load Balancer<br/>AWS ALB]
                NAT[🌐 NAT Gateway<br/>AWS NAT]
            end
            
            subgraph "Private Subnet 1 (10.0.1.0/24)"
                HSM1[🔐 CloudHSM Instance 1<br/>FIPS 140-2 Level 3]
                ECS1[📦 ECS Tasks<br/>Financial Processor]
                Lambda1[⚡ Lambda Functions<br/>Key Management]
            end
            
            subgraph "Private Subnet 2 (10.0.2.0/24)"
                HSM2[🔐 CloudHSM Instance 2<br/>FIPS 140-2 Level 3]
                RDS[🗄️ RDS PostgreSQL<br/>Encrypted Database]
            end
        end
        
        subgraph "AWS Services"
            CloudWatch[📊 CloudWatch<br/>Monitoring & Logs]
            KMS[🔑 AWS KMS<br/>Key Management]
            Secrets[🔒 Secrets Manager<br/>Credentials]
            IAM[👥 AWS IAM<br/>Access Control]
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

## Transaction Processing Flow

```mermaid
sequenceDiagram
    participant C as 👤 Customer
    participant P as 🏪 POS Terminal
    participant A as 🔄 ALB
    participant E as 📦 ECS Service
    participant H as 🔐 CloudHSM
    participant D as 🗄️ Database
    participant L as 📊 CloudWatch
    
    C->>P: 1. Swipe Card & Enter PIN
    P->>A: 2. Send Transaction Request
    A->>E: 3. Route to ECS Task
    
    Note over E,H: HSM Cryptographic Operations
    E->>H: 4a. Encrypt PAN
    H-->>E: 4b. Encrypted PAN
    E->>H: 5a. Verify PIN
    H-->>E: 5b. PIN Valid/Invalid
    E->>H: 6a. Sign Transaction
    H-->>E: 6b. Digital Signature
    
    Note over E: Fraud Detection Analysis
    E->>E: 7. Calculate Fraud Score
    
    alt Transaction Approved
        E->>D: 8a. Store Transaction
        E->>L: 9a. Log Success
        E-->>A: 10a. APPROVED Response
    else Transaction Declined
        E->>L: 9b. Log Decline Reason
        E-->>A: 10b. DECLINED Response
    end
    
    A-->>P: 11. Authorization Response
    P-->>C: 12. Display Result
```

## Security Architecture

```mermaid
graph TB
    subgraph "Security Layers"
        subgraph "Network Security"
            VPC[🏢 VPC Isolation<br/>Private Subnets]
            SG[🛡️ Security Groups<br/>Firewall Rules]
            NACL[🚧 Network ACLs<br/>Subnet Protection]
        end
        
        subgraph "Application Security"
            WAF[🛡️ AWS WAF<br/>Web Application Firewall]
            ALB_SSL[🔒 ALB SSL/TLS<br/>Certificate Management]
            ECS_SEC[📦 ECS Security<br/>Task Isolation]
        end
        
        subgraph "Data Security"
            HSM[🔐 CloudHSM<br/>FIPS 140-2 Level 3]
            KMS[🔑 AWS KMS<br/>Envelope Encryption]
            RDS_ENC[🗄️ RDS Encryption<br/>At Rest & Transit]
        end
        
        subgraph "Access Control"
            IAM[👥 AWS IAM<br/>Role-Based Access]
            SECRETS[🔒 Secrets Manager<br/>Credential Rotation]
            AUDIT[📋 CloudTrail<br/>API Audit Logs]
        end
    end
    
    style HSM fill:#ff6b6b,stroke:#d63031,stroke-width:3px
    style KMS fill:#fdcb6e,stroke:#e17055,stroke-width:2px
    style IAM fill:#6c5ce7,stroke:#5f3dc4,stroke-width:2px
    style WAF fill:#00b894,stroke:#00a085,stroke-width:2px
```

## Data Flow Architecture

```mermaid
flowchart TD
    subgraph "Data Processing Pipeline"
        A[📥 Transaction Input] --> B{🔍 Input Validation}
        B -->|Valid| C[🔐 HSM Encryption]
        B -->|Invalid| Z[❌ Reject Transaction]
        
        C --> D[🔑 PIN Verification]
        D -->|Valid PIN| E[✍️ Digital Signature]
        D -->|Invalid PIN| Y[❌ Decline - Invalid PIN]
        
        E --> F[🕵️ Fraud Detection]
        F -->|Low Risk| G[✅ Approve Transaction]
        F -->|High Risk| X[❌ Decline - Fraud Detected]
        
        G --> H[💾 Store in Database]
        H --> I[📊 Log to CloudWatch]
        I --> J[📤 Return Response]
        
        Y --> I
        X --> I
        Z --> I
    end
    
    subgraph "HSM Operations"
        K[🔐 Master Key Storage]
        L[🔄 Key Derivation]
        M[🔒 Encryption/Decryption]
        N[✍️ Digital Signing]
    end
    
    C -.-> K
    C -.-> L
    C -.-> M
    E -.-> N
    
    style K fill:#ff6b6b,stroke:#d63031,stroke-width:3px
    style L fill:#ff6b6b,stroke:#d63031,stroke-width:3px
    style M fill:#ff6b6b,stroke:#d63031,stroke-width:3px
    style N fill:#ff6b6b,stroke:#d63031,stroke-width:3px
```

## Compliance Framework

```mermaid
mindmap
  root((🏛️ Compliance<br/>Framework))
    🔐 FIPS 140-2 Level 3
      Hardware Security Module
      Tamper Evidence
      Cryptographic Boundary
      Key Management
    💳 PCI DSS Level 1
      Cardholder Data Protection
      Secure Network Architecture
      Access Control Measures
      Regular Security Testing
    📊 SOX Compliance
      Financial Reporting Controls
      Audit Trail Requirements
      Change Management
      Risk Assessment
    🛡️ GDPR Ready
      Data Protection by Design
      Right to be Forgotten
      Data Minimization
      Consent Management
    🏢 Enterprise Security
      Zero Trust Architecture
      Least Privilege Access
      Defense in Depth
      Continuous Monitoring
```

## Monitoring and Observability

```mermaid
graph TB
    subgraph "Monitoring Stack"
        subgraph "Metrics Collection"
            CW[📊 CloudWatch Metrics<br/>System Performance]
            XR[🔍 X-Ray Tracing<br/>Request Tracking]
            CI[📈 Container Insights<br/>ECS Monitoring]
        end
        
        subgraph "Log Aggregation"
            CWL[📝 CloudWatch Logs<br/>Application Logs]
            HSM_L[🔐 HSM Audit Logs<br/>Cryptographic Operations]
            ALB_L[🔄 ALB Access Logs<br/>Request Patterns]
        end
        
        subgraph "Alerting & Dashboards"
            SNS[📢 SNS Notifications<br/>Alert Delivery]
            DASH[📊 CloudWatch Dashboards<br/>Real-time Monitoring]
            ALARM[🚨 CloudWatch Alarms<br/>Threshold Monitoring]
        end
        
        subgraph "Compliance Monitoring"
            CT[📋 CloudTrail<br/>API Audit Logs]
            CONFIG[⚙️ AWS Config<br/>Resource Compliance]
            SEC_HUB[🛡️ Security Hub<br/>Security Posture]
        end
    end
    
    CW --> DASH
    CWL --> DASH
    HSM_L --> DASH
    CW --> ALARM
    ALARM --> SNS
    CT --> SEC_HUB
    CONFIG --> SEC_HUB
    
    style HSM_L fill:#ff6b6b,stroke:#d63031,stroke-width:3px
    style DASH fill:#74b9ff,stroke:#0984e3,stroke-width:2px
    style SEC_HUB fill:#00b894,stroke:#00a085,stroke-width:2px
```

## Disaster Recovery Architecture

```mermaid
graph TB
    subgraph "Primary Region (us-east-1)"
        subgraph "Production Environment"
            HSM_P1[🔐 CloudHSM Primary]
            ECS_P1[📦 ECS Cluster Primary]
            RDS_P1[🗄️ RDS Primary]
        end
    end
    
    subgraph "Secondary Region (us-west-2)"
        subgraph "DR Environment"
            HSM_DR[🔐 CloudHSM DR]
            ECS_DR[📦 ECS Cluster DR]
            RDS_DR[🗄️ RDS Read Replica]
        end
    end
    
    subgraph "Backup & Recovery"
        S3_BACKUP[🪣 S3 Cross-Region<br/>Backup Storage]
        PARAM_STORE[⚙️ Parameter Store<br/>Configuration Sync]
        SECRETS_REP[🔒 Secrets Manager<br/>Cross-Region Replication]
    end
    
    HSM_P1 -.->|Key Backup| S3_BACKUP
    RDS_P1 -.->|Continuous Replication| RDS_DR
    ECS_P1 -.->|Config Sync| PARAM_STORE
    
    S3_BACKUP -.->|Key Restore| HSM_DR
    PARAM_STORE -.->|Config Deploy| ECS_DR
    SECRETS_REP -.->|Credential Sync| ECS_DR
    
    style HSM_P1 fill:#ff6b6b,stroke:#d63031,stroke-width:3px
    style HSM_DR fill:#ff6b6b,stroke:#d63031,stroke-width:3px
    style S3_BACKUP fill:#fd79a8,stroke:#e84393,stroke-width:2px
```

## Cost Optimization Strategy

```mermaid
pie title Monthly Cost Breakdown ($2,500 Total)
    "CloudHSM Cluster (2 instances)" : 2400
    "ECS Fargate" : 50
    "RDS Database" : 25
    "Application Load Balancer" : 20
    "Data Transfer & Misc" : 5
```

```mermaid
graph LR
    subgraph "Cost Optimization Techniques"
        A[💰 Cost Savings] --> B[🎯 Fargate Spot<br/>70% Savings]
        A --> C[📏 Right-sizing<br/>Resource Optimization]
        A --> D[📊 Reserved Instances<br/>Predictable Workloads]
        A --> E[🗂️ Log Retention<br/>Policy Management]
        A --> F[⏰ Scheduled Scaling<br/>Off-hours Reduction]
    end
    
    style A fill:#00b894,stroke:#00a085,stroke-width:3px
    style B fill:#fdcb6e,stroke:#e17055,stroke-width:2px
    style C fill:#74b9ff,stroke:#0984e3,stroke-width:2px
```

## Legend

| Symbol | AWS Service | Description |
|--------|-------------|-------------|
| 🔐 | CloudHSM | Hardware Security Module |
| 📦 | ECS | Elastic Container Service |
| 🔄 | ALB | Application Load Balancer |
| 🗄️ | RDS | Relational Database Service |
| ⚡ | Lambda | Serverless Functions |
| 📊 | CloudWatch | Monitoring & Logging |
| 🔑 | KMS | Key Management Service |
| 🔒 | Secrets Manager | Credential Management |
| 👥 | IAM | Identity & Access Management |
| 🛡️ | WAF | Web Application Firewall |
| 📋 | CloudTrail | API Audit Logging |
| 🪣 | S3 | Simple Storage Service |

---

*All diagrams follow AWS Well-Architected Framework principles and represent production-ready architecture patterns.*
