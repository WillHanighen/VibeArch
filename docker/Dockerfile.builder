FROM archlinux:latest

ENV TERM=xterm-256color

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
      archiso \
      rsync \
      squashfs-tools \
      git \
      sudo \
      which \
      sed \
      gawk \
      findutils \
      grep \
      coreutils \
      bash && \
    pacman -Scc --noconfirm

WORKDIR /workspace

ENTRYPOINT ["/bin/bash"]
