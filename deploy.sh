#!/bin/bash

skaffold run -p gcb --default-repo=us-docker.pkg.dev/$GOOGLE_CLOUD_PROJECT/microservices-demo
