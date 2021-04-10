# gcloud domains list-user-verified
# gcloud domains verify BASE-DOMAIN
# gcloud beta run domain-mappings create --service hugo-server --domain site.dm-on.info --platform=managed --region=asia-northeast1
# Creating......done.                                                                                                                   
# Waiting for certificate provisioning. You must configure your DNS records for certificate issuance to begin.
# NAME  RECORD TYPE  CONTENTS
# site  CNAME        ghs.googlehosted.com.

.PHONY: publish
publish:
	@ rm -rf ./public; \
	  hugo

# .PHONY: push-image-sa
# push-image-sa: publish
# 	@ cat "${HOME}/.gcp/soi-cloud-708d1b5c40f7.json" | docker login -u _json_key --password-stdin https://gcr.io; \
# 		docker rmi gcr.io/dm-on-site/hugo-server:latest; \
#     docker build -t gcr.io/dm-on-site/hugo-server:latest . ;\
# 	  docker push gcr.io/dm-on-site/hugo-server:latest

GCP_PROJECT_ID = dm-on-site
DOCKER_IMAGE_NAME = hugo-server

.PHONY: push-image
push-image: publish
	@ gcloud auth login; \
    gcloud config set project $(GCP_PROJECT_ID); \
    gcloud auth configure-docker; \
    docker rmi gcr.io/$(GCP_PROJECT_ID)/$(DOCKER_IMAGE_NAME):latest; \
    docker build -t gcr.io/$(GCP_PROJECT_ID)/$(DOCKER_IMAGE_NAME):latest . ;\
    docker push gcr.io/$(GCP_PROJECT_ID)/$(DOCKER_IMAGE_NAME):latest

CLOUD_RUN_SERVICE = hugo-server

.PHONY: deploy
deploy-image: push-image
	@ gcloud beta run deploy $(CLOUD_RUN_SERVICE) \
    --image gcr.io/$(GCP_PROJECT_ID)/$(DOCKER_IMAGE_NAME):latest \
    --port 80 \
    --platform=managed \
    --region=asia-northeast1 \
    --max-instances=2

# https://qiita.com/szk3/items/38a3dba7fdfed189f4c9

.PHONY: list-images
list-images:
	@ gcloud container images list-tags gcr.io/dm-on-site/hugo-server
