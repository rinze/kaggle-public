import sqlite3
import pandas as pd
import csv
import gzip
from collections import defaultdict

if __name__ == '__main__':
    conn = sqlite3.connect('data/instacart.db')
    c = conn.cursor()

    # This does the same (?; re-check) and is much faster
    q = """
    SELECT user_id, 
           MIN(n_items) AS min_items, 
           AVG(n_items) AS avg_items,
           MAX(n_items) AS max_items
    FROM orders o
    INNER JOIN (SELECT order_id, COUNT(*) AS n_items
                FROM order_products__prior
                GROUP BY order_id) avg ON avg.order_id = o.order_id
    GROUP BY user_id
    """
    print "Getting order stats..."
    c.execute(q)

    order_stats = dict()

    print "Assigning to dictionary..."
    for row in c:
        order_stats[row[0]] = (row[1], row[2], row[3])

    # For every customer, sort the bought items in descending popularity
    # Use double weighing.
    q = """
    SELECT o.user_id AS user_id,
           opp.product_id AS product_id,
           -- w_periodic only when it's fresh products. Use squared w_periodic,
           -- as we have checked it works better.
           -- Work on this
           -- SUM(CASE WHEN opp.product_id IN (16, 24, 67, 83) THEN w_periodic * w_periodic * w_decay
           --          ELSE w_decay 
           --    END) AS n 
           -- Simpler version (all equal)
           SUM(w_periodic * w_decay * w_recent) AS n
    FROM order_products__prior opp
    JOIN orders o ON o.order_id = opp.order_id
    JOIN order_weights w ON w.user_id = o.user_id AND w.order_id = o.order_id
    GROUP BY o.user_id, opp.product_id
    ORDER BY o.user_id, n DESC
    """

    print "Getting product frequency..."
    c.execute(q)

    print "Assigning next order per user..."
    next_order = defaultdict(list)
    for row in c:
        if len(next_order[row[0]]) < round(order_stats[row[0]][1]): # more than the average
            next_order[row[0]].append(row[1])

    # Now just let's assign orders
    print "Generating CSV file..."
    q = "SELECT order_id, user_id FROM orders WHERE eval_set = 'test'"
    c.execute(q)
    result = []
    result.append(['order_id', 'products'])
    for row in c:
        result.append([row[0], " ".join([str(x) for x in next_order[row[1]]])])

    # Write compressed CSV file
    with gzip.open('/tmp/submission.csv.gz', 'wb') as f:
        csvwriter = csv.writer(f, delimiter = ',', quotechar = '"')
        for row in result:
            csvwriter.writerow(row)

