# psittacid-dist-review
Literature review of the application of species distribution model for Psittacid species


```sh
source load-env.sh
sudo mkdir /var/www/html/litrev
sudo chown jferrer.jferrer /var/www/html/litrev

##
ln -s $SCRIPTDIR/web/ /var/www/html/litrev
```


# local database backup
```sh
cd $WORKDIR
pg_dump -d litrev   -n public -n psit > $(date +%Y%m%d)-litrev.sql
```

 upload to AWS RDS for testing

```sh
sed -e s/jferrer/postgres/g $(date +%Y%m%d)-litrev.sql > export-litrev.sql
psql -U postgres -h literature-review.c9ldkr8elxog.ap-southeast-2.rds.amazonaws.com -d litrev -v ON_ERROR_STOP=1 < export-litrev.sql


1:33pm
Using elasticbeanstalk-ap-southeast-2-572174861211 as Amazon S3 storage bucket for environment data

1:34pm
Environment health has transitioned to Pending. Initialization in progress (running for 32 seconds). There are no instances.
1:34pm
Created Auto Scaling launch configuration named:
awseb-e-8et3a9m3zw-stack-AWSEBAutoScalingLaunchConfiguration-W1RP1V9I767M
1:34pm
Created security group named:
awseb-e-8et3a9m3zw-stack-AWSEBSecurityGroup-VI7ED6E023PO
1:33pm
Created security group named:
sg-0d41ce4fa05d9b39e
1:33pm
Created target group named:
arn:aws:elasticloadbalancing:ap-southeast-2:572174861211:targetgroup/awseb-AWSEB-1UUL89CRVHXG8/6217bf9a7067e2e7
1:33pm
Using elasticbeanstalk-ap-southeast-2-572174861211 as Amazon S3 storage bucket for environment data.
1:33pm
createEnvironment is starting.
```
