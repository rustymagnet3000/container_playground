# Docker command reminders

#### Version

`docker --version`

#### Pull ( slim linux image )

`docker pull alpine`

#### Quick setup

```docker
docker pull alpine:latest

docker run -it alpine 
```

#### Check docker is running

`docker run busybox date`

#### Where is docker

`which docker`

#### List local images

`docker image ls`

#### View size of image

```docker
docker image ls duckll/ctf-box
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
duckll/ctf-box      latest              089e6adcad4d        9 months ago        1.74GB
```

#### Image history

`docker image history duckll/ctf-box`

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

#### Run service ( interactive, terminal flags )

`docker run -it ubuntu`

#### Run service

`docker run -d -p 80:8181 blah_swagger/foobar`

#### Run interactive, detach and allocate Pseudo Terminal

`docker run -idt ...`

#### Run in privileged

`docker run --privileged`

#### Run in non-privileged mode

`docker run -idt --name ctf duckll/ctf-box`

#### Logs from Container ID

`docker logs bd0657a17d54`

#### Copy from Host to Docker Container

`docker cp foo/bar.c bd0657a17d54://root/newbar.c`

#### check if container is running as Privileged

`docker inspect --format='{{.HostConfig.Privileged}}' <container id>`

#### check if image can mount disk on Host

`mount -t tmpfs none /mnt`

#### Start the Swagger spec with a custom Port

`docker run -d -p 7999:8080 blah_swagger/foobar`      # http://localhost:7999/

#### App Armor

`docker run --rm -it --security-opt apparmor=docker-default duckll/ctf-box`

#### Run interactive Terminal with Cut and Paste

`docker container exec -it ctf bash`

#### Stop by Container ID

`docker stop <container id>`

#### Remove Container ( removed before Image removal )

`docker container rm <container id>`

#### Stop by Image name

`docker stop foobar-service`

#### Remove Image

`docker image rm <image id> --force`

#### Force Remove Image

`docker rmi -f duckll/ctf-box`

#### Misc

`docker history foobar:v1`

#### Security cheat sheet

<https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html>
