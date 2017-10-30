#!/bin/bash

# Reference: https://docs.aws.amazon.com/inspector/latest/userguide/inspector_quickstart.html

# Set Default Profile.  This assumes that you have followed these steps:
# https://github.com/Resistor52/aws-inspector-poc/blob/master/configuration.md
export AWS_DEFAULT_PROFILE=$(cat setup.conf | grep "AWS_DEFAULT_PROFILE" | cut -d" " -f1 | cut -d"=" -f2)
export EC2_KEY_PAIR=$(cat setup.conf | grep "EC2_KEY_PAIR" | cut -d" " -f1 | cut -d"=" -f2)
export LOCAL_PEM=$(cat setup.conf | grep "LOCAL_PEM" | cut -d" " -f1 | cut -d"=" -f2)
export REGION=$(cat setup.conf | grep "REGION" | cut -d" " -f1 | cut -d"=" -f2)
export LINUX_IMAGEID=$(cat setup.conf | grep "LINUX_IMAGEID" | cut -d" " -f1 | cut -d"=" -f2)
export ACCOUNT=$(cat setup.conf | grep "ACCOUNT" | cut -d" " -f1 | cut -d"=" -f2)

# Get External IP Address for Configuration
MY_EXTERNAL_IP=$(curl -s icanhazip.com)
OUTPUT=$(echo $MY_EXTERNAL_IP | cut -d"." -f4 | wc -c)
if [ $OUTPUT == 1 ] || [ $OUTPUT -gt 4 ] # As a test of validity, check 4th octet string size
#if [ $OUTPUT -gt 4 ] # As a test of validity, check 4th octet string size
then
echo "*****ERROR - Unable to obtain a valid external IP Address for configuration. Result: "$MY_EXTERNAL_IP
exit 1
fi

# Test Profile Parameters
function test_config_file {
OUTPUT=$(cat setup.conf | grep $1 | wc -c)
if [ $OUTPUT == 0 ]
then
echo " "
echo "*****ERROR - Unable to find the $1 parameter in setup.config. See \
https://github.com/Resistor52/aws-inspector-poc/blob/master/configuration.md and \
http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html for more information"
exit 1
fi
}
PARAMETER_LIST=$(cat setup.example.conf | cut -d"=" -f1)
for PARAMETER in $PARAMETER_LIST; do
  test_config_file $PARAMETER
done
OUTPUT=$(cat ~/.aws/config | grep $AWS_DEFAULT_PROFILE | wc -c)
if [ $OUTPUT == 0 ]
then
echo " "
echo "*****ERROR - Unable to find a profile in ~/.aws/config that matches the AWS_DEFAULT_PROFILE parameter set in \
this script. See https://github.com/Resistor52/aws-inspector-poc/blob/master/configuration.md and \
http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html for more information"
exit 1
fi
OUTPUT=$(cat ~/.aws/credentials | grep $AWS_DEFAULT_PROFILE | wc -c)
if [ $OUTPUT == 0 ]
then
echo " "
echo "*****ERROR - Unable to find a profile in ~/.aws/credentials that matches the AWS_DEFAULT_PROFILE parameter set in \
this script. See https://github.com/Resistor52/aws-inspector-poc/blob/master/configuration.md and \
http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html for more information"
exit 1
fi
REGIONLIST=(
    'us-east-2'
    'us-east-1'
    'us-west-1'
    'us-west-2'
    'ca-central-1'
    'ap-south-1'
    'ap-northeast-2'
    'ap-southeast-1'
    'ap-southeast-2'
    'ap-northeast-1'
    'eu-central-1'
    'eu-west-1'
    'eu-west-2'
    'sa-east-1'
    )
if [[ ! " ${REGIONLIST[@]} " =~ " ${REGION} " ]];
then
echo "*****ERROR - The REGION parameter set in this script is invalid.  For valid us-east-1s, See \
http://docs.aws.amazon.com/general/latest/gr/rande.html#ssm_us-east-1"
fi
OUTPUT=$(aws ec2 describe-key-pairs --profile $AWS_DEFAULT_PROFILE --region $REGION | grep $EC2_KEY_PAIR | wc -c)
if [ $OUTPUT == 0 ]
then
echo " "
echo "*****ERROR - Unable to find an EC2 Key Pair that matches the EC2_KEY_PAIR parameter set in \
this script. See https://github.com/Resistor52/aws-inspector-poc/blob/master/configuration.md and \
http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html for more information"
exit 1
fi
if [ -e $LOCAL_PEM ]
then
echo "Profile Parameters Test Completed"
else
echo "*****ERROR - Unable to find the local PEM file that matches the LOCAL_PEM parameter set in \
this script. See https://github.com/Resistor52/aws-inspector-poc/blob/master/configuration.md and \
http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html for more information"
exit 1
fi

#***************** Remove Inspector Role *****************
echo; echo "Detach the Inspector Service Role Policies"
aws iam detach-role-policy --role-name inspector-service-role \
  --policy-arn arn:aws:iam::$ACCOUNT:policy/inspector-role-policy

echo; echo "Delete the Inspector Service Role Policy"
aws iam delete-policy --policy-arn arn:aws:iam::$ACCOUNT:policy/inspector-role-policy
echo; echo "Delete the IAM Role for AWS Inspector Service"
aws iam delete-role --role-name inspector-service-role

#***************** Teardown Assets *****************
# Initiate Teardown
VPC=$(cat temp/vpc.log)
INSTANCES=$(cat temp/instance.log)
IGW=$(cat temp/igw.log)
RTBL=$(cat temp/route-table.log)

echo; echo "Terminate Instances: "
aws ec2 terminate-instances --instance-ids $INSTANCES | grep "TERMINATINGINSTANCES | cut -f2"
OUTPUT=2
echo "Waiting for EC2 Instance termination process to complete. This may \
take a few minutes...please wait"
while [ $OUTPUT != 1 ]; do
#  STRING=$(aws ec2 describe-instance-status --instance-ids $INSTANCES --output text --region $REGION \
#   --profile $AWS_DEFAULT_PROFILE)
   STRING=$(aws ec2 terminate-instances --instance-ids $INSTANCES --output text --region $REGION \
   --profile $AWS_DEFAULT_PROFILE | grep "CURRENTSTATE" | grep -v "terminated")
  OUTPUT=$(echo $STRING | wc -c)
  printf "."
	if [ $OUTPUT != 1 ]; then
		sleep 10
	fi
done
echo; echo "EC2 Instance termination process is complete."
# Security Groups
echo; echo "Delete Security Groups: "
SECGROUPS=$(aws ec2 describe-security-groups --region $REGION | grep $VPC | grep -v "default" | cut -f3)
for SGX in $SECGROUPS; do
  aws ec2 delete-security-group --group-id $SGX
  echo $SGX" deleted"
done
# Detach Internet Gateway
echo; echo "Detach Internet Gateway: "
aws ec2 detach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC
echo $IGW" detached"
# Internet Gateway
echo; echo "Delete Internet Gateway: "
aws ec2 delete-internet-gateway --internet-gateway-id $IGW
echo $IGW" deleted"
# Subnets
echo; echo "Delete Subnets: "
SUBNETS=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$VPC | cut -f9)
for SUBX in $SUBNETS; do
  aws ec2 delete-subnet --subnet-id $SUBX
  echo $SUBX" deleted"
done
# Routes
echo; echo "Delete Routes: "
aws ec2 delete-route --route-table-id $RTBL --destination-cidr-block 0.0.0.0/0
echo "0.0.0.0/0 in $RTBL deleted"

# Routetable
echo; echo "Delete Route Tables: "
aws ec2 delete-route-table --route-table-id $RTBL
echo $RTBL" deleted"

echo; echo "Terminate VPC: "
aws ec2 delete-vpc --vpc-id $VPC
OUTPUT=2
echo; echo "Waiting for VPC termination process to complete. This may \
take a few minutes...please wait"
while [ $OUTPUT != 1 ]; do
  STRING=$(aws ec2 describe-vpcs --vpc-ids $VPC --output text --region $REGION \
  --profile $AWS_DEFAULT_PROFILE 2>/dev/null)
  echo $STRING
  OUTPUT=$(echo $STRING | wc -c)
  printf "."
	if [ "$OUTPUT" != 1 ]; then
		sleep 10
	fi
done
echo; echo "VPC termination process is complete."

echo; echo "Delete the Assessment Run"
OUTPUT=$(cat temp/assessment-run.log)
aws inspector delete-assessment-run --assessment-run-arn $OUTPUT

echo; echo "Delete the Assessment Template"
OUTPUT=$(cat temp/assessment-template.log)
aws inspector delete-assessment-template --assessment-template-arn $OUTPUT

echo; echo "Delete the Assessment Target"
OUTPUT=$(cat temp/assessment-target.log)
aws inspector delete-assessment-target --assessment-target-arn $OUTPUT 


rm temp/*

echo; echo "Teardown has completed.  To ensure that you do not incure unexpected \
AWS charges, verify using the AWS console"
