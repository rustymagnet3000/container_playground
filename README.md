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
#### Show Container IDs
`docker ps`
#### Show Container IDs with memory footprint of the Thin R/W Layer
`docker ps -s`
#### A history of everything launched
`docker ps -a`
#### Load service [first time only]
`docker load -i foobar.tar.gz`
#### Start service
`docker run -d -p 80:8181 blah_swagger/foobar`
#### Start the Swagger spec with a custom Port
```
docker run -d -p 7999:8080 blah_swagger/foobar
http://localhost:7999/
```
#### Stop by Container ID
`docker stop xxxxxxxxx`
#### Stop by Image name
`docker stop foobar-service`
#### Remove Image
`docker image rm xxxxxxxxx --force`
#### Misc
`docker history foobar:v1`
