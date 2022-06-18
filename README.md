# on-premise-data-migration

![alt text](/Images/data_setup_screenshot.png)

export AWS_ACCESS_KEY_ID="xxxx"

export AWS_SECRET_ACCESS_KEY="xxxxx"

OR

Add a Role with S3 policy to the Ec2

aws s3 cp s3://ravi-123-today/ /home/ec2-user/ --recursive

mysql -uroot -proot123@PSWD

INSERT INTO mysql.restaurants (`id`,`position`,`name`,`score`,`ratings`,`category`,`price_range`,`full_address`,`zip_code`,`lat`,`lng`,`last_modified_date`) VALUES (5001,19,'papa johns',3,3,'Burgers','$','NY','35210',33.5623653,-86.8307025,'2022-06-18');


UPDATE mysql.restaurants SET zip_code = '35211',last_modified_date = '2022-06-18' WHERE id = 1;

ops_table: ops_metadata
source_name, source_database, source_table, last_processed_date

