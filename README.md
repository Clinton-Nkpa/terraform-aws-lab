# AWS Cloud Security Lab

**Status:** In progress

## Why I'm working on this

I built this lab to practise AWS network security with Terraform and keep a record of what happens when I test the network paths. I’m using a client instance and a private app instance to look at routing, security group rules, and Systems Manager access.

This is a learning lab. The results describe what I tested so far; they aren’t a production deployment or a completed audit.

## Current setup

- A VPC with a client subnet (`10.20.1.0/24`) and a private app subnet (`10.20.2.0/24`).
- The client subnet has a route to an Internet Gateway and can get a public IPv4 address. The app instance has no public IPv4 address.
- Separate security groups for the client, app, and Systems Manager interface endpoints.
- EC2 instance roles for Systems Manager. Both instances require IMDSv2 and use encrypted EBS root volumes.
- Session Manager for administration, with no inbound SSH rule.

## What I've tested

- **Client to app on TCP 8080:** the connection worked and the temporary HTTP server returned `200 OK`.
- **Client to app on TCP 22:** the connection timed out. The app security group has no inbound TCP 22 rule. The timeout is consistent with that rule set, but on its own it doesn’t show exactly where the traffic was dropped.
- **Public HTTPS from the private app:** DNS resolved, but the IPv4 connection timed out and IPv6 was unreachable. The private subnet route table has only the VPC-local route. I still want to check the path with Reachability Analyzer or Flow Logs.
- **Systems Manager:** I opened Session Manager sessions to the instances. While troubleshooting, I found the endpoint security group was missing TCP 443 ingress from the client security group. I added the rule, and the client then came back online in Systems Manager. That timing points to the rule as the fix, though it doesn’t prove it was the only cause.

I initially ran one HTTPS test from the client by mistake. It returned `200 OK`, but it didn’t test the private app’s egress. I repeated the test from the app and left the first result out of the app findings.

## Things I still want to look at

- Use Reachability Analyzer for the client-to-app paths on TCP 8080 and TCP 22.
- Enable and inspect VPC Flow Logs, then compare them with the tests above.
- Review the client’s TCP 443 egress. It currently allows HTTPS to `0.0.0.0/0`; I want to see whether I can narrow it without breaking Session Manager.
- Stop the temporary HTTP server and review the AWS resources for cleanup and ongoing costs.
- Continue into CloudTrail, vulnerability management, key management, and backup testing.

## Files

- [`main.tf`](main.tf) contains the Terraform configuration.
- [`docs/network-security-lab-report.md`](docs/network-security-lab-report.md) has the test notes and evidence. AWS resource IDs and individual host IPs have been removed from this copy.
- [`docs/aws-cloud-security-skill-progression.md`](docs/aws-cloud-security-skill-progression.md) tracks the areas I’ve covered and what I still need to learn.

I’ve left Terraform state, saved plans, AWS console output, and local snapshots out of this repository.
