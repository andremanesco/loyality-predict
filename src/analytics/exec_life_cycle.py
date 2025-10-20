#%%
import pandas as pd
import sqlalchemy
import datetime
from tqdm import tqdm

#%% 
def import_query(path):
    with open(path) as open_file:
        query = open_file.read()
    return query

query = import_query('life_cycle.sql')


#%%
engine_app = sqlalchemy.create_engine('sqlite:///../../data/loyalty-system/database.db')
engine_analytical = sqlalchemy.create_engine('sqlite:///../../data/analytics/database.db')

#%%
def date_range(start_date, end_date):
    dates = []
    while start_date <= end_date:
        dates.append(start_date)
        dt_start = datetime.datetime.strptime(start_date, '%Y-%m-%d') + datetime.timedelta(days=1)
        start_date = datetime.datetime.strftime(dt_start, '%Y-%m-%d')
    return dates

dates = date_range('2024-09-01', '2025-10-01')

for i in tqdm(dates):
    with engine_analytical.connect() as con:
        try:
            query_delete = f"DELETE FROM life_cycle WHERE dtRef = date('{i}', '-1 day')"
            con.execute(sqlalchemy.text(query_delete))
            con.commit()
        except Exception as e:
            print(e)
        
    query_format = query.format(date=i)
    df = pd.read_sql(query_format, engine_app)
    df.to_sql('life_cycle', engine_analytical, if_exists='append', index=False)


# %%
