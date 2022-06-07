############################ Objeective ##############################################################################
## read data from db1. delete if table exists in db2. dump the data into db2.                                       ##
########################### Invoke ###################################################################################
## python3 full_load.py --src_table restaurants --trg_table hotels --src_db mysql --trg_db mysql                    ##
######################################################################################################################


from datetime import datetime # Clocking
from sqlalchemy import create_engine, event

import urllib.parse # parsing the passowrd if you have special chars
import numpy as np # spliting the dataframe into smaller chunks if required 
import pandas as pd # Csv reading
import argparse # runtime arguments passing 
import traceback
import math


def log_message(level, message):
    print(f"{datetime.now()} :: {level} :: {message}")

def write_df_to_sql(df, table, conn):
    chunks = np.array_split(df, math.ceil(df.shape[0] / 10**3))
    for chunk in chunks:
        chunk.to_sql(table, conn, if_exists = 'append', index = False)
        log_message('info', f'copying chunk of data...')
    return True


if __name__ == '__main__':

    log_message('info', 'program execution started')
    start_time = datetime.now()

    parser = argparse.ArgumentParser()
    parser.add_argument('--src_table', required=True)
    parser.add_argument('--trg_table', required=True)
    parser.add_argument('--src_db', required=True)
    parser.add_argument('--trg_db', required=True)
    args = parser.parse_args()

    src_table = args.src_table
    trg_table = args.trg_table
    trg_db = args.trg_db
    src_db = args.src_db

    host = 'localhost'
    password = urllib.parse.quote_plus("root123@PSWD") 

    src_conn_str = f'mysql+pymysql://root:{password}@{host}/{src_db}'
    src_conn = create_engine(src_conn_str)

    trg_conn_str = f'mysql+pymysql://root:{password}@{host}/{trg_db}'
    trg_conn = create_engine(trg_conn_str)

    try:
        s = src_conn.connect()
        t = trg_conn.connect()

    except Exception as e:
        log_message('error', f'connection issue : \n{str(e)}') 

    try:            
        @event.listens_for(trg_conn, 'before_cursor_execute')
        def receive_before_cursor_execute(conn, cursor, statement, params, context, executemany):
            print("--------- testing -------------")
            if executemany:
                cursor.fast_executemany = True

        df = pd.read_sql(f'select * from {src_table}', con = src_conn)
        log_message('info', f'data successfully read from {src_db}.{src_table}')

        trg_conn.execute(f'drop table if exists {trg_table}')
        log_message('info', f'dropping if {trg_table} exists in {trg_db}')

        trg_conn.execute(f'\
                create table if not exists {trg_table}(\
                    `id` BIGINT,\
                    `position` BIGINT,\
                    `name` VARCHAR(1000),\
                    `score` FLOAT,\
                    `ratings` INT,\
                    `category` TEXT,\
                    `price_range` VARCHAR(10),\
                    `full_address` TEXT,\
                    `zip_code` VARCHAR(100),\
                    `lat` FLOAT,\
                    `lng` FLOAT \
                    )\
                ')
        trg_conn.execute(f'ALTER TABLE {trg_table} CONVERT TO CHARACTER SET utf8mb4;')
        log_message('info', f'created table {trg_table} with expected DDL in {trg_db}')

        write_df_to_sql(df, trg_table, trg_conn)
        log_message('info', f'data successfully written to {trg_db}.{trg_table}')

        log_message('info', f'execution completed and Time taken: {datetime.now()-start_time}')

    except Exception as e:
        log_message('error', f'data processing issue : \n{str(e)}') 
        log_message('error', f'trace back details: \n{traceback.print_exc()}')

    finally:
        s.close()
        t.close()
        