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

dnf install python3 gcc python3-devel -y &>>$LOG_FILE
VALIDATE $? "Installing python 3"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Created roboshop user"
else
    echo -e "Roboshop User already exists... $Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "making an PP"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip 
rm -rf /app/*

cd /app 

unzip /tmp/payment.zip
VALIDATE $? "unzipping"

pip3 install -r requirements.txt
VALIDATE $? "Installing pip3"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service
VALIDATE $? "copying payment service"

systemctl daemon-reload
VALIDATE $? "daemon reloaded"

systemctl enable payment 
systemctl start payment
VALIDATE $? "starting the system"
