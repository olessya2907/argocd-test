#!/bin/bash
# Build the image and run the container
docker build -t demo-app:v1 .
docker run -d --name demo -p 8080:8080 demo-app:v1
sleep 2
echo "App is running at http://localhost:8080/"
