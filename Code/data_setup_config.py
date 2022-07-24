############################ Objeective ##############################################################################
## Delete table if exists & create a table, read csv file, in an optimal way send blocks of records into the table  ##
########################### Invoke ###################################################################################
## python3 data_setup.py --config_name Config/one-time-data-setup.json                                              ##
######################################################################################################################

import argparse
import json
from mysql.connector import Error # MySQL exceptions
from tqdm import tqdm # Progress status bar
from datetime import datetime # Clocking

import pandas as pd # Csv reading
import mysql.connector as mysql # MySQL operations
import math # Ceil calcualtion 


def log_message(level, message):
    print(f"{datetime.now()} :: {level} :: {message}")


if __name__ == '__main__':

    log_message('info', 'program execution started')
    start_time = datetime.now()

    parser = argparse.ArgumentParser()
    parser.add_argument('--config_name', required=True)
    args = parser.parse_args()

    with open(args.config) as config:
        config_details = json.load(config)
    
    source_path = config_details['src_path']
    file_name = config_details['src_file_name']
    table_name = config_details['trg_table_name']
    chunk_size = int(config_details['chunk_size'])

    total_records = pd.read_csv(source_path+file_name).shape[0]
    log_message('info', f'trying to ingest {total_records} records into {table_name} table')

    try:
        conn = mysql.connect(host='localhost', database='mysql', user='root', password='root123@PSWD')

        if conn.is_connected():

            cursor = conn.cursor()  
            cursor.execute("select database();")
            record = cursor.fetchone()
            log_message('info', f'you are connected to {record} database') 
            
            cursor.execute(f'DROP TABLE IF EXISTS {table_name};') 
            log_message('info', f'creating {table_name} table...')

            cursor.execute(config_details['create_ddl'])
            log_message('info', f'created successfully {table_name} table' )
            cursor.execute(f'ALTER TABLE {table_name} CONVERT TO CHARACTER SET utf8mb4;') 

            val = ''
            df_cols = 'list(zip('
            for index in config_details['num_cols']:
                val = val + '%s,'
                df_cols = df_cols + f"data['{config_details['cols'].split(',')[index]}'],"
            val = val[:-1]
            df_cols = df_cols[:-1]+'))'

            sqlQ = f'INSERT INTO mysql.{table_name} VALUES ({val})'
            log_message('info', f'data ingestion started into {table_name} started')
            
            # To get the progress bar using tqdm
            with tqdm(total= math.ceil(total_records/chunk_size)) as pbar:
                for data in pd.read_csv(source_path+file_name ,chunksize=chunk_size):
                    # Filling missing values with 0, with out this it gave error 
                    data = data.fillna(0)
                    # Executemany can ingest chuck of data that is given as a list
                    cursor.executemany(
                        sqlQ,
                        df_cols
                        )
                    conn.commit()
                    pbar.update(1)
            conn.close()
            log_message('info', f'data ingestion successfully completed into {table_name}')
            log_message('info', f'execution completed and Time taken: {datetime.now()-start_time}')
        else:
            log_message('error', 'mqsl not connected')
    except (mysql.Error,mysql.Warning) as e:
        log_message('error', f'following sql error: \n{str(e)}') 
    except Exception as e:
        log_message('error', f'following error: \n{str(e)}') 