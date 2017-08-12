# Kaggle Instacart code

## TODO

* Ensemble with the highest scored solution with a public kernel. We are using 
  different methods, so my weights are (probably, haven't checked) uncorrelated 
  with theirs. Averaging may improve the overall solution.

* *Running bayesian*, concept. Explore. Idea: we know a given item was ordered 
  at t0 and at te, use a prior window to compute the posterior. There might be 
  some ML involved after all.

## Instructions

1. Run `data/zip_to_bz2.sh` to have all files in the right format.
2. Run `data/csv_to_sql.sh` to generate a big `instacart.db` SQLITE file that 
   will be used as the centralized database for this competition.

## Different runs

### Last repeated order

Simple SQL query: `last_repeated_order.sql`.

### Very simple average

Just run `most_common_items.py` directly.

### Simple weighing (periodic)

Need to run `compute_weights.py` and then `most_common_items_simple_weight.py`.

### Double weighing (periodic plus decay)

Need to run `compute_weights_2.py` and then 
`most_common_items_double_weight.py`.

### Triple weighing (periodic plus decay plus recency penalty)

Need to run `compute_weights_3.py` and then 
`most_common_items_triple_weight.py`. Never obtained a good score using this.

## Notes

The number of `None` elements has an effect. Consider `last_repeated_order.sql`. 
With one `None` to substitute, the score is 0.22xxx. With two `None`s, it's 
0.219. Probably needs to reflect the total number of items per order.

It is important to study the seasonality of the different items. We have the 
number of days since the last order, which is a good feature to compute 
periodicity.

ex: `w = exp(-cumsum(time_since_last_order)) + sin(cumsum(time_since_last_order) 
/ 365)`

This will include a recency weight (first term) plus a periodicity term (second 
term). The sin() function must not go all the way to -1, though. This is just an 
example, must be tuned for this particular problem.

180 days will probably mark the minimum? Need to study periodicity per item. 
Perhaps some categories have more sensitivity to time of the year than others.

Funnily enough, it seems there are only 365 days in total for every user, so we 
have, at most, a year of orders.

There is also a big amount of users with 90 days (the biggest group, actually). 
See:

```
SELECT COUNT(*) AS n, total_period 
FROM (SELECT user_id, 
             SUM(days_since_prior_order) AS total_period, 
             AVG(days_since_prior_order) AS frequency, 
             COUNT(*) as n_orders 
      FROM orders 
      GROUP BY user_id) b 
GROUP BY total_period 
ORDER BY n 
DESC LIMIT 10;
```

<pre>
n           total_period
----------  ------------
4342        90.0        
2246        364.0       
2028        120.0       
1609        363.0       
1568        365.0       
1183        362.0       
1112        70.0        
1106        67.0        
1103        74.0        
1101        361.0       
</pre>

201321 164320 109010 80567 <-- users with 0 days 
