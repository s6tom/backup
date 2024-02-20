#!/bin/bash

# Set the database credentials and S3 bucket information
DB_USER="$DB_USER"
DB_NAME="$DB_NAME"
DB_HOST="$DB_HOST"
DB_PORT="$DB_PORT"
DB_PASSWORD="$DB_PASSWORD"
PGPASSWORD="$DB_PASSWORD"
S3_BUCKET="$S3_BUCKET"
BACKUP_DIR="/backup"

# Set the AWS region
export AWS_DEFAULT_REGION="$AWS_DEFAULT_REGION"

# Set the working directory
WORKDIR=/backup
# mkdir -p $WORKDIR
# cd $WORKDIR || exit

# Set the timestamp for the backup file
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="$DB_NAME-$TIMESTAMP.sql"

# Perform the database backup
PGPASSWORD="$DB_PASSWORD" pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" > "$BACKUP_FILE"

# Check if the backup was successful
if [ $? -eq 0 ]; then
    echo "Database backup successful."

    # Upload the backup file to S3
    aws s3 cp $BACKUP_FILE s3://del-db-backup/S6/s6tom/

    # Check if upload to S3 was successful
    if [ $? -eq 0 ]; then
        echo "Backup uploaded to S3 successfully."
    createdb -U $DB_USER s6tom

    pg_restore -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d s6tom -f "$BACKUP_FILE"  
        # Clean up the local backup file
        rm "$BACKUP_FILE"
        
        exit 0
    else
        echo "Error: Failed to upload backup to S3."
        exit 1
    fi
else
    echo "Error: Database backup failed."
    exit 1
fi
