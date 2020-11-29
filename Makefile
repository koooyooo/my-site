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

.PHONY: push-image
push-image:
	@ cat "${HOME}/.gcp/soi-cloud-708d1b5c40f7.json" | docker login -u _json_key --password-stdin https://gcr.io; \
      docker build -t gcr.io/soi-cloud/soi-server:latest . ;\
	  docker push gcr.io/soi-cloud/soi-server:latest
