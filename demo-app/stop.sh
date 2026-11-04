#!/bin/bash
# Stop and remove the container
docker stop demo && docker rm demo
echo "Container stopped and removed."
