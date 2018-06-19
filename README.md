# Ec2SpaceWatcher

Ec2SpaceWatcher scans the available space on your ec2 instances and dynamically adds ebs volumes and regrows your data drive when some thresholds are crossed. 

tested on cc2, c4, c5 instances.

1. create an IAM instance profile that allows the instance create, list, attach and delete volumes.
2. launch instance with profile

3. clone this repo

```
apt install awscli
./ec2spacewatcher.bash
```

your instance will now be able to dynamically regrow its /media/ebs partition
