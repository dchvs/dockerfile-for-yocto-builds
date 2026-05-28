# Build container image
# DOCKER_IMAGE_NAME=scarthgap
# DOCKER_BUILDKIT=1 docker build -f Dockerfile --no-cache --network host -t $DOCKER_IMAGE_NAME .

# Start container
# docker run --rm -it --privileged --network host -e USER=$USER -e UID=$(id -u) -e GID=$(id -g) \
#     -v $PWD:/workdir -v $HOME/.gitconfig:$HOME/.gitconfig -v $HOME/.ssh:$HOME/.ssh \
#     $DOCKER_IMAGE_NAME bash

FROM ubuntu:22.04

RUN apt-get update -y
RUN DEBIAN_FRONTEND=noninteractive TZ="America/Costa_Rica" \
    apt-get -y install tzdata gosu

RUN apt-get install -y \
    build-essential chrpath cpio debianutils diffstat file \
    gawk gcc git iputils-ping libacl1 liblz4-tool locales \
    python3 python3-git python3-jinja2 python3-pexpect python3-pip \
    python3-subunit socat texinfo unzip wget xz-utils zstd

RUN apt-get install -y \
    apt-utils \
    coreutils \
    curl \
    device-tree-compiler \
    git-lfs \
    nano \
    openssh-client \
    openssh-server \
    rsync \
    screen \
    ssh-import-id \
    sudo \
    tmux \
    tree \
    util-linux \
    vim

RUN git clone --depth 1 -b master https://git.openembedded.org/bitbake /opt/bitbake \
    && ln -s /opt/bitbake/bin/bitbake-setup /usr/bin/bitbake-setup

COPY patches/ /tmp/patches/
RUN for p in /tmp/patches/*.patch; do \
        git -C /opt/bitbake apply "$p"; \
    done \
    && rm -rf /tmp/patches

ENV PYTHONPATH="/opt/bitbake/lib:${PYTHONPATH}"

ARG USER
ARG UID
ARG GID

ENV USER=${USER}
ENV UID=${UID}
ENV GID=${GID}

USER ${USER}

ENV TERM=xterm-256color
RUN printf "PS1='${debian_chroot:+(\$debian_chroot)}\\[\\033[01;32m\\]\\u@\\h\\[\\033[00m\\]:\\[\\033[01;34m\\]\\w\\[\\033[00m\\]\\$ '\n" \
    >> /etc/bash.bashrc

RUN printf "alias ls='ls --color=auto'" >> /etc/bash.bashrc

RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
RUN locale-gen

WORKDIR /workdir

ENTRYPOINT ["/bin/bash","-lc", "\
    getent group ${GID} >/dev/null || groupadd --gid ${GID} ${USER}; \
    getent passwd ${UID} >/dev/null || useradd -p \"\" -l --uid ${UID} \
        --gid ${GID} ${USER} --shell /bin/bash; \
    usermod -a -G sudo ${USER}; \
    exec gosu ${UID}:${GID} \"$@\" \
    ", "--"]
CMD ["bash"]
