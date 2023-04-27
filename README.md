# NPM + Redis demo app
This is an example app made from a nodejs frontlend and Redis data backend.

The project shows how to build the app container and deploy it to Azure Container Apps using managed Redis cache as a dependency.

It also includes the terraform IaC code and a basic load test used to show the scaling of the deployed app.

## Local environment
To start the app locally a container runtme with compose support is required. Docker supports it out of the box. Assuming that docker is used.

* Start: `docker compose up -d`
* Stop: `docker compose down`
* Test: `curl http://localhost:5000`

The frontend supports following environment variables: `REDIS_HOST`, `REDIS_PORT` allowing to configure connectivity to the data backend.

## Infrastructure
Cloud infrastructure resources except the resource group and its basic permissions can be created using terraform.

Login to Azure: `az login`

If needed select a subscription: `az account set --subscription XXX-YYY-ZZZ`

Run terraform:
```
terraform -chdir=devops/terraform init -var-file=./environments/test/env.tfvars
terraform -chdir=devops/terraform import azurerm_resource_group.rg \
  /subscriptions/d7d0b744-7dd4-494d-b357-0e13c93cf89e/resourceGroups/RG-EUR-WW-POC-DL
terraform -chdir=devops/terraform plan -var-file=./environments/test/env.tfvars -out=test.tfplan
terraform -chdir=devops/terraform apply -input=false -auto-approve test.tfplan
```

## Azure container apps deployment
In this example redis cache is provisioned with ACR and the rest of the infrastructure using terrafom.

The frontend app is in `web/`. Dockerfile is provided. See `pipelines/cap-deploy.yaml` how the image can be built and published to ACR.

The container app is created:
```
az containerapp create \
            --name noderedis-example \
            --resource-group RG-EUR-WW-POC-DL \
            --image acrpocdl.azurecr.io/noderedis-example:1.0.35217 \
            --environment CAP-EUR-WW-POC-DL \
            --registry-server acrpocdl.azurecr.io \
            --registry-username $(ACRUSER) \
            --registry-password $(ACRPASS) \
            --secrets "redis-password=$(redis-password)" \
            --env-vars \
            "REDIS_HOST=$(REDIS_NAME).privatelink.redis.cache.windows.net" \
            REDIS_PORT=$(az redis show -n $(REDIS_NAME) -g RG-EUR-WW-POC-DL | jq -r ".sslPort") \
            "REDIS_PASSWORD=secretref:redis-password"

az containerapp ingress enable \
            --type external \
            --name noderedis-example \
            --resource-group RG-EUR-WW-POC-DL \
            --target-port 5000 \
            --transport auto
```
The app availability can be tested with
```
curl -w '%{http_code}\n' -s -LI  \
  https://$(az containerapp ingress show -n $(imgname) -g $(RESOURCE_GROUP) | jq -r ".fqdn")
```

The container app can be removed with
```
az containerapp delete -n noderedis-example -g RG-EUR-WW-POC-DL -y
```
# Replicas Scaling
A container app created with a scaling rule
```
...
    --min-replicas 0 \
    --max-replicas 3 \
    --scale-rule-name azure-http-rule \
    --scale-rule-type http \
    --scale-rule-http-concurrency 10 \
...
```
can be loaded with [k6 tool](https://k6.io/) to simulate the web load and trigger the scaling of the number of replicas. The load test script is found in `tests/load/k6-test.js`. when the load test is running the number of replicas can be observed in container app -> Metrics -> Metric: Replica Count. The number of replicas will scale up to 3 as it is the maximum set by the rule.
## Azure DevOps pipeline
The [pipline](https://dev.azure.com/TAGDataAI/Common/_build?definitionId=322&_a=summary) code is in `pipelines/cap-deploy.yaml`.

Pipeline parameters are in `pipelines/config/test.yaml`.

It is expected that the ADO project is set that the service connection is granted with a sufficient role (Contributor) on the resource group where the app is deployed.
