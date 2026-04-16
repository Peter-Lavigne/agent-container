FROM ubuntu:24.04

ARG USER_UID=1000
ARG USER_GID=1000
ARG USERNAME=peter

ENV DEBIAN_FRONTEND=noninteractive

# Ubuntu 24.04 ships a default "ubuntu" user at UID 1000 — remove it so the
# host user can be created at that UID.
RUN userdel -r ubuntu 2>/dev/null || true

# Ubuntu's docker image strips /usr/share/doc/*; re-include fzf examples
# (~/.bashrc sources key-bindings.bash from there).
RUN echo 'path-include=/usr/share/doc/fzf/examples/*' \
        > /etc/dpkg/dpkg.cfg.d/keep-fzf-examples \
    && apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        fzf \
        git \
        gnupg \
        ripgrep \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

RUN curl -LsSf https://astral.sh/uv/install.sh \
    | env UV_INSTALL_DIR=/usr/local/bin INSTALLER_NO_MODIFY_PATH=1 sh

RUN uv tool install playwright \
    && /root/.local/bin/playwright install-deps firefox \
    && uv tool uninstall playwright \
    && uv cache clean

RUN groupadd -g ${USER_GID} ${USERNAME} \
    && useradd -m -u ${USER_UID} -g ${USER_GID} -s /bin/bash ${USERNAME}

USER ${USERNAME}
WORKDIR /home/${USERNAME}

# Some tools expect uv at ~/.local/bin/uv (uv is installed at /usr/local/bin).
RUN mkdir -p /home/${USERNAME}/.local/bin \
    && ln -sf /usr/local/bin/uv /home/${USERNAME}/.local/bin/uv

# Install Python 3.14.3 at the same path host's .venv references
# (~/.local/share/uv/python/cpython-3.14.3-linux-x86_64-gnu).
RUN uv python install 3.14.3

# Claude Code (native installer, auto-updates into ~/.local/bin).
RUN curl -fsSL https://claude.ai/install.sh | bash

# Pre-create ~/.cache so bind-mounting ~/.cache/ms-playwright doesn't leave
# the parent owned by root (which would block uv from writing ~/.cache/uv).
RUN mkdir -p /home/${USERNAME}/.cache

CMD ["sleep", "infinity"]
