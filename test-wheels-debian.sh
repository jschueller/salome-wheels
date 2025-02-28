#!/bin/sh

set -e -x
docker build docker/debian11
docker build docker/debian12
