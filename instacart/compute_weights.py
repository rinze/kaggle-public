import sqlite3
import pandas as pd
import numpy as np
import csv
import gzip
from collections import defaultdict

if __name__ == '__main__':
    conn = sqlite3.connect('data/instacart.db')
    c = conn.cursor()

    # Get the orders properly sorted, so we can directly
    # group by user_id, order_id and then compute the weights.
    q = """
    SELECT user_id, order_id, days_since_prior_order 
    FROM orders
    ORDER BY order_number
    """

    orders = pd.read_sql(q, conn)

    # First day is 0
    orders.ix[orders.days_since_prior_order == u'', 'days_since_prior_order'] = 0

    # Cumsum to obtain total days since *first* order
    orders_g = orders.groupby(['user_id'])['days_since_prior_order'].cumsum()
    orders['cumulative_days'] = orders_g.astype(int)
    # But I need to subtract cumulative_days from the actual day of the 
    # order we want to compute... which will be the maximum
    max_cum_days = orders.groupby(['user_id'])['cumulative_days'].max()
    max_cum_days = max_cum_days.reset_index()
    max_cum_days.columns = ['user_id', 'max_order_day']
    orders = pd.merge(orders, max_cum_days, on = "user_id", how = 'left')

    # Compute weight
    orders['w'] = (np.cos(2 * (orders['max_order_day'] - orders['cumulative_days']) / 365.0 * 3.14) + 1) / 2

    # Remove unwanted columns (for DB storage, let's try not do duplicate)
    res = orders
    res = res.drop(['days_since_prior_order', 'cumulative_days', 'max_order_day'],
                   axis = 1)

    # Insert weights into the DB
    res.to_sql('order_weights', conn, if_exists = 'replace')
    c.execute("CREATE INDEX IF NOT EXISTS idx_tmp1 ON order_weights(user_id)")
    c.execute("CREATE INDEX IF NOT EXISTS idx_tmp2 ON order_weights(order_id)")


