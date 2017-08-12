.headers on
.mode csv
.output /tmp/submission.csv

SELECT t.order_id, products FROM (
    SELECT o.user_id, order_id, IFNULL(GROUP_CONCAT(DISTINCT CASE WHEN reordered = 1 THEN product_id END, ' '), 'None') AS products

    FROM SELECT (order_id, product_id FROM order_products__prior WHERE repeated = 1) opp

    JOIN orders o ON o.order_id = opp.order_id

    GROUP BY order_id, m.user_id) b

INNER JOIN (SELECT DISTINCT user_id, order_id
            FROM orders
            WHERE eval_set = 'test') t ON t.user_id = b.user_id

ORDER BY t.order_id DESC;
