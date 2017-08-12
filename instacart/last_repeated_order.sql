.headers on
.mode csv
.output /tmp/submission.csv

SELECT t.order_id, products FROM (
    SELECT m.user_id, order_id, IFNULL(GROUP_CONCAT(CASE WHEN reordered = 1 THEN product_id END, ' '), 'None') AS products

    FROM order_products__prior opp

    INNER JOIN (SELECT MAX(order_id) AS max_order_id,
                       user_id
                FROM orders
                WHERE eval_set = 'prior'
                GROUP BY user_id) m ON m.max_order_id = opp.order_id

    GROUP BY order_id, m.user_id) b

INNER JOIN (SELECT DISTINCT user_id, order_id
            FROM orders
            WHERE eval_set = 'test') t ON t.user_id = b.user_id

ORDER BY t.order_id DESC;
