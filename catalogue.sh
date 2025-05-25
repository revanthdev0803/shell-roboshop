#!/bin/bash

#this code is used to check either user was root or not
USERID=$(id -u) #id -u commands extract only user information from log

#these are the variables that use to store the colors

R="\e[31m" #red
G="\e[32m" #green
Y="\e[33m" #yellow
N="\e[0m" #no colour

LOGS_FOLDER="/var/log/shellscripts-logs"    #we create this path for storing our logs
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)  # it removes the .sh in script name
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER #we are making directry and telling if it is already dont give error by using -p
echo "script started at: $(date)" | tee -a $LOG_FILE

#we are checking that if user was not equal to zero or not
#root user id will be zero,if not we will give error

if [ $USERID -ne 0 ]
then
    echo -e "$R Erorr....$N please run with root user" | tee -a $LOG_FILE 
    exit 1 #give any number except zero for checking status
else
    echo "you are the root user" |&>>$LOG_FILE
fi

 #we use this function if given one is installed or not ,to reduce the steps we use this
 #here we are sending two arguments to the function one is exit status as $1=$? $2=is the package name to install
VALIDATE(){

    if [ $1 -eq 0 ]
    then
        echo -e "$2 is $G succesfull $N" | tee -a $LOG_FILE 
    else
        echo "$2 is fail" | tee -a $LOG_FILE 
        exit 1
    fi
}

dnf module disable nodejs -y
VALIDATE $? "disabling default nodejs"

dnf module enable nodejs:20 -y
dnf install nodejs -y

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop 
    VALIDATE $? "creating robosho system user"
else
    echo -e "system user roboshop already created....$Y skipping $N"
fi

mkdir -p /app
VALIDATE $? "creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
cd /app 
rm -rf /app/*
unzip /tmp/catalogue.zip

npm install

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service

systemctl daemon-reload
systemctl enable catalogue 
systemctl start catalogue

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y

STATUS=$(mongosh --host mongodb.chinni.fun --eval 'db.getMongo().getDBNames().indexof("catalogue"),)
if [ $STATUS -lt 0]
then
    mongosh --host mongodb.chinni.fun </app/db/master-data.js
else
    echo -e "data is alreay loaded"
