#developing code for ec2 in stance
#!/bin/bash
AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-04ccc30b04ef49701"
INSTANCES=("mongodb" "frontend" "catalouge")
ZONE_ID="Z022707230EX5QM3U8XUK"
DOMAIN_NAME="chinni.fun"
 

for instance in ${INSTANCES[@]}
do
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t2.micro \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query "Instances[0].InstanceId" --output text)
   
    if [ $instance = "frontend" ]
    then
        IP=$(aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --query "Reservations[0].Instances[0].PublicIpAddress" \
        --output text)
    else
	    IP=$(aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --query "Reservations[0].Instances[0].PrivateIpAddress" \
        --output text)
    fi

    echo "$instance IP adress $IP"


     {

        aws route53 change-resource-record-sets \
         --hosted-zone-id $ZONE_ID \
        --change-batch file:///path/to/your/file.json
     "Comment": "Update A record for example.com",
    "Changes": [
        {
        "Action": "UPSERT",
        "ResourceRecordSet": {
        "Name": "$instance.$DOMAIN_NAME",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [
            {
                "Value": "1.2.3.4"
             }
            ]
        }
        }
        ]
    }
done 