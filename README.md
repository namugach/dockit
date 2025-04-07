# Dockit - Docker 개발 환경 도구

Dockit은 Docker를 사용하여 개발 환경을 빠르게 설정하고 관리하기 위한 모듈식 쉘 스크립트 도구입니다.

## 기능

- Docker 개발 환경 설치 및 설정
- 컨테이너 시작/정지 관리
- 컨테이너 접속 및 상태 확인
- 현재 사용자 설정(UID/GID)을 자동으로 컨테이너에 적용
- 호스트-컨테이너 간 볼륨 마운트 지원
- 모듈식 설계로 쉽게 확장 가능

## 사용 방법

### 기본 명령어

```bash
./dockit.sh install   # 설치 및 초기 설정
./dockit.sh start     # 컨테이너 시작
./dockit.sh stop      # 컨테이너 정지
./dockit.sh connect   # 컨테이너 접속
./dockit.sh status    # 컨테이너 상태 확인
./dockit.sh help      # 도움말 표시
```

### 설치 과정

`install` 명령을 실행하면 다음과 같은 설정을 구성할 수 있습니다:

- 사용자 이름: 현재 로그인한 사용자 (자동 감지)
- UID/GID: 현재 사용자의 UID/GID (자동 감지)
- 비밀번호: 기본값 "1234"
- 작업 디렉토리: 기본값 "work/project"
- 이미지 이름: 기본값 "my-ubuntu"
- 컨테이너 이름: 기본값 "my-container"

## 디렉토리 구조

```
./
├── dockit.sh                     # 메인 스크립트
├── modules/                      # 모듈 디렉토리
│   ├── common.sh                 # 공통 함수 모듈
│   ├── install.sh                # 설치 모듈
│   ├── start.sh                  # 시작 모듈
│   ├── stop.sh                   # 정지 모듈
│   ├── connect.sh                # 접속 모듈
│   ├── status.sh                 # 상태 확인 모듈
│   └── help.sh                   # 도움말 모듈
├── templates/                    # 템플릿 파일 디렉토리
│   ├── Dockerfile.template       # Docker 이미지 템플릿
│   └── docker-compose.yml.template # Docker Compose 템플릿
└── README.md                     # 이 파일
```

## 자동 생성 파일

- `.env`: 설정 파일
- `docker-compose.yml`: Docker Compose 구성 파일
- `dockit.log`: 로그 파일

## Docker 이미지 정보

기본 이미지는 `namugach/ubuntu-basic:24.04-kor-deno`를 사용하며, 다음과 같은 도구가 포함되어 있습니다:

- sudo
- git
- 한국어 로케일 설정 