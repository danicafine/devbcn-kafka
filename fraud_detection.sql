-- Create Customer table
CREATE TABLE customers (
  id STRING PRIMARY KEY
) WITH (
  kafka_topic='customers', 
  value_format='AVRO'
);

-- Create Transactions stream
CREATE STREAM transactions WITH (
  kafka_topic='transactions',
  value_format='AVRO' 
);

-- Filter out information from Customers
CREATE TABLE customers_filtered WITH (
  kafka_topic='customers-filtered',
  value_format='AVRO' 
) AS
SELECT 
  * 
FROM CUSTOMERS 
WHERE USERID != 'User_8' 
EMIT CHANGES;

-- Enrich Transactions with Customer data
CREATE STREAM transactions_enriched WITH (
  kafka_topic='transactions_enriched',
  value_format='AVRO' 
) AS
SELECT 
  * 
FROM transactions t 
LEFT JOIN customers_filtered c
ON t.user_id = c.id
EMIT CHANGES;

-- Identify Suspicious Activity Ongoing
CREATE TABLE transactions_suspicious WITH (   
  kafka_topic='transactions_suspicious',
  format='AVRO'
) AS 
SELECT
  t_user_id AS user_id,
  COUNT(t_transaction_id) AS transactions_count
FROM transactions_enriched
WINDOW TUMBLING (SIZE 60 SECONDS)
GROUP BY t_user_id
HAVING COUNT(t_transaction_id) > 4
EMIT CHANGES;

-- Identify Suspicious Activity Final
CREATE TABLE transactions_suspicious_final WITH (   
  kafka_topic='transactions_suspicious_final',
  format='AVRO'
) AS 
SELECT
  t_user_id AS user_id,
  COUNT(t_transaction_id) AS transactions_count
FROM transactions_enriched
WINDOW TUMBLING (SIZE 30 SECONDS)
GROUP BY t_user_id
HAVING COUNT(t_transaction_id) > 4
EMIT FINAL;
