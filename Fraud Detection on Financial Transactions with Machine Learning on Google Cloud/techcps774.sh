

gsutil cp gs://spls/gsp774/archive.zip .

unzip archive.zip

export DATA_FILE=PS_20174392719_1491204439457_log.csv

export PROJECT_ID=$(gcloud config get-value project)

bq mk --dataset $PROJECT_ID:finance

gsutil mb gs://$PROJECT_ID

gsutil cp $DATA_FILE gs://$PROJECT_ID


bq load --autodetect --source_format=CSV --max_bad_records=100000 finance.fraud_data gs://$PROJECT_ID/$DATA_FILE


bq query --use_legacy_sql=false \
'SELECT type, isFraud, COUNT(*) as cnt
 FROM `finance.fraud_data`
 GROUP BY isFraud, type
 ORDER BY type'

bq query --use_legacy_sql=false '
SELECT isFraud, COUNT(*) as cnt
FROM `finance.fraud_data`
WHERE type IN ("CASH_OUT", "TRANSFER")
GROUP BY isFraud'


bq query --nouse_legacy_sql \
'SELECT *
 FROM `finance.fraud_data`
 ORDER BY amount DESC
 LIMIT 10'


bq query --use_legacy_sql=false \
'CREATE OR REPLACE MODEL
finance.model_supervised_boosted_tree
OPTIONS(model_type="BOOSTED_TREE_CLASSIFIER", INPUT_LABEL_COLS=["isfraud"])
AS
SELECT
type, amount, oldbalanceOrig, newbalanceOrig, oldbalanceDest, newbalanceDest, isFraud
FROM finance.fraud_data_model'


bq query --use_legacy_sql=false \
'CREATE OR REPLACE TABLE finance.table_perf AS
SELECT "Initial_reg" as model_name, *
FROM ML.EVALUATE(MODEL `finance.model_supervised_initial`, (
  SELECT *
  FROM `finance.fraud_data_model` ))'


bq query --use_legacy_sql=false '
INSERT INTO `finance.table_perf`
SELECT "improved_reg" as model_name, *
FROM ML.EVALUATE(MODEL `finance.model_supervised_boosted_tree`, (
  SELECT *
  FROM `finance.fraud_data_model` 
))'


bq query --use_legacy_sql=false '
SELECT id, label as predicted, isFraud as actual
FROM
  ML.PREDICT(MODEL `finance.model_supervised_initial`,
  (
   SELECT  *
   FROM  `finance.fraud_data_test`
  )
 ), unnest(predicted_isfraud_probs) as p
WHERE p.label = 1 and p.prob > 0.5
'
