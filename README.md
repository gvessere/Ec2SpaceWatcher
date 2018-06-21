# Ec2SpaceWatcher

Ec2SpaceWatcher scans the available space on your ec2 instances and dynamically adds ebs volumes and regrows your data drive when some thresholds are crossed. 

#### Quick Start:

1. Create an IAM instance profile that allows the instance create, attach volumes, modify instance attributes, create tags.
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ec2:CreateVolume",
                "ec2:AttachVolume",
                "ec2:ModifyInstanceAttribute",
                "ec2:CreateTags",
            ],
            "Resource": "*"
        }
    ]
}
```
2. Launch instance with profile, make sure to attach instance store drives if you plan on using them for your first array.

3. Clone this repo

```
apt install awscli
./ec2spacewatcher.bash
```

your instance will now be able to dynamically regrow its /media/ebs partition

#### lvme, ebs, and instance store drives

On instance store instances the instance local drives will be used first, make sure to attach all the instance store drives on launch.

On other types of instance Ec2SpaceWatcher will be able to deal with both and nvme and regular ebs drives.

tested on cc2, c4, c5 instances.

