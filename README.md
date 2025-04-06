# Docker 개발 환경 설정 도구

이 도구는 Docker를 사용하여 개발 환경을 빠르게 설정하기 위한 스크립트입니다.

## 기능

- 사용자 정의 개발 환경 Docker 이미지 생성
- 현재 사용자 설정(UID/GID)을 기반으로 컨테이너 내 사용자 설정
- Docker Compose 설정 파일 자동 생성
- 호스트-컨테이너 간 볼륨 마운트 지원

## 사용 방법

### 빠른 시작

```bash
./install.sh
```

스크립트를 실행하면 기본값으로 진행하거나, 각 설정값을 변경할 수 있는 옵션이 제공됩니다.

### 기본값

- 사용자 이름: 현재 로그인한 사용자
- UID/GID: 현재 사용자의 UID/GID
- 비밀번호: 1234
- 작업 디렉토리: work/project
- 이미지 이름: my-ubuntu

### 디렉토리 구조

```
./
├── install.sh                     # 설치 스크립트
├── templates/                     # 템플릿 파일 디렉토리
│   ├── Dockerfile.template        # Docker 이미지 템플릿
│   └── docker-compose.yml.template # Docker Compose 템플릿
└── README.md                      # 이 파일
```

## Docker 이미지 정보

기본 이미지는 `namugach/ubuntu-basic:24.04-kor-deno`를 사용하며, 다음과 같은 도구가 포함되어 있습니다:

- sudo
- git
- 한국어 로케일 설정 