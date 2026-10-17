# AWS cloud security skill acquisition progression

*Practical evidence assessment — 13 October 2026*

## Purpose
This report evaluates the evidence demonstrated in the AWS Terraform security lab against twelve recommended AWS cloud-security knowledge areas. Statuses describe evidence observed in this lab, not a broader certification or enterprise-scale cloud security assessment.

## Your 12-point assessment

Assessment based on lab progress as of 13 October 2026.

### 1. Shared responsibility model

**Status: Partially demonstrated**

Your lab uses AWS-managed infrastructure while you configure guest access, IAM, network controls and instance security. That gives you practical examples of the division of responsibility, but you have not yet examined broader organisational responsibilities, shared-control boundaries or operational governance at scale.

### 2. Managing identity at scale

**Status: Partially demonstrated**

You configured dedicated EC2 roles and instance profiles, attached `AmazonSSMManagedInstanceCore`, and restored SSM connectivity by investigating endpoint access. This is real workload identity management in practice and a useful demonstration of role-based access design, but it does not yet cover broader identity governance or enterprise-scale IAM patterns.

### 3. Multi-account governance

**Status: Not demonstrated**

The lab operates in one AWS account. There is no demonstrated AWS Organizations structure, Service Control Policies, delegated security administration or centralised multi-account governance.

### 4. Software supply chain risks

**Status: Not demonstrated**

Terraform provides infrastructure as code, but we haven't examined provider and module provenance, dependency pinning and integrity, CI/CD security, image provenance, or software bill of materials.

### 5. Incident prevention and response

**Status: Partially demonstrated**

Your network segmentation, restricted security-group rules, private application subnet and Session Manager access demonstrate preventative controls and a secure administration approach. We haven't run a formal detection or response exercise across logs, alerts and recovery activities, so the response aspect remains partial.

### 6. Cloud vulnerability management

**Status: Not demonstrated**

We haven't assessed EC2 vulnerabilities, scanned images, reviewed installed packages against known CVEs, or demonstrated patch prioritisation and remediation verification.

### 7. Firewall rules at layers 3–7

**Status: Directly demonstrated at L3–L4**

You configured VPC CIDRs, subnet routes and security groups, then tested TCP 8080 and TCP 22. You also inspected the private route table and controlled TCP 443 access to Systems Manager endpoints.

The qualification: these are strong network-layer and transport-layer examples. You haven't yet demonstrated application-layer (L7) controls such as AWS WAF, HTTP request filtering or centralised firewall management.

### 8. Incident root cause analysis

**Status: Partially demonstrated**

Your investigation of the SSM connection failure is a practical example of troubleshooting: you inspected live rules, identified that the endpoint security group lacked client ingress on TCP 443, applied a targeted fix and verified connectivity. That is a credible, small-scale root-cause investigation.

This is a credible, small-scale root-cause investigation. It isn't yet a full incident RCA involving a formal timeline, audit logs, impact analysis, contributing factors and preventive actions.

### 9. Responding to an audit

**Status: Not demonstrated**

Your updated lab report is useful technical documentation, but we haven't performed an audit exercise: collecting evidence against controls, identifying gaps, documenting exceptions or presenting remediation recommendations.

### 10. Logging and monitoring strategies

**Status: Partially demonstrated**

You've used AWS CLI inspection, EC2 health checks, SSM managed-instance status and terminal output to observe system behaviour. Those are operational observations, but we haven't configured a deliberate log architecture, alert flow or central monitoring strategy.

### 11. Encryption at rest and in transit

**Status: Partially demonstrated**

Your EC2 root volumes use encryption, and you tested HTTPS connectivity to AWS endpoints and a public website. These are relevant examples of encryption controls.

We haven't yet inspected the KMS key configuration, key policies and rotation, or demonstrated and verified TLS for your own application. A successful HTTPS test demonstrates a TLS connection; it does not yet validate end-to-end encryption design for a custom workload.

### 12. Disaster recovery and backups

**Status: Not demonstrated**

You created backups of local Terraform files and state before changes. That's good change-management practice, but it is not evidence of AWS workload disaster recovery. We haven't configured AWS backup or restore processes with explicit recovery objectives and tested recovery validity.

## Summary

- **Directly demonstrated:** 1 area — firewall rules at layers 3–4.
- **Partially demonstrated:** 6 areas — shared responsibility; identity at scale; incident prevention and response; incident root cause analysis; logging and monitoring; encryption at rest and in transit.
- **Not demonstrated:** 5 areas — multi-account governance; software supply chain risks; cloud vulnerability management; responding to an audit; disaster recovery and AWS workload backups.

These are evidence classifications rather than equal-weight competency scores. The categories overlap, and “not demonstrated” means the lab has not yet produced evidence for that area; it does not mean the skill is impossible or irrelevant.

## Conclusion

This lab provides clear, evidence-based demonstrations of AWS networking and access-control skills, including VPC design, routing, security groups, EC2 roles and instance profiles, and SSM troubleshooting, and shows practical progress in identity management, incident investigation, logging and monitoring, and encryption. It documents explored controls and observed behaviour and identifies focused next steps, including multi-account governance, software supply-chain checks, vulnerability scanning and remediation, audit evidence collection, and backup-and-restore validation. It also points to a longer-term path toward a full-scale system design.

## Suggested next steps

1. Complete the network investigation with VPC Reachability Analyzer and, if appropriate, VPC Flow Logs.
2. Build a controlled detection and incident-investigation exercise using CloudTrail and selected CloudWatch or VPC Flow Logs.
3. Inspect KMS and EBS encryption settings, run a controlled vulnerability assessment, and complete a backup-and-restore exercise with explicit recovery criteria.
4. Extend the lab into multi-account governance, audit evidence collection, and software supply-chain security, and eventually work towards a full-scale system design.
