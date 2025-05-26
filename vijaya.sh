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
   
    if [ $instance != "frontend" ]
    then
        IP=$(aws ec2 describe-instances \
        --instance-ids $instance \
        --query "Reservations[0].Instances[0].PublicIpAddress" \
        --output text)
    else
	    IP=$(aws ec2 describe-instances \
        --instance-ids $instance \
        --query "Reservations[0].Instances[0].PrivateIpAddress" \
        --output text)
    fi

    echo "$instance IP adress $IP"
done 