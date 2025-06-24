FROM ${BASE_IMAGE}


# sudo 설치 및 기타 유틸리티
RUN apt-get update && apt-get install -y sudo git

# UID 기반 조건부 사용자 처리 (충돌 감지)
RUN EXISTING_USER=$(getent passwd ${USER_UID} | cut -d: -f1 || echo "") && \
    if [ -n "$EXISTING_USER" ]; then \
        echo "Found existing user: $EXISTING_USER with UID ${USER_UID}" && \
        usermod -aG sudo "$EXISTING_USER" && \
        echo "$EXISTING_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
        usermod -p $(openssl passwd -1 ${USER_PASSWORD}) "$EXISTING_USER" && \
        passwd -u "$EXISTING_USER" && \
        echo "$EXISTING_USER" > /tmp/actual_user; \
    else \
        echo "Creating new user: ${USERNAME}" && \
        (groupadd -g ${USER_GID} ${USERNAME} || true) && \
        (useradd -m -d /home/${USERNAME} -u ${USER_UID} -g ${USER_GID} ${USERNAME} || true) && \
        usermod -aG sudo ${USERNAME} && \
        echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
        echo "${USERNAME}:${USER_PASSWORD}" | chpasswd && \
        echo "${USERNAME}" > /tmp/actual_user; \
    fi

# 작업 디렉토리 생성 및 권한 설정
RUN mkdir -p /workspace && \
    chown -R ${USER_UID}:${USER_GID} /workspace

# SSH 디렉토리 생성 (실제 사용자 기준)
RUN ACTUAL_USER=$(cat /tmp/actual_user) && \
    mkdir -p /home/$ACTUAL_USER/.ssh && \
    chmod 700 /home/$ACTUAL_USER/.ssh && \
    chown -R ${USER_UID}:${USER_GID} /home/$ACTUAL_USER/.ssh

# 한국어 로케일 설정 및 쉘 자동 변경 설정 (실제 사용자 기준)
RUN ACTUAL_USER=$(cat /tmp/actual_user) && \
    echo "export LANG=ko_KR.UTF-8" >> /home/$ACTUAL_USER/.bashrc && \
    echo "export LC_ALL=ko_KR.UTF-8" >> /home/$ACTUAL_USER/.bashrc && \
    touch /home/$ACTUAL_USER/.profile && \
    chown ${USER_UID}:${USER_GID} /home/$ACTUAL_USER/.bashrc && \
    chown ${USER_UID}:${USER_GID} /home/$ACTUAL_USER/.profile


# 볼륨 마운트 시 권한 문제 해결을 위한 스크립트 추가
RUN echo '#!/bin/bash\nif [ -d "/workspace" ] && [ "$(stat -c %u "/workspace")" != "$(id -u)" ]; then\n  sudo chown -R $(id -u):$(id -g) "/workspace"\nfi\nexec "$@"' > /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

# Git 안전 디렉토리 설정
# 사용자로 전환 대신 sudo 사용
RUN sudo -u \#${USER_UID} git config --global --add safe.directory "*" || true

# 기본 작업 디렉토리 설정
WORKDIR /workspace

# 사용자로 전환
USER ${USER_UID}:${USER_GID}

# 기본 쉘 설정 - 엔트리포인트 스크립트 추가
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"] 