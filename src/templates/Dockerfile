FROM ${BASE_IMAGE}

# 빌드 시 사용할 인자들
ARG USERNAME=user
ARG USER_UID=1001
ARG USER_GID=1001
ARG USER_PASSWORD=1234
ARG WORKDIR=workspace

# sudo 설치 및 기타 유틸리티
RUN apt-get update && apt-get install -y sudo git

# 사용자 그룹 및 사용자 생성
RUN groupadd -g ${USER_GID} ${USERNAME} || echo "Group already exists"
RUN useradd -m -d /home/${USERNAME} -u ${USER_UID} -g ${USERNAME} ${USERNAME}

# 사용자에게 sudo 권한 부여 및 비밀번호 설정
RUN echo "${USERNAME}:${USER_PASSWORD}" | chpasswd && \
    usermod -aG sudo ${USERNAME} && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# 작업 디렉토리 생성 및 권한 설정
RUN mkdir -p /workspace && \
    chown -R ${USERNAME}:${USERNAME} /workspace

# SSH 디렉토리 생성
RUN mkdir -p /home/${USERNAME}/.ssh && \
    chmod 700 /home/${USERNAME}/.ssh && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.ssh

# 한국어 로케일 설정 및 쉘 자동 변경 설정
RUN echo "export LANG=ko_KR.UTF-8" >> /home/${USERNAME}/.bashrc && \
    echo "export LC_ALL=ko_KR.UTF-8" >> /home/${USERNAME}/.bashrc && \
    chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.bashrc && \
    chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.profile

# 볼륨 마운트 시 권한 문제 해결을 위한 스크립트 추가
RUN echo '#!/bin/bash\nif [ -d "/workspace" ] && [ "$(stat -c %u "/workspace")" != "$(id -u)" ]; then\n  sudo chown -R $(id -u):$(id -g) "/workspace"\nfi\nexec "$@"' > /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

# Git 안전 디렉토리 설정
USER ${USERNAME}
RUN git config --global --add safe.directory "*"
USER root

# 기본 작업 디렉토리 설정
WORKDIR /workspace

# 사용자로 전환
USER ${USERNAME}

# 기본 쉘 설정 - 엔트리포인트 스크립트 추가
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"] 