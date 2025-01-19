

export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")


gcloud storage buckets create gs://$DEVSHELL_PROJECT_ID-image --location=$REGION

gcloud storage buckets create gs://$DEVSHELL_PROJECT_ID-result --location=$REGION

gcloud pubsub topics create techcps-translate

gcloud pubsub topics create techcps-result

git clone https://github.com/GoogleCloudPlatform/python-docs-samples.git

cd python-docs-samples/functions/ocr/app/


PROJECT_ID=$(gcloud config get-value project)
SERVICE_AGENT_EMAIL="service-${PROJECT_NUMBER}@gcp-sa-eventarc.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$SERVICE_AGENT_EMAIL \
  --role roles/eventarc.serviceAgent


STORAGE_SERVICE_ACCOUNT=$(gcloud storage service-agent --project=$PROJECT_ID)

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$STORAGE_SERVICE_ACCOUNT \
  --role roles/pubsub.publisher



gcloud functions deploy ocr-extract \
  --gen2 \
  --runtime python312 \
  --region=$REGION \
  --source=. \
  --entry-point process_image \
  --trigger-bucket $DEVSHELL_PROJECT_ID-image \
  --service-account $PROJECT_NUMBER-compute@developer.gserviceaccount.com \
  --allow-unauthenticated \
  --set-env-vars "^:^GCP_PROJECT=$PROJECT_ID:TRANSLATE_TOPIC=techcps-translate:RESULT_TOPIC=techcps-result:TO_LANG=es,en,fr,ja"


sleep 10

gcloud functions deploy ocr-translate \
--gen2 \
--runtime python312 \
--region=$REGION \
--source=. \
--trigger-topic techcps-result \
--entry-point translate_text \
--service-account $PROJECT_NUMBER-compute@developer.gserviceaccount.com \
--allow-unauthenticated \
--set-env-vars "GCP_PROJECT=$PROJECT_ID,RESULT_TOPIC=$_techcps-result"

sleep 10

gcloud functions deploy ocr-save \
--gen2 \
--runtime python312 \
--region=$REGION \
--source=. \
--trigger-topic techcps-result \
--entry-point save_result \
--service-account $PROJECT_NUMBER-compute@developer.gserviceaccount.com \
--allow-unauthenticated \
--set-env-vars "GCP_PROJECT=$PROJECT_ID,RESULT_BUCKET=$DEVSHELL_PROJECT_ID-result"


gsutil cp gs://cloud-training/OCBL307/menu.jpg .

gsutil cp menu.jpg gs://$DEVSHELL_PROJECT_ID-image


gcloud functions logs read --limit 100


