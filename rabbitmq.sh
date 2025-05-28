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

echo "please enter  password"
read -s RABBITMQ_PASSWD

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



cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>$LOG_FILE
VALIDATE $? "copying"

dnf install rabbitmq-server -y &>>$LOG_FILE
VALIDATE $? "installing rabbtmq server"
systemctl enable rabbitmq-server &>>$LOG_FILE
VALIDATE $? "enabling"
systemctl start rabbitmq-server &>>$LOG_FILE
VALIDATE $? "starting"

rabbitmqctl add_user roboshop $RABBITMQ_PASSWD
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"