#!/usr/bin/env nu

gcloud auth login

let project_id = $"dot-(date now | format date "%Y%m%d%H%M%S")"

open settings.yaml
    | upsert projectID $project_id
    | save settings.yaml --force

gcloud projects create $project_id

start $"https://console.cloud.google.com/marketplace/product/google/container.googleapis.com?project=($project_id)"

print $"(ansi yellow_bold)
ENABLE the API.(ansi reset)
Press any key to continue."
input

(
    gcloud container clusters create dot --project $project_id
        --zone us-east1-b --machine-type e2-standard-4
        --enable-autoscaling --num-nodes 1 --min-nodes 1
        --max-nodes 3 --enable-network-policy
        --no-enable-autoupgrade
)

(
    gcloud container clusters get-credentials dot
        --project $project_id --zone us-east1-b
)

(
    helm upgrade --install traefik traefik
        --repo https://helm.traefik.io/traefik
        --namespace traefik --create-namespace --wait
)

let ingress_host = (kubectl --kubeconfig kubeconfig.yaml 
    --namespace traefik get service traefik 
    --output jsonpath="{.status.loadBalancer.ingress[0].ip}")

open settings.yaml
    | upsert ingress.host $ingress_host
    | save settings.yaml --force

open ollama-values.yaml
    | upsert ingress.hosts.0.host ollama.($ingress_host).nip.io
    | save ollama-values.yaml --force

$"export KUBECONFIG=($env.PWD)/kubeconfig.yaml
export INGRESS_HOST=($ingress_host)
export PROJECT_ID=($project_id)" | save .env --force