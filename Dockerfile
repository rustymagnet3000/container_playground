#Pull the base image as Alpine
FROM alpine:latest

#Add a user with userid 1001 and name myuser
RUN useradd −u 1001 myuser

#Run Container as nonroot
USER myuser