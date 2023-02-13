ARG UBUNTU_VERSION

FROM ubuntu:${UBUNTU_VERSION} as base
ARG DEBIAN_FRONTEND=noninteractive
COPY configs/apt.conf /etc/apt/apt.conf

RUN apt-get update \
    && apt-get install -y git \
    python3-dev \
    libffi-dev gcc \
    libssl-dev \
    python3-pip \
    python3-socks

RUN useradd -ms /bin/bash -b /etc kolla
USER kolla

FROM base as ansible

ARG HOME_DIR=/etc/kolla

RUN pip install -U --no-cache-dir pip \
    && pip install --no-cache-dir 'ansible>=4,<6'

#Не понятно, почему не работает $HOME
ENV PATH="${HOME_DIR}/.local/bin:$PATH"

ARG KOLLA_VERSION
FROM ansible as kolla_stage

RUN pip3 install --no-cache-dir  git+https://opendev.org/openstack/kolla-ansible@stable/${KOLLA_VERSION} \
    oauth2 as oauth \
    requests \
    requests_cache \
    && kolla-ansible install-deps

FROM ubuntu:${UBUNTU_VERSION} as kolla_base

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install --no-install-recommends -y python3

RUN useradd -ms /bin/bash -b /etc kolla
USER kolla

WORKDIR /etc/kolla

ENV PATH="/etc/kolla/.local/bin:$PATH"

FROM kolla_base as deployment
COPY --from=kolla_stage --chown=kolla:kolla /etc/kolla/.ansible .ansible
COPY --from=kolla_stage --chown=kolla:kolla /etc/kolla/.local .local