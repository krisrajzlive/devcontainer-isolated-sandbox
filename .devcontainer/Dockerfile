FROM python:3.12-slim

ARG USERNAME=dev
ARG UID=1000

RUN useradd --create-home --uid ${UID} --shell /bin/bash ${USERNAME} \
    && mkdir -p /workspace /opt/seed \
    && chown ${USERNAME}:${USERNAME} /workspace

# Seed content is baked into the image so the sandbox never needs a host bind mount.
COPY --chown=${USERNAME}:${USERNAME} app /opt/seed/app
COPY --chown=${USERNAME}:${USERNAME} scripts /opt/seed/scripts

USER ${USERNAME}
WORKDIR /workspace
