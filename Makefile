.PHONY: run
run:
	@ hugo serve -D

.PHONY: nginx
nginx:
	@ docker run -p 80:80 -v $(pwd)/public:/usr/share/nginx/html nginx

.PHONY: docker-build
docker-build:
	@ docker build -t nginx-hugo .

.PHONY: docker-run
docker-run:
	@ docker container run --rm --name nginx-hugo -p 80:80 nginx-hugo


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

.PHONY: push-image
push-image: publish
	@ cat "${HOME}/.gcp/soi-cloud-708d1b5c40f7.json" | docker login -u _json_key --password-stdin https://gcr.io; \
		docker rmi gcr.io/dm-on-site/hugo-server:latest; \
    docker build -t gcr.io/dm-on-site/hugo-server:latest . ;\
	  docker push gcr.io/dm-on-site/hugo-server:latest

.PHONY: deploy-image
deploy-image: push-image
	@ gcloud beta run deploy hugo-server \
	  --image gcr.io/dm-on-site/hugo-server:latest \
		--port 80 \
		--platform=managed \
		--region=asia-northeast1

# https://qiita.com/szk3/items/38a3dba7fdfed189f4c9
