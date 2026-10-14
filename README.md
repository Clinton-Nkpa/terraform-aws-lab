# AWS Cloud Security Lab

**Status:** In progress  
**Focus:** AWS infrastructure security, network segmentation, IAM, secure administration, and evidence-led troubleshooting  
**Stack:** AWS, Terraform, AWS CLI, Linux, EC2, VPC, IAM, AWS Systems Manager

## Overview

A hands-on AWS security lab provisioned with Terraform to investigate network segmentation, least-privilege access paths, and private workload administration. The environment uses a VPC with separate client and private application subnets, security groups, route tables, EC2 instance roles, and Systems Manager interface endpoints.

This repository entry documents work completed to date. It does not claim a production deployment or a completed security audit.

## Implemented and tested

- Provisioned a VPC using CIDR `10.20.0.0/16`, with a client subnet (`10.20.1.0/24`) and private application subnet (`10.20.2.0/24`).
- Configured route tables to provide the client subnet with an Internet Gateway route while the private application subnet had only the VPC-local route.
- Deployed separate client and private application EC2 instances.
- Configured dedicated instance roles and instance profiles, including `AmazonSSMManagedInstanceCore`, to support Systems Manager access.
- Required IMDSv2 and used encrypted EBS root volumes.
- Used Systems Manager Session Manager to administer instances without opening inbound SSH access.
- Verified client-to-application TCP 8080 connectivity with a successful HTTP 200 response.
- Tested TCP 22 from the client; the connection timed out, consistent with the application security group having no inbound TCP 22 rule. The timeout alone does not prove which network control dropped the traffic.
- Investigated an SSM connectivity failure by inspecting live security-group rules. A missing TCP 443 ingress permission from the client security group to the SSM endpoint security group was corrected, after which SSM connectivity was verified.
- Tested public HTTPS from the private application instance; the request timed out, consistent with the private route table and restricted egress policy. Further path analysis remains planned.

## Security design notes

- The client subnet is public-routed and can receive public IPv4 addresses; the client security group has no inbound rules.
- The application instance has no public IPv4 address.
- The application security group allows inbound TCP 8080 from the client security group and restricts outbound HTTPS to the endpoint security group.
- The SSM endpoint security group allows HTTPS from the lab client and application security groups.
- The client security group's HTTPS egress is currently broad to `0.0.0.0/0`; reviewing whether this can be narrowed is a follow-up hardening task.

## Evidence and limitations

Observed tests and AWS configuration inspections support the findings above. Connectivity timeouts are treated as observations, not definitive proof of a specific dropped packet or control. Reachability Analyzer and VPC Flow Logs have not yet been used to corroborate the network paths.

The temporary Python HTTP server used for TCP 8080 validation returned a directory listing and was intended only for a short-lived test, not as a production application.

## Planned work

1. Use VPC Reachability Analyzer to analyse the client-to-application paths for TCP 8080 and TCP 22.
2. Enable and inspect VPC Flow Logs to correlate observed traffic with the configured controls.
3. Extend the lab into CloudTrail-based investigation and AWS security monitoring.
4. Review KMS key management, vulnerability management, audit evidence, software supply-chain risks, and backup/restore testing.
5. Review least-privilege egress and remove or recreate billable lab resources deliberately when they are not needed.

## Reproducibility and security

The Terraform configuration and execution evidence should be committed alongside this document after review and sanitisation. Do not commit Terraform state files, state backups, AWS credentials, private keys, session tokens, or unredacted account-specific output. Check plans before applying changes and avoid committing secrets or sensitive resource metadata.
