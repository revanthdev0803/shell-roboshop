#!/bin/bash

START_TIME=$(date +%s)
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
M="\e[35m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)       #It will split the scriptName and gives only 10-logs which is field 1
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo -e "$M Script executing at : $N $(date)"  | tee -a $LOG_FILE

if [ $USERID -eq 0 ]   
then
    echo -e "$M Running with sudo user... $N" | tee -a $LOG_FILE
else
    echo -e "$R Error:: Run with sudo user to install packages $N" | tee -a $LOG_FILE
    exit 1
fi

#function to validate package installed succesfully or not
VALIDATE(){

    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

echo "please enter root password"
read -s MYSQL_ROOT_PASSWORD

dnf install maven -y
VALIDATE $? "installing maven"

id roboshop

if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
else
    echo -e "user allready there $Y skipping $N"
fi

mkdir -p /app 
VALIDATE $? "creating app Directory"


curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip
VALIDATE $? "downloading shipping"

rm -rf /app/* 
cd /app 
unzip /tmp/shipping.zip
VALIDATE $? "unzipping shipping"


mvn clean package 
VALIDATE $? "packing the shipping"

mv target/shipping-1.0.jar shipping.jar 
VALIDATE $? "moving and renaming jar file"


cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service

systemctl daemon-reload 
VALIDATE$? "dameon reloaded"
systemctl enable shipping 
VALIDATE $? "enable shipping"
systemctl start shipping 
VALIDATE $? "start shipping"

dnf install mysql -y
VALIDATE $? "installing mysql" 

mysql -h mysql.chinni.fun -u root -p$MYSQL_ROOT_PASSWORD -e 'use cities'
if [ $? -ne 0 ]
then
    mysql -h mysql.chinni.fun -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/schema.sql

    mysql -h mysql.chinni.fun -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/app-user.sql  

    mysql -h mysql.chinni.fun -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/master-data.sql
    VALIDATE $? "loading data into my sql"
else 
    echo -e "data is already loaded into mysql...$Y skipping $N"
fi

systemctl restart shipping