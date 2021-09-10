# Docker, Containers, Snyk and Kubernetes
<!-- TOC depthfrom:2 depthto:3 withlinks:true updateonsave:true orderedlist:false -->

- [Docker](#docker)
    - [Info](#info)
    - [Local credentials](#local-credentials)
    - [Lint](#lint)
    - [Build](#build)
    - [General commands](#general-commands)
    - [Run](#run)
    - [History](#history)
    - [Audit](#audit)
    - [Copy](#copy)
    - [Clean-up](#clean-up)
    - [python](#python)
    - [Sidecar design pattern](#sidecar-design-pattern)
    - [Docker CVEs](#docker-cves)
    - [References](#references)
- [Apache Bench / JMeter to load test a container](#apache-bench--jmeter-to-load-test-a-container)
- [circleci](#circleci)
    - [local setup](#local-setup)
    - [circleci setup](#circleci-setup)
    - [Validate config file](#validate-config-file)
    - [On every config.yaml change](#on-every-configyaml-change)
    - [Resources](#resources)
- [Snyk](#snyk)
    - [Setup](#setup)
    - [Upgrade](#upgrade)
    - [Verify it works](#verify-it-works)
    - [Find local auth token](#find-local-auth-token)
    - [Test Python dependencies](#test-python-dependencies)
    - [Test dependencies](#test-dependencies)
    - [custom filter results](#custom-filter-results)
    - [apply patches to your vulnerable dependencies](#apply-patches-to-your-vulnerable-dependencies)
    - [Test Javascript packages via CLI](#test-javascript-packages-via-cli)
    - [Monitor for new vulnerabilities](#monitor-for-new-vulnerabilities)
    - [Infrastructure as Code scanning](#infrastructure-as-code-scanning)
- [Kubernetes](#kubernetes)
    - [Deploy and Monitor](#deploy-and-monitor)
    - [Config](#config)
    - [autocomplete in zsh](#autocomplete-in-zsh)
    - [Dashboard](#dashboard)
    - [static code analysis - kube-score](#static-code-analysis---kube-score)
- [Terraform](#terraform)
    - [Validate](#validate)
    - [Lint  macOS](#lint--macos)

<!-- /TOC -->
## Docker

### Info

`docker info`

#### Version

`docker --version`

#### Check docker is running

`docker run busybox date`

#### Where is docker

`which docker`

#### List local images

`docker image ls`

#### Pull ( slim linux image )

`docker pull alpine`

#### Quick setup

```docker
docker pull alpine:latest

docker run -it alpine 
```

### Local credentials

#### Current docker.io logged in user

```bash
docker-credential-$(
  jq -r .credsStore ~/.docker/config.json
) list | jq -r '
  . |
    to_entries[] |
    select(
      .key | 
      contains("docker.io")         // modify here for other accounts
    ) |
    last(.value)
'
```

#### Contents of Credential Helper

```bash
docker-credential-desktop list | \
    jq -r 'to_entries[].key'   | \
    while read; do
        docker-credential-desktop get <<<"$REPLY";
    done
```

### Lint

#### hadolint

```bash
brew install hadolint
hadolint Dockerfile
```


#### multiple RUN vs single chained RUN

[multiple-run-vs-single-chained-run](https://stackoverflow.com/questions/39223249/multiple-run-vs-single-chained-run-in-dockerfile-which-is-better):

>When possible, I always merge together commands that create files with commands that delete those same files into a single RUN line. This is because each RUN line adds a layer to the image, the output is quite literally the filesystem changes that you could view with docker diff on the temporary container it creates.

### Build

#### Build options

```bash
docker build -f Dockerfile -t demo_lambda:0.3 .
docker build -f Dockerfile -t demo_lambda:0.9 .  --progress=plain
```

#### Run

```bash
docker run -it demo_lambda:0.3
docker run -it demo_lambda:0.3 bash    # shell in container
docker run --env AWS_PROFILE=foo --env AWS_REGION=eu-west-1 foobar:0.3 bash
docker run -v $HOME/.aws/:/root/.aws/:ro -it foobar:0.3 bash # mount directory for AWS variables

# mount file. Better to pass in via Dockerfile but passing is as a command line argument works for some edge cases
docker run \
        --env TOKEN=${TOKEN} \
        -v $(pwd)/Dockerfile:/Dockerfile \
        -it ${REPONAME}:0.1 \
        bash
```

#### Order matters

For an efficient use of the caching mechanism, [reference](https://www.docker.com/blog/containerized-python-development-part-1/):
> place the instructions for layers that change frequently after the ones that incur less changes.

```python
# Changes less frequently
COPY requirements.txt .

# install dependencies
RUN pip install -r requirements.txt

# Changes often
COPY src/ .
```

#### Push to DockerHub

```bash
<Create Private repo on Dockerhub>
docker build -t rusty/flasksidecardemo .
sudo lsof -iTCP -sTCP:LISTEN -n -P 	// check no containers running on port
docker run -d -p 5000:5000 rusty/flasksidecardemo
docker push rusty/flasksidecardemo
```

### General commands

#### View size of image

`docker image ls`

#### Show Container IDs

`docker ps`

#### Show Container IDs with memory footprint of the Thin R/W Layer

`docker ps -s`

#### A history of images and container IDs

`docker ps -a`

#### All exited container IDs

`docker ps --all --filter STATUS=exited`

#### All running container IDs

`docker ps --all --filter STATUS=running`

#### Load service [first time only]

`docker load -i foobar.tar.gz`

#### Start container

`docker start ctf`

#### Stop container

`docker stop ctf`

### Run

#### Interactive, terminal

`docker run -it ubuntu`

#### Interactive, terminal specify Bash

`docker run -it ubuntu bash`

#### Automatically remove container when it exits

`docker run --rm -it ubuntu`

#### Name container for Docker Container ls

`docker run --name foobar -it ubuntu`

#### Run service in background

```bash
docker pull swaggerapi/swagger-editor
docker run -d -p 7999:8080 swaggerapi/swagger-editor
```

#### Interactive, detach and allocate Pseudo Terminal

`docker run -idt ...`

#### Run in privileged

`docker run --privileged`

#### Run in non-privileged mode

`docker run -idt --name ctf duckll/ctf-box`

#### App Armor

`docker run --rm -it --security-opt apparmor=docker-default duckll/ctf-box`

### History

#### Image

`docker image history alpine_non_root`

#### Tag

`docker history foobar:v1`

#### No truncation

`docker image history foo/bar:0.2.1 --no-trunc`

#### Pretty Print

`docker history --format "{{.ID}}: {{.CreatedSince}}" foo/bar:0.2.1`

### Audit

#### Logs from Container ID

`docker logs bd0657a17d54`

#### check if container is running as Privileged

`docker inspect --format='{{.HostConfig.Privileged}}' <container id>`

#### Stats

`docker stats < container ID >`

### Copy

#### from Host to Docker Container

`docker cp foo/bar.c bd0657a17d54://root/newbar.c`

#### check if image can mount disk on Host

`mount -t tmpfs none /mnt`

#### Run interactive Terminal with Cut and Paste

`docker container exec -it ctf bash`

#### Stop by Container ID

`docker stop <container id>`

#### Stop by Image name

`docker stop foobar-service`

### Clean-up

#### Remove all stopped containers

`docker rm $(docker ps -a -q)`

#### Remove all all images not referenced by a container

`docker image prune --all`

#### Removes images created more than 10 days (240h) ago

`docker image prune -a --force --filter "until=240h"`

#### Container ( removed before Image removal )

`docker container rm <container id>`

#### Remove Image

`docker image rm <image id> --force`


#### Remove Image, force

`docker rmi -f duckll/ctf-box`

#### Security cheat sheet

<https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html>

### python

#### Do I use a virtualenv?

<https://stackoverflow.com/questions/29146792/why-people-create-virtualenv-in-a-docker-container>

### Sidecar design pattern

There are [lots of design patterns](https://techbeacon.com/enterprise-it/7-container-design-patterns-you-need-know) with containers.  If containers only have "one responsibility", the `sidecar pattern` ensures you add common functionaly out of a container. This includes:

- Logging
- Monitoring
- TLS set up
- Strip / add Response Headers
- Configuration

Overview [here](https://containerjournal.com/topics/container-security/tightening-security-with-sidecar-proxies/):
> `Decoupling` of common tasks to an independent unified service deployed alongside any core application service is known as a “sidecar” architecture.  Primary application in Go.   Existing functionality written in Python to collect logs and metrics.  Offloading that Python code into a sidecar is more efficient than asking the development team to rewrite that functionality in Go.

### Docker CVEs

[CVE-2019-5736: runc container breakout](https://seclists.org/oss-sec/2019/q1/119)

### References

#### Dockerfile design

<https://www.youtube.com/watch?v=15GYSxzdTLQ>

## Apache Bench / JMeter to load test a container

```bash

    -n: Number of requests
    -c: Number of concurrent requests
    -H: Add header
    —r: flag to not exit on socket receive errors
    -k: Use HTTP KeepAlive feature
    -p: File containing data to POST
    -T: Content-type header to use for POST/PUT data,


#GET with Header
ab -n 100 -c 10 -H "Accept-Encoding: gzip, deflate" -rk https://0.0.0.0:4000/
#POST
ab -n 100 -c 10 -p data.json -T application/json -rk https://0.0.0.0:4000/
```

## circleci

### local setup

It was essential that you debug the `config.yml` file before uploading to circleci.

```bash
brew install --ignore-dependencies circleci

brew upgrade circleci 

circleci version
```

### circleci setup

Go to web interface for CircleCI. It can auto generate the files and workflow.

Then generate a `Personal Access Token` or `Project Access Token`.

```bash
circleci setup
```

Then check it all worked:

```bash
cat /Users/foobar/.circleci/cli.yml                               
host: https://circleci.com
token: .......66de
```

### Validate config file

```bash
circleci context
circleci config validate
circleci config validate .circleci/config.yml
```

### On every config.yaml change

```bash
circleci config validate
circleci config process .circleci/config.yml > process.yml
circleci local execute -c process.yml --job build

# Environment variable
circleci local execute \
 -c process.yml \
 --job build \
 --env FOO_TOKEN=${FOO_TOKEN}
```

### Resources

<https://circleci.com/developer/orbs/orb/circleci/python>

<https://circleci.com/docs/2.0/local-cli/#run-a-job-in-a-container-on-your-machine>

<https://circleci.com/docs/2.0/ssh-access-jobs/>

## Snyk

### Setup

```bash
brew install npm
npm install -g snyk
npm i snyk
```

### Upgrade

`npm i -g snyk`

### Verify it works

```bash
snyk version
snyk auth               < login via GitHub / Docker account >
```

### Find local auth token

```bash
export SNYK_TOKEN=$(jq -r '.api' ~/.config/configstore/snyk.json)

echo ${SNYK_TOKEN}   
ffffffff-eeee-dddd-cccc-4fd7923c9cc8

cat ~/.config/configstore/snyk.json 
{
        "api": "ffffffff-eeee-dddd-cccc-4fd7923c9cc8",
        "org": "foobar"
}% 
```

### Test Python dependencies

```bash
# poetry
snyk test --file=poetry.lock --package-manager=poetry

# tell Snyk what python version is installed on the container
snyk --command=python3 monitor --severity-threshold=high
```

### Test dependencies

```bash
synk test
snyk test --severity-threshold="high"
snyk test --docker alpine --file=Dockerfile --exclude-base-image-vulns
snyk test --severity-threshold=critical --docker alpine --file=Dockerfile --json > ~/results.json
snyk test --severity-threshold="high" --docker mhart/alpine-node:12.19.1 --file=Dockerfile --exclude-base-image-vulns --json > snyk.json
snyk test ionic@1.6.5
snyk container test busybox
snyk container test $(basename $(pwd)) --file=Dockerfile
```

### custom filter results

```bash
git clone https://github.com/snyk-tech-services/snyk-filter.git
npm install -g
source ~/.zshrc
snyk test --json | snyk-filter -f ~/path/to/snyk-filter/sample-filters/example-cvss-9-or-above.yml    
```

### apply patches to your vulnerable dependencies

`snyk protect`

### Test Javascript packages via CLI

Snyk reads `package.json` and `package-lock.json` files, to build a full structured [Javascript](https://support.snyk.io/hc/en-us/articles/360004712477-Snyk-for-JavaScript) dependency tree.

```bash
cd codeDir
yarn install       // or 'npm install'
snyk test --severity-threshold="high" --json > snyk.json
```

### Monitor for new vulnerabilities

`snyk monitor`

### Infrastructure as Code scanning

```bash
// individual files
snyk iac test Kubernetes.yaml
snyk iac test terraform_file.tf

// folder and sub-folders
snyk iac test
snyk iac test | grep '✗'
snyk iac test --severity-threshold=high
snyk iac test --severity-threshold=high --json > results.json
```

```bash
// tfsec scans entire directory of Terraform files
brew install tfsec
tfsec .
```

## Kubernetes

#### Kubernetes Info

`kubectl version -o json`

#### Commands

<https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands>

#### Enable Kubernetes

```bash
kubectl config get-contexts
< check Kubernetes is "enabled" inside of `Docker Desktop` >
kubectl config use-context docker-desktop
kubectl get nodes
```

### Deploy and Monitor

#### Deploy

`kubectl apply -f deploy.yml`

#### Deploy status

`kubectl rollout status deployment/hello-deployment`

#### Get deployments

`kubectl get deployments`

#### Get services

`kubectl get services`

#### Get a service

`kubectl get svc hello-svc`

#### Scale

`kubectl scale -n default deployment hello-deployment --replicas=3`

#### Describe deployment

`kubectl describe po hello-deployment`

#### Delete deployment

```bash
kubectl delete -f deploy.yml
kubectl delete -n default deployment hello-deployment
```

#### Get pods

```bash
kubectl get pods
NAME                                READY   STATUS        RESTARTS   AGE
hello-deployment-566f549976-5nsm7   0/1     Terminating   0          16h
hello-deployment-566f549976-fh6c7   1/1     Terminating   0          16h
hello-deployment-697fc848f5-42swj   2/2     Running       0          9s
hello-deployment-697fc848f5-cbn86   2/2     Running       0          15s
```

#### Get Pods

`kubectl get pods -A -o=custom-columns='DATA:spec.containers[*].image'`

#### All images, grouped by Pod

`kubectl get pods --namespace default --output=custom-columns="NAME:.metadata.name,IMAGE:.spec.containers[*].image"`

### Config

#### View

```bash
// ref: https://kubernetes.io/docs/reference/kubectl/cheatsheet/
kubectl config view
kubectl config view -o jsonpath='{.users[].name}' 
```

### autocomplete in zsh

```bash
source <(kubectl completion zsh)  
echo "[[ $commands[kubectl] ]] && source <(kubectl completion zsh)" >> ~/.zshrc # add autocomplete permanently to your zsh shell
```

### Dashboard

Great [tutorial](https://andrewlock.net/running-kubernetes-and-the-dashboard-with-docker-desktop/):

kubectl edit deployment kubernetes-dashboard -n kubernetes-dashboard

#### Install

`kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.2.0/aio/deploy/recommended.yaml`

#### Disabling the login prompt in Kubernetes Dashboard

`kubectl patch deployment kubernetes-dashboard -n kubernetes-dashboard --type 'json' -p '[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--enable-skip-login"}]'`

#### Delete

`kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.2.0/aio/deploy/recommended.yaml`




#### Parse deploy file - kubeval

#### Install

```bash
brew tap instrumenta/instrumenta
brew install kubeval
```

#### Parse

`kubeval deploy.yml`

### static code analysis - kube-score

`docker run -v $(pwd):/project zegl/kube-score:v1.10.0 score deploy.yml`

#### Deploy to K8S from Private Dockerhub repo

```bash
kubectl apply -f deploy.yml

kubectl get deployments                    

NAME               READY   UP-TO-DATE   AVAILABLE   AGE
hello-deployment   0/2     2            0           5m58s

kubectl get pods
NAME                                READY   STATUS             RESTARTS   AGE
hello-deployment-54b9b7c848-7z56w   0/1     ImagePullBackOff   0          79m
hello-deployment-54b9b7c848-plkq7   0/1     ImagePullBackOff   0          79m
```

#### Create secret from Docker information

```bash
// not advised, due to env variables
//  Private Docker Registry FQDN = https://index.docker.io/v2/ for DockerHub

export NAME=xxx
export PSWD=xxx
export EMAIL=xxx
kubectl create secret docker-registry regcred --docker-server=https://index.docker.io/v2/ --docker-username=${NAME} --docker-password=${PSWD} --docker-email=${EMAIL}
```

#### Get secret

`kubectl get secret regcred --output=yaml`

#### Debug secret was created correctly

`kubectl get secret regcred --output="jsonpath={.data.\.dockerconfigjson}" | base64 --decode`

#### Add secret to yaml file

```yaml
   spec:
     containers:
     - name: app
       image: "foobar/flasksidecardemo"
     imagePullSecrets:
       - name: regcred
```

#### Debug secret was created correctly

```bash
kubectl apply -f deploy.yml 

kubectl get pods       
NAME                                READY   STATUS              RESTARTS   AGE
hello-deployment-566f549976-5nsm7   0/1     ContainerCreating   0          6s
hello-deployment-566f549976-fh6c7   0/1     ContainerCreating   0          6s


kubectl get deployments
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
hello-deployment   2/2     2            2           32s
```

#### Delete secret

`kubectl delete secret regcred`

## Terraform

### Validate

#### local files

```bash
terraform init -backend=false
terraform validate  
```

#### plan changes

terraform plan 

### Lint ( macOS )

`brew install tflint`

#### Upgrade flint

`brew upgrade tflint`

#### Check installed versions

```bash
brew list --formulae |
xargs brew info --json |
jq -r '
    ["name", "latest", "installed version(s)"],
    (.[] | [ .name, .versions.stable, (.installed[] | .version) ])
    | @tsv
'
```

#### Where is lint

```bash
which tflint               
/usr/local/bin/tflint
```

#### Set Cloud environment ( so lint rules work )

`vi ~/.tflint.hcl`

Copy in plug-in data from [here](https://github.com/terraform-linters/tflint-ruleset-aws).

#### Init the lint

`tflint --init`

#### TF file lint

```bash
tflint foobar_file.tf

# Behind the scenes
tflint -c ~/.tflint.hcl foobar.tf 

# Set log level
tflint --loglevel trace foobar.tf

# Debug
TFLINT_LOG=debug tflint

```
