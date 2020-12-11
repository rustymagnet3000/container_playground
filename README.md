# Docker command reminders
#### Version
`docker --version`
#### Test docker is working
`docker run hello-world`
#### Check docker is running
`docker run busybox date`
#### Where is docker
`which docker`
#### List local images
`docker image ls`
#### View size of image
```
docker image ls duckll/ctf-box
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
duckll/ctf-box      latest              089e6adcad4d        9 months ago        1.74GB
```
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
#### Run interactive Terminal with Cut and Paste
`docker container exec -it ctf bash`
#### Start service
`docker run -d -p 80:8181 blah_swagger/foobar`
#### Run interactive, detach and allocate Pseudo Terminal
`docker run -idt ...`
#### Run in privileged
`docker run --privileged`
#### Start the Swagger spec with a custom Port
`docker run -d -p 7999:8080 blah_swagger/foobar`      # http://localhost:7999/
#### App Armor
`docker run --rm -it --security-opt apparmor=docker-default duckll/ctf-box`
#### Stop by Container ID
`docker stop <container id>`
#### Remove Container
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
https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html
