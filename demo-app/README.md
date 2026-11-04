# demo-app

A minimal Flask application for demonstrating a full CI/CD pipeline:
Docker image build → container registry → Kubernetes deployment via GitOps (Argo CD).

The app itself is intentionally tiny — the pipeline around it is the point.

## Endpoints

- `/` — returns `Hello from demo-app {VERSION}!`
- `/health` — returns JSON `{"status": "ok", "version": "{VERSION}"}`.
  Used as a Kubernetes liveness/readiness probe later.

The version comes from the `APP_VERSION` environment variable (default `v1`).

## Run locally

One command to build and start:

./run.sh

Then open http://localhost:8080/ and http://localhost:8080/health.

One command to stop and clean up:

./stop.sh

Manual commands (the scripts do the same):

docker build -t demo-app:v1 .
docker run -d --name demo -p 8080:8080 demo-app:v1
curl localhost:8080/
curl localhost:8080/health
docker stop demo && docker rm demo

## Project layout

demo-app/
├── app.py # Flask app: / and /health endpoints
├── requirements.txt # Python dependencies (Flask)
├── Dockerfile # Image recipe: Python 3.12 slim + app
└── .dockerignore # Keeps .git and caches out of the image

## Roadmap

- [x] Step 1: Dockerize the app, verify locally
- [ ] Step 2: GitHub Actions — build and push image to GHCR on every push
- [ ] Step 3: Kubernetes manifests + Argo CD — GitOps deployment, v1 → v2 demo
