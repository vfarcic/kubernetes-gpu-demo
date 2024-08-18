#!/usr/bin/env nu

let project_id = (open settings.yaml | get projectID)

(
    gcloud container node-pools delete dot-gpu
        --project $project_id --cluster dot --zone us-east1-b
        --quiet
)

(
    gcloud container clusters delete dot
        --project $project_id --zone us-east1-b --quiet
)

gcloud projects delete $project_id --quiet

rm $env.KUBECONFIG 
