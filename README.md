# psittacid-dist-review
Literature review of the application of species distribution model for Psittacid species


create a new eb env
```sh
cd $WORKDIR
mkdir lit-rev-app
cd $WORKDIR/lit-rev-app

echo 'export PATH="/home/jferrer/.ebcli-virtual-env/executables:$PATH"' >> ~/.bash_profile && source ~/.bash_profile
 echo 'export PATH=/home/jferrer/.pyenv/versions/3.7.2/bin:$PATH' >> /home/jferrer/.bash_profile && source /home/jferrer/.bash_profile

eb init
eb init --profile eb-jrfep
eb create lit-rev-app
git init


## cp -rv $SCRIPTDIR/web/* .
 unzip ~/Downloads/php-v1.zip
git add .
git commit -m 'initial commit'
eb use lit-rev-app

eb deploy --staged

```

download and compare

```sh

##
psql -U postgres -h literature-review.cpq4sgesx7kb.ap-southeast-2.rds.amazonaws.com -d litrev   
##
psql -U postgres -h literature-review.c9ldkr8elxog.ap-southeast-2.rds.amazonaws.com -d litrev  
```


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

eb config get litrev-app-take-away
 eb status

```

Move to another aws account
```sh
cd $WORKDIR

s3://elasticbeanstalk-ap-southeast-2-572174861211/resources/templates/LiteratureReviewApp-env/

psql -U postgres -h literature-review.cpq4sgesx7kb.ap-southeast-2.rds.amazonaws.com -d litrev

```


how to migrate eb app: https://aws.amazon.com/premiumsupport/knowledge-center/elastic-beanstalk-migration-accounts/

Initialization of eb directory

```sh
cd $WORKDIR
eb init
eb config get litrev-app-take-away
 eb status

mkdir $WORKDIR/bckA
cd $WORKDIR
aws s3 sync "s3://elasticbeanstalk-ap-southeast-2-572174861211/resources/templates/literature review app/" bckA


```

RDS configuration:
Endpoint
literature-review.c9ldkr8elxog.ap-southeast-2.rds.amazonaws.com

Subnets
subnet-6809f80e
subnet-cbea0883
subnet-863655de

VPC security groups
myVPC (sg-07baf88218ebe445f)
( active )
default (sg-0d76a279)
( active )
```sh
```

http://literaturereviewapp-env.eba-2bmsdtqx.ap-southeast-2.elasticbeanstalk.com

```sh

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
