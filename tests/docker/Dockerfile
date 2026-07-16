# ==============================================================================
# DISTRO TEST IMAGE
# Parameterized base for running the installer and test suites on any distro.
# Build: docker build -f tests/docker/Dockerfile --build-arg BASE_IMAGE=<image> tests/docker
# ==============================================================================

ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

ENV TERM=xterm-256color \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

COPY prepare.sh /prepare.sh
RUN sh /prepare.sh && rm /prepare.sh

USER testuser
WORKDIR /home/testuser

CMD ["bash"]
