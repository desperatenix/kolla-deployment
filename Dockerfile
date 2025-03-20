ARG DEBIAN_VERSION

FROM debian:${DEBIAN_VERSION} as base
ARG DEBIAN_FRONTEND=noninteractive
COPY configs/apt.conf /etc/apt/apt.conf

RUN apt-get update \
    && apt-get install -y git \
    python3-dev \
    libffi-dev gcc \
    libssl-dev \
    python3-socks \
    python3-requests \
    python3-requests-cache \
    pipx

RUN useradd -ms /bin/bash -b /etc kolla
USER kolla

FROM base as ansible

ARG HOME_DIR=/etc/kolla

#RUN pipx install --pip-args no-cache-dir pip
#&& pip install --no-cache-dir 'ansible>=4,<6'

#Не понятно, почему не работает $HOME
ENV PATH="${HOME_DIR}/.local/bin:$PATH"

ARG KOLLA_VERSION
FROM ansible as kolla_stage

RUN pipx install   git+https://opendev.org/openstack/kolla-ansible@stable/${KOLLA_VERSION} \
    && pipx install 'ansible>=6,<8'  --include-deps \
    && kolla-ansible install-deps

FROM debian:${DEBIAN_VERSION} as kolla_base

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install --no-install-recommends -y python3 \
    openssh-client

RUN useradd -ms /bin/bash -b /etc kolla
USER kolla

WORKDIR /etc/kolla

ENV PATH="/etc/kolla/.local/bin:$PATH"

FROM kolla_base as deployment
COPY --from=kolla_stage --chown=kolla:kolla /etc/kolla/.ansible .ansible
COPY --from=kolla_stage --chown=kolla:kolla /etc/kolla/.local .local
