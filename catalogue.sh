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

dnf module disable nodejs -y &>>LOG_FILE
VALIDATE $? "disabling default nodejs"

dnf module enable nodejs:20 -y &>>LOG_FILE
VALIDATE $? "enable node js 20"

dnf install nodejs -y &>>LOG_FILE
VALIDATE $? "installing nodejs"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
VALIDATE $? "creating roboshop system user"

mkdir -p /app 
VALIDATE $? "creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
VALIDATE $? "downloading catalouge"

cd /app 
unzip /tmp/catalogue.zip &>>LOG_FILE
VALIDATE $? "unzip the file"

npm install
VALIDATE $? "npm is installing"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "copying catalogue service"

systemctl daemon-reload &>>LOG_FILE
systemctl enable catalogue &>>LOG_FILE
systemctl start catalogue
VALIDATE $? "starting catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y &>>LOG_FILE
VALIDATE $? "installing mongodb client"

STATUS=$(mongosh --host mongodb.daws84s.site --eval 'db.getmongo().getDBNames().getDBNames().indexof("catalogue")'
if [ $STATUS -lt 0 ]
then
    mongosh --host mongodb.chinni.fun </app/db/master-data.js &>>LOG_FILE
    VALIDATE $? "Loading data into MongoDB"
else
    echo -e "Data is already loaded...$Y SKIPPING $N"
fi
