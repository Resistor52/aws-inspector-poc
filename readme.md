# Demonstration of using AWS inspector with the Command Line Interface

## Instructions

To use the demonstration environment in AWS, enter the following command:
```
./setup.sh # Set up the environment and run a vuln scan
```

To use it you must [configure your AWS Profile Parameters](../master/doc/configuration.md)
in **setup.conf**.

`./teardown.sh` will delete all EC2 instances, the VPC, and other objects created
by the aws-setup script with the help of the .log files created during setup.

## description
This proof-of-concept creates a single EC2 instance in a dedicated VPC, complete
with security groups, routing and everything necessary to deploy via script.

The script detects your external IP address and restricts inbound access to only
that address on port 22 (SSH).

At the end of the script a vulnerability scan is performed on the EC2 instance
automatically. It is scheduled to run for 15 minutes.  When it is complete a PDF
of the scan findings can be downloaded via the Inspector Console.

[Here](../master/doc/AWS_Inspector_Vuln_Findings.pdf) is an example of the report that AWS generates.
