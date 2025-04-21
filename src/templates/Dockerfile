FROM ${BASE_IMAGE}

# 빌드 시 사용할 인자들
ARG USERNAME=${USERNAME}
ARG USER_UID=${USER_UID}
ARG USER_GID=${USER_GID}
ARG USER_PASSWORD=${USER_PASSWORD}
ARG WORKDIR=workspace

# sudo 설치 및 기타 유틸리티
RUN apt-get update && apt-get install -y sudo git

# 사용자 그룹 및 사용자 생성 (단순화된 방식)
RUN (groupadd -g ${USER_GID} ${USERNAME} || true) && \
    (useradd -m -d /home/${USERNAME} -u ${USER_UID} -g ${USER_GID} ${USERNAME} || true)

# 사용자에게 sudo 권한 부여 및 비밀번호 설정
RUN (usermod -aG sudo ${USERNAME} || true) && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    echo "${USERNAME}:${USER_PASSWORD}" | chpasswd || echo "Password will be set later"

# 작업 디렉토리 생성 및 권한 설정
RUN mkdir -p /workspace && \
    chown -R ${USER_UID}:${USER_GID} /workspace

# SSH 디렉토리 생성
RUN mkdir -p /home/${USERNAME}/.ssh && \
    chmod 700 /home/${USERNAME}/.ssh && \
    chown -R ${USER_UID}:${USER_GID} /home/${USERNAME}/.ssh

# 한국어 로케일 설정 및 쉘 자동 변경 설정
RUN echo "export LANG=ko_KR.UTF-8" >> /home/${USERNAME}/.bashrc && \
    echo "export LC_ALL=ko_KR.UTF-8" >> /home/${USERNAME}/.bashrc && \
    touch /home/${USERNAME}/.profile && \
    chown ${USER_UID}:${USER_GID} /home/${USERNAME}/.bashrc && \
    chown ${USER_UID}:${USER_GID} /home/${USERNAME}/.profile

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