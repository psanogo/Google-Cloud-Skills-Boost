
gcloud auth list

echo -e "\033[1;33mPlease enter USERNAME_2:\033[0m"

touch sample.txt

gsutil mb gs://$DEVSHELL_PROJECT_ID

gsutil cp sample.txt gs://$DEVSHELL_PROJECT_ID

gcloud projects remove-iam-policy-binding $DEVSHELL_PROJECT_ID --member="user:$USERNAME_2" --role="roles/viewer"

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member="user:$USERNAME_2" --role="roles/storage.objectViewer"
