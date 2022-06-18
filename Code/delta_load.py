############################ Objeective ######################################################################################################
## read data from db1. delete if table exists in db2. dump the data into db2.                                                               ##
########################### Invoke ###########################################################################################################
## python3 delta_load.py --src_table restaurants --trg_table hotels --meta_table ops_metadata --src_db mysql --trg_db mysql  --meta_db mysql ##
##############################################################################################################################################


from datetime import datetime, timedelta# Clocking
from sqlalchemy import create_engine, event

import urllib.parse # parsing the passowrd if you have special chars
import numpy as np # spliting the dataframe into smaller chunks if required 
import pandas as pd # Csv reading
import argparse # runtime arguments passing 
import traceback
import math


def log_message(level, message):
    print(f"{datetime.now()} :: {level} :: {message}")



if __name__ == '__main__':

    log_message('info', 'program execution started')
    start_time = datetime.now()

    parser = argparse.ArgumentParser()
    parser.add_argument('--src_table', required=True)
    parser.add_argument('--trg_table', required=True)
    parser.add_argument('--meta_table', required=True)
    parser.add_argument('--src_db', required=True)
    parser.add_argument('--trg_db', required=True)
    parser.add_argument('--meta_db', required=True)
    args = parser.parse_args()

    src_table = args.src_table
    trg_table = args.trg_table
    meta_table = args.meta_table
    trg_db = args.trg_db
    src_db = args.src_db
    meta_db = args.meta_db
    

    host = 'localhost'
    password = urllib.parse.quote_plus("root123@PSWD") 

    src_conn_str = f'mysql+pymysql://root:{password}@{host}/{src_db}'
    src_conn = create_engine(src_conn_str)

    trg_conn_str = f'mysql+pymysql://root:{password}@{host}/{trg_db}'
    trg_conn = create_engine(trg_conn_str)

    meta_conn_str = f'mysql+pymysql://root:{password}@{host}/{meta_db}'
    meta_conn = create_engine(meta_conn_str)

    try:
        s = src_conn.connect()
        t = trg_conn.connect()
        m = meta_conn.connect()


    except Exception as e:
        log_message('error', f'connection issue : \n{str(e)}') 

    try: 

        meta_df = pd.read_sql(f"select last_processed_date from {meta_table} where source_name = 'on-prem' and source_database = 'FnB' and source_table = '{src_table}'", con = meta_conn)
        last_processed_date = meta_df.iloc[0]['last_processed_date']

        log_message('info', f'retrived last processed info for {src_table} from {meta_table} and it is {last_processed_date}')

        @event.listens_for(trg_conn, 'before_cursor_execute')
        def receive_before_cursor_execute(conn, cursor, statement, params, context, executemany):
            if executemany:
                cursor.fast_executemany = True

        #processed_date = (datetime.today() - timedelta(days = 1)).strftime('%Y-%m-%d')
        processed_date = (datetime.today()).strftime('%Y-%m-%d')

        df = pd.read_sql(f"select * from {src_table} where last_modified_date > '{last_processed_date}' and last_modified_date <= '{processed_date}'", con = src_conn)
        log_message('debug', f"select * from {src_table} where last_modified_date > '{last_processed_date}' and last_modified_date <= '{processed_date}'")
        log_message('info', f'incremental data successfully read from {src_db}.{src_table}. it is {df.shape[0]} records')
        
        if df.shape[0] > 0: 
            
            df.to_sql('temp_delta', trg_conn, if_exists = 'replace', index = False)
            log_message('info', f'data successfully written to {trg_db}.temp_delta')


            trg_conn.execute(f"REPLACE INTO {trg_db}.{trg_table} (SELECT * FROM temp_delta)")
            log_message('info', f'incremantal data successfully written to {trg_db}.{trg_table}')

            log_message('info', f'execution completed and Time taken: {datetime.now()-start_time}')

            meta_conn.execute(f"\
                    UPDATE ops_metadata SET last_processed_date = '{processed_date}' where source_name = 'on-prem' and source_database = 'FnB' and source_table = '{src_table}';\
                    ")
            log_message('info', f'updated the meta record into ops_metadata')
        else :
            log_message('info', f'no incremantal data to process.')

    except Exception as e:
        log_message('error', f'data processing issue : \n{str(e)}') 
        log_message('error', f'trace back details: \n{traceback.print_exc()}')

    finally:
        s.close()
        t.close()
        m.close()
        