# Docker, Containers, Snyk and Kubernetes
<!-- TOC depthfrom:2 depthto:3 withlinks:true updateonsave:true orderedlist:false -->

- [Docker](#docker)
    - [Dockerfile](#dockerfile)
    - [Build](#build)
    - [Run](#run)
    - [CMD, RUN and ENTRYPOINT](#cmd-run-and-entrypoint)
    - [Local credentials](#local-credentials)
    - [Image introspection](#image-introspection)
    - [Containers](#containers)
    - [Copy](#copy)
    - [Clean-up](#clean-up)
    - [Sidecar design pattern](#sidecar-design-pattern)
- [circleci](#circleci)
    - [Pass values from Docker Container to Host](#pass-values-from-docker-container-to-host)
    - [Set environment variable](#set-environment-variable)
    - [local setup](#local-setup)
    - [circleci setup](#circleci-setup)
    - [Validate config file](#validate-config-file)
    - [Speed](#speed)
    - [Define what branches you test on](#define-what-branches-you-test-on)
    - [On every config.yaml change](#on-every-configyaml-change)
    - [Share Docker Containers](#share-docker-containers)
    - [Resources](#resources)
- [Snyk](#snyk)
    - [Setup](#setup)
    - [Upgrade](#upgrade)
    - [Verify it works](#verify-it-works)
    - [Find local auth token](#find-local-auth-token)
    - [Container scan](#container-scan)
    - [Code scan](#code-scan)
    - [Dependency scan](#dependency-scan)
    - [custom filter results](#custom-filter-results)
    - [apply patches to your vulnerable dependencies](#apply-patches-to-your-vulnerable-dependencies)
    - [Test Javascript packages via CLI](#test-javascript-packages-via-cli)
    - [Monitor for new vulnerabilities](#monitor-for-new-vulnerabilities)
    - [Infrastructure as Code scanning](#infrastructure-as-code-scanning)
- [TwistLock](#twistlock)
- [Kubernetes](#kubernetes)
    - [Commands](#commands)
    - [Pod Creation](#pod-creation)
    - [Namespaces](#namespaces)
    - [can-i get](#can-i-get)
    - [API Server](#api-server)
    - [Secrets](#secrets)
    - [Logs](#logs)
    - [Delete](#delete)
    - [Drain and Cordon](#drain-and-cordon)
    - [Kubernetes auto complete](#kubernetes-auto-complete)
    - [Kubernetes for Docker Desktop](#kubernetes-for-docker-desktop)
    - [KubeVal](#kubeval)
    - [KubeSec](#kubesec)
- [Terraform](#terraform)
    - [Writing](#writing)
    - [Lint  macOS](#lint--macos)

<!-- /TOC -->

## Docker

### Dockerfile

#### Pro tip - chown

```bash
# before
COPY install_zip.sh .
RUN chown -R myuser install_zip.sh

# after
COPY --chown=myuser install_zip.sh .
```

#### Pro tip - pip caching

`pip` keeps a copy of downloaded packages on disk.  Disable:

```bash
# No cache and pin version
RUN pip install --no-cache-dir poetry==${POETRY_VERSION}
```

#### lint

```bash
brew install hadolint
hadolint Dockerfile
```

#### Python - do I use a virtualenv?

<https://stackoverflow.com/questions/29146792/why-people-create-virtualenv-in-a-docker-container>

#### multiple RUN vs single chained RUN

[multiple-run-vs-single-chained-run](https://stackoverflow.com/questions/39223249/multiple-run-vs-single-chained-run-in-dockerfile-which-is-better):

>When possible, I always merge together commands that create files with commands that delete those same files into a single RUN line. This is because each RUN line adds a layer to the image, the output is quite literally the filesystem changes that you could view with docker diff on the temporary container it creates.

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

#### Dockerfile design

<https://www.youtube.com/watch?v=15GYSxzdTLQ>

#### BuildKit

Reference: <https://pythonspeed.com/articles/docker-buildkit/>

### Build

#### Build options

```bash
# Build present working directory
docker build -f Dockerfile -t $(pwd | xargs basename):latest .

# View progress in plaintext
docker build -f Dockerfile -t $(pwd | xargs basename):latest . --progress=plain

# Target a setp.  Debug a multi-stage build
docker build -f Dockerfile --target builder -t $(pwd | xargs basename):latest .

# docker-compose with BuildKit for Secrets
DOCKER_BUILDKIT=1 COMPOSE_DOCKER_CLI_BUILD=1 docker-compose -f docker-compose.yml 
build --build-arg build_secret=${BUILD_SECRET} --progress=plain --no-cache

## Build argument to env var in container
docker build -f Dockerfile --build-arg FOO_VERSION="$(./foo_echo_version_script)" -t $(pwd | xargs basename):latest .

  ## Dockerfile
  ARG FOO_VERSION
  ENV MY_FOO_VERSION ${FOO_VERSION}

# Stop secrets leaking in Docker History or an Image Layer
DOCKER_BUILDKIT=1 \
docker build -t $(pwd | xargs basename) \
  --secret id=build_secret,src=build_secret.txt \
  --progress=plain --no-cache \
  .
```

### Run

```bash
# interactive bash shell for container
docker run -it $(pwd | xargs basename):latest bash

 # mount AWS directory as Read-Only for set AWS environment variables

docker run \
    --rm \
    --env AWS_PROFILE=foo \
    --env AWS_REGION=eu-west-3 \
    -v $HOME/.aws/:/root/.aws/:ro \
    -it $(pwd | xargs basename):latest \
    bash

# get file from Container to Host
  # inside Dockerfile: 
CMD ["./create_zip_file.sh"]
  # to get the zip file mount the dir/file to host 
docker run --rm -v /tmp/my_host:/tmp/my_container $(pwd | xargs basename):latest

# mount file. Better to pass in via Dockerfile but passing is as a command line argument works for some edge cases
docker run \
        --env TOKEN=${TOKEN} \
        -v $(pwd)/Dockerfile:/Dockerfile \
        -it ${REPONAME}:latest \
        bash

#### Interactive, terminal specify Bash
docker run -it ubuntu bash

#### Automatically remove container when it exits
docker run --rm -it ubuntu 

#### network connections ON THE HOST

docker run -it --net=container:${APISERVER_ID} controlplane/alpine-base

#### Automatically remove container when it exits after running a shell command
docker run \
  --rm \
  "${CIRCLE_PROJECT_REPONAME}:${CIRCLE_SHA1}" \
  /bin/bash -c '
    echo "Hello there"
  '

#### Name container for Docker Container ls
docker run --name foobar -it ubuntu

# Run service in background
docker pull swaggerapi/swagger-editor
docker run -d -p 7999:8080 swaggerapi/swagger-editor

# Interactive, detach and allocate Pseudo Terminal
docker run -idt ..

#### Run in privileged
docker run --privileged

# App Armor
docker run --rm -it --security-opt apparmor=docker-default duckll/ctf-box

# Start container
docker start ctf

# Stop container
docker stop ctf
```

### CMD, RUN and ENTRYPOINT

Nice article [here](https://goinbigdata.com/docker-run-vs-cmd-vs-entrypoint/):

#### RUN

install your application and packages required.

#### CMD

Set a default command. Executed only when you run container without specifying a command.

```Dockerfile
CMD echo "Hello world" 
```

```bash
docker run -it <image>
Hello world

docker run -it <image> /bin/bash
< no Hello world >
```

#### ENTRYPOINT

Command(s) not ignored when Docker container runs with command line parameters.

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

### Image introspection

#### Skopeo

```bash
brew install skopeo

# inspect an image on Docker Hub
skopeo inspect docker://docker.io/fedora:latest --override-os linux

# inspect a specific tagged version
skopeo inspect docker://docker.io/foobar/foo:0.1.0

# inspect latest tag
skopeo inspect docker://docker.io/foobar/foo:latest

# Copy from Docker Hub
skopeo copy docker://docker.io/foobar/foo:latest dir:foobar

# Save from Docker Hub
skopeo copy docker://docker.io/foobar/foo:latest docker-archive:foo.tar

```

#### Search for secrets in layers

```bash
# Save Image for inspection
docker save foo:latest -o ~/foo.tar

# Extract the Docker layers
mkdir ~/foo && tar xf ~/foo.tar -C ~/foo | cd ~/foo

# Search each layer
for layer in */layer.tar; do tar -tf $layer | grep -w secret.file && echo $layer; done

# Or search for a specifc file
find . -name "*secret*"

# Extract where it found secret
tar xf FFFFFFFFF/layer.tar app/secret.file

# Print the secret
cat app/secret.file
```

#### Logs

```bash
# Keep container alive and echoing data
docker run -d busybox /bin/sh -c 'i=0; while true; do echo "$i: $(date)"; i=$((i+1)); sleep 1; done'

# Get container ID
docker ps
CONTAINER ID   IMAGE 
9a0c73bcf87d   busybox

# Get logs
docker logs 9a0c73bcf87d -f
```

#### Inspect

```bash
# Dive
brew install dive
dive docker://$(pwd | xargs basename)

# Image
docker image history alpine_non_root --no-trunc

# Tag
docker history foobar:v1 

# If built local folder into image
docker history $(pwd | xargs basename)

# Print layers
docker inspect --format='{{json .RootFS.Layers}}' foobar

# Inspect local image
docker image inspect $(pwd | xargs basename)

# Pretty Print
docker history --format "{{.ID}}: {{.CreatedSince}}" foo/bar:0.2.1

# Logs from Container ID
docker logs bd0657a17d54

# check if container is running as Privileged
docker inspect --format='{{.HostConfig.Privileged}}' <container id>

# Stats
docker stats < container ID >
```

#### Push to DockerHub

```bash
<Create Private repo on Dockerhub>
docker build -t rusty/flasksidecardemo .
sudo lsof -iTCP -sTCP:LISTEN -n -P 	# check no containers running on port
docker run -d -p 5000:5000 rusty/flasksidecardemo
docker push rusty/flasksidecardemo
```

### Containers

```bash
# Show Container IDs
docker ps

# Show Container IDs with memory footprint of the Thin R/W Layer
docker ps -s

# A history of images and container IDs
docker ps -a

# All exited container IDs
docker ps --all --filter STATUS=exited

# All running container IDs
docker ps --all --filter STATUS=running

# Run interactive Terminal with Cut and Paste
docker container exec -it ctf bash

# Stop by Container ID
docker stop <container id>

```

### Copy

#### from Host to Docker Container

`docker cp foo/bar.c bd0657a17d54://root/newbar.c`

#### check if image can mount disk on Host

`mount -t tmpfs none /mnt`

### Clean-up

```bash
# Remove all stopped containers
docker rm $(docker ps -a -q)

# Remove all all images not referenced by a container
docker image prune --all

# Removes images created more than 10 days (240h) ago
docker image prune -a --force --filter "until=240h"

# Container ( removed before Image removal )
docker container rm <container id>

# Remove Image
docker image rm <image id> --force

# Remove Image, force
docker rmi -f duckll/ctf-box
```

### Sidecar design pattern

There are [lots of design patterns](https://techbeacon.com/enterprise-it/7-container-design-patterns-you-need-know) with containers.  If containers only have "one responsibility", the `sidecar pattern` ensures you add common functionaly out of a container. This includes:

- Logging
- Monitoring
- TLS set up
- Strip / add Response Headers
- Configuration

Overview [here](https://containerjournal.com/topics/container-security/tightening-security-with-sidecar-proxies/):
> `Decoupling` of common tasks to an independent unified service deployed alongside any core application service is known as a “sidecar” architecture.  Primary application in Go.   Existing functionality written in Python to collect logs and metrics.  Offloading that Python code into a sidecar is more efficient than asking the development team to rewrite that functionality in Go.

#### Security references

- [NPM_TOKENS_LEAKING_IN_DOCKER](https://www.alexandraulsh.com/2018/06/25/docker-npmrc-security/)
- [CVE-2019-5736: runc container breakout](https://seclists.org/oss-sec/2019/q1/119)
- [Docker_Security_Cheat_Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)

## circleci

### Pass values from Docker Container to Host

I struggled for hours with this.  I expected that `docker run -v /tmp:/data $(pwd | xargs basename):latest` would pass all files from `data` on the Container to the `tmp` folder of the Host.  That didn't happen.

The reason is referenced in the [tech documents](https://circleci.com/docs/2.0/building-docker-images/):

>It is not possible to mount a volume from your job space into a container in Remote Docker (and vice versa).

The answer is simpler:

```yaml
- run: |
    # start container with the application
    # make sure you're not using `--rm` option
    docker run --name app app-image:1.2.3

- run: |
    # after application container finishes, copy artifacts directly from it
    docker cp app:/output /path/in/your/job/space
```

### Set environment variable

You can set `Organization` or `Project` level environment variables.   Sometimes it is useful to override a `Organization` variable in a single `Circle CI Job`:

```yaml
jobs:
  build:
    environment:
      FOO: bar
```

[Reference](https://circleci.com/docs/2.0/configuration-reference/#modifiers).

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

### Speed

Don't chain `requires` unless required:

```yaml
workflows:
  my_workflow:
    jobs:
      - prod_image
      - test_image
      - push_code:
          requires:
          - prod_image
      - scan_with_some_tool:
          requires:
          - test_image
```

### Define what branches you test on

```yaml
filter_deployable: &filter_deployable
  filters:
    branches:
      only:
        - sandbox
        - master
workflows:
  my_workflow:
    jobs:
    ...
    ...
      - scan_with_some_tool:
            <<: *filter_deployable
            requires:
            - test_image
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

### Share Docker Containers

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
snyk auth
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

### Container scan

```bash
snyk container test busybox
snyk test --docker alpine --file=Dockerfile --exclude-base-image-vulns
snyk container test $(basename $(pwd)) --file=Dockerfile
snyk test --docker alpine --file=Dockerfile --exclude-base-image-vulns
snyk container monitor --docker $(basename $(pwd)):latest --file=Dockerfile --debug
snyk test --severity-threshold=critical --docker alpine --file=Dockerfile --json > ~/results.json
```

### Code scan

```bash
snyk config set org=playground
snyk code test
snyk code test --sarif
snyk code test --severity-threshold=high
```

### Dependency scan

```bash
# Python and poetry
snyk test --file=poetry.lock --package-manager=poetry

# pip and Python3
pip install -r requirements.txt

# force Snyk to consider Python3
snyk test --file=requirements.txt --package-manager=pip --command=python3

# Send Snapshot to Snyk
snyk monitor --severity-threshold=high --file=requirements.txt --package-manager=pip --command=python3 
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

## TwistLock

```bash
# install
curl --progress-bar -L -k --header "authorization: Bearer API-TOKEN" https://kubernetes:30443/api/v1/util/twistcli > /usr/local/bin/twistcli

chmod a+x /usr/local/bin/twistcli

# scan
/usr/local/bin/twistcli defender export kubernetes \
        --address https://kubernetes:30443 \
        --user ${USERNAME} \
        --password ${PASSWORD} \
        --cluster-address twistlock-console \
        --output defender.yaml
```

## Kubernetes

### Commands

- <https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands>
- <https://kubernetes.io/docs/reference/kubectl/cheatsheet/>

```bash
# version
kubectl version
kubectl version -o json

# view config
kubectl config view
kubectl config view
kubectl config view -o jsonpath='{.users[].name}' 

# Deploy
kubectl apply -f deploy.yml

# Describe deployment
kubectl describe po hello-deployment

# Deploy status
kubectl rollout status deployment/hello-deployment

# Get deployments
kubectl get deployments

# create Pod named "secret" with yaml file
kubectl apply -f secret-pod.yml

# create Pod manually
kubectl run mypod --image=controlplane/secrets-demo:1.0

# get env variables from mypod
kubectl exec -it mypod -- env

#  Find which node your pod is running on
kubectl describe pods my_pod

# get pods regardless of namespace
kubectl get pods --all-namespaces --output wide

# get pods
kubectl get pods
kubectl get pods -A -o=custom-columns='DATA:spec.containers[*].image'
kubectl get pods --namespace default --output=custom-columns="NAME:.metadata.name,IMAGE:.spec.containers[*].image"

# get Pod registry info
kubectl describe pod privateer-1 | grep -i image

# get IP addresses
kubectl get pods -o wide

# debug
watch kubectl get pods -o wide

# Get services
kubectl get services

# Get a service
kubectl get svc hello-svc

# Get ReplicaSets
kubectl get rs

# Scale
kubectl scale -n default deployment hello-deployment --replicas=3

```

### Pod Creation

![PodCreation](.images/pod_creation.png)

### Namespaces

Logically group applications, environments, teams, etc.

```bash
kubectl get namespaces
kubectl get pods --all-namespaces
kubectl create namespace foobar
kubectl run nginx --image=nginx --namespace=foobar
kubectl get all --namespace=foobar
kubectl delete namespace foobar
```

### can-i get

```bash
# verb, resource, and optional resourceName
kubectl auth can-i get rs

# verb, resource, and optional resourceName
kubectl auth can-i --list
```

### API Server

```bash
# API image
APISERVER_IMAGE=$(docker ps | awk '/k8s_kube-apiserver/{print $2}')
echo "${APISERVER_IMAGE}"

# API server connections
sudo lsof -Pan -i tcp | grep 6443

# API server info
ps faux | sed -E 's,.*(kube-apiserver.*),\1,g;t;d' | grep -v 'g;t;d' | tr ' ' '\n'

# Kill API server and watch restart
sudo kill -9 "$(ps faux | grep kube-apiserver | head -1 | awk '{print $2}')"
sleep 1
docker ps | grep k8s_kube-apiserver
```

### Secrets

```bash
# create secrets from files
kubectl create secret generic user-pass --from-file=./username.txt --from-file=./password.txt

# create secrets from env vars
kubectl create secret docker-registry regcred --docker-server=https://index.docker.io/v2/ --docker-username=${NAME} --docker-password=${PSWD} --docker-email=${EMAIL}

# get secret info ( not the secret )
kubectl get secrets

# get secret as B64 encoded
kubectl get secret user-pass -o yaml

# get secret info
kubectl get secret regcred --output="jsonpath={.data.\.dockerconfigjson}" | base64 --decode

# meta data about secret
kubectl describe secret user-pass

# check for issues
kubectl logs secret

```

### Logs

```bash
# logs of a single container
WEAVE_POD=$(kubectl get --namespace kube-system pods -l name=weave-net -o json | jq -r '.items[0].metadata.name')
kubectl logs --namespace kube-system $WEAVE_POD --container weave

# etcd - "system of record".  Distributed consensus.   Highly available.
kubectl logs -f -n kube-system etcd-kubernetes-master

# Follow - real-time container log output
kubectl logs --namespace kube-system $WEAVE_POD --container weave --follow

# Cluster events
kubectl get events --sort-by=.metadata.creationTimestamp | tail -n 20

# Info about Kubelet daemon
systemctl status kubelet.service
```

### Delete

```bash
# delete all
kubectl delete all --all    
# delete Pod in Namespace "kube-system"
kubectl delete pod --namespace kube-system $KUBE_PROXY
kubectl delete -f deploy.yml
kubectl delete -n default deployment hello-deployment
kubectl delete replicaset demo-api
kubectl delete service demo-api
kubectl delete pod busybox-curl
kubectl delete namespace my-namespace
```

### Drain and Cordon

```bash
# Drain node in preparation for maintenance
kubectl drain kubernetes-worker-0 --ignore-daemonsets

# Mark node as schedulable
kubectl uncordon kubernetes-worker-0

# Mark node as unschedulable
kubectl cordon kubernetes-worker-0
```

### Kubernetes auto complete

```bash
source <(kubectl completion zsh)  
echo "[[ $commands[kubectl] ]] && source <(kubectl completion zsh)" >> ~/.zshrc # add autocomplete permanently to your zsh shell
```

### Kubernetes for Docker Desktop

Great [tutorial](https://andrewlock.net/running-kubernetes-and-the-dashboard-with-docker-desktop/):

```bash
# check Kubernetes is "enabled" inside of `Docker Desktop
kubectl config get-contexts
kubectl config use-context docker-desktop
kubectl get nodes

# Dashboard
kubectl edit deployment kubernetes-dashboard -n kubernetes-dashboard

# Install
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.2.0/aio/deploy/recommended.yaml

# Disabling the login prompt in Kubernetes Dashboard
kubectl patch deployment kubernetes-dashboard -n kubernetes-dashboard --type 'json' -p '[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--enable-skip-login"}]'

# Delete
kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.2.0/aio/deploy/recommended.yaml
```

### KubeVal

```bash
brew tap instrumenta/instrumenta
brew install kubeval
kubeval deploy.yml
```

#### Raft

[Overview](https://runway.systems/?model=github.com/ongardie/runway-model-raft#)

### KubeSec

<https://kubesec.io/>

#### Kube-score

`docker run -v $(pwd):/project zegl/kube-score:v1.10.0 score deploy.yml`

## Terraform

### Writing

Writing [AWS Terraform files](https://blog.gruntwork.io/an-introduction-to-terraform-f17df9c6d180) introduction:

```terraform
brew upgrade hashicorp/tap/terraform
terraform --version
terraform -install-autocomplete
terraform init
terraform plan
terraform apply
terraform output
terraform output public_ip
```

#### Validate

```bash
terraform init -backend=false
terraform validate  
```

#### Debug variables

```bash
terraform refresh
terraform show 
terraform show -json | jq .
```

#### APIs

```bash
# Gets List of strings
value = local.country_codes

# Convert from List of Strings to Map
value = { for idx, val in local.foobar_domains : idx => val }

# Get List of String values if
value = [for x in local.foobar_domains : x if x == "foobar.fr"]

# get index
value = index(local.foobar_domains, "foobar.fr")

# Contains Boolean response
contains(local.foobar_domains, "foobar.fr")
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
