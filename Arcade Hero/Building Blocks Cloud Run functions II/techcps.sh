

gcloud auth list

export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

gcloud services enable \
  cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  eventarc.googleapis.com \
  pubsub.googleapis.com \
  storage.googleapis.com \
  iam.googleapis.com

sleep 10

mkdir ~/hello-go && cd ~/hello-go

cat > main.go <<EOF_CP
package function

import (
    "fmt"
    "net/http"
)

// HelloGo is the entry point
func HelloGo(w http.ResponseWriter, r *http.Request) {
    fmt.Fprint(w, "Hello from Cloud Functions (Go 2nd Gen)!")
}
EOF_CP

cat > go.mod <<EOF_CP
module example.com/hellogo

go 1.21
EOF_CP

gcloud functions deploy cf-go \
  --gen2 \
  --region=$REGION \
  --runtime=go121 \
  --trigger-http \
  --allow-unauthenticated \
  --entry-point=HelloGo \
  --min-instances=5 \
  --source=.



echo "n" | gcloud functions deploy cf-pubsub \
  --gen2 \
  --region=$REGION \
  --runtime=go121 \
  --trigger-topic=cf-pubsub \
  --allow-unauthenticated \
  --entry-point=HelloGo \
  --min-instances=5 \
  --source=.


  
