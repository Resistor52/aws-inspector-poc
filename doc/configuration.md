# Configure your AWS Profile Parameters

First, make a copy of **setup.example.conf** as **setup.conf** as follows:
```
$ cp setup.example.conf setup.conf
```

Next, edit **setup.conf** by replacing the characters to the right of the equal sign as appropriate for your environment.

```
AWS_DEFAULT_PROFILE=999999999999                          # Name of Profile to Use
EC2_KEY_PAIR=AAAAAAAAA                                    # Name of Key Pair in EC2
LOCAL_PEM=~/.ssh/AAAAAAAAA.pem                            # Needs full path to PEM file, without quotes
REGION=us-east-1                                          # Must be a valid AWS Region
LINUX_IMAGEID=ami-c58c1dd3                                # AMI Must exist in the AWS Region
ACCOUNT=111111111111                                      # AWS Account ID Number
```

NOTE: Do not include quotes or use variables in setup.conf

For additional information see:

http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html

http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html
