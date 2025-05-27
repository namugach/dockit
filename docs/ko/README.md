<p align="center">
  <img src="../../docs/logo.png" alt="Dockit Logo" width="400">
</p>

# Dockit - Docker 개발 환경 도구

[English](../../docs/en/README.md) | [한국어](../../docs/ko/README.md)

Dockit은 Docker를 사용하여 개발 환경을 빠르게 설정하고 관리하기 위한 모듈식 쉘 스크립트 도구입니다.

## 빠른 시작

```bash
# 저장소 복제
git clone https://github.com/namugach/dockit.git
cd dockit

# Dockit을 시스템에 설치
./bin/install.sh

# 새 개발 환경 초기화
dockit init
```

이 명령어는 Dockit을 시스템에 설치하고 `dockit` 명령을 경로에 추가합니다. 설치 후에는 어떤 디렉토리에서든 Dockit을 사용할 수 있습니다.

## 제거하기

Dockit을 시스템에서 제거하려면:

```bash
./bin/uninstall.sh
```

## 문서

- [자세한 메뉴얼](./MANUAL.md) - Dockit의 모든 기능에 대한 상세 설명

## 주요 기능

- Docker 개발 환경 설치 및 구성
- 컨테이너 시작/정지/제거 관리
- 컨테이너 접속 및 상태 확인
- 현재 사용자 설정(UID/GID)을 컨테이너에 자동 적용
- 호스트-컨테이너 볼륨 마운트 지원
- 쉬운 확장을 위한 모듈식 설계
- 깔끔한 프로젝트 구조
- 다국어 지원 (영어, 한국어)

## 명령어

다음은 Dockit에서 사용할 수 있는 주요 명령어입니다:

- `init`: Docker 개발 환경 초기화
- `start`: 컨테이너 시작 (자동 생성 옵션 포함, 옵션: number, "this", "all")
- `build`: Docker 개발 환경 이미지 빌드
- `up`: 컨테이너 백그라운드에서 시작 (옵션: number, "this", "all")
- `stop`: 컨테이너 정지 (옵션: number, "this", "all")
- `down`: 컨테이너 완전 제거 (옵션: number, "this", "all")
- `connect`: 컨테이너에 접속 (자동 생성 및 자동 시작 옵션 포함)
- `status`: 컨테이너 상태 확인
- `setup`: 초기화, 빌드, 시작, 접속을 한번에 실행
- `run`: 초기화, 빌드, 시작을 자동으로 실행
- `join`: 초기화, 빌드, 시작, 접속을 자동으로 한 번에 실행
- `list`: dockit으로 생성된 모든 컨테이너 목록 표시
- `migrate`: 새 버전으로 업그레이드
- `help`: 도움말 표시

## 프로젝트 구조

```
dockit/
├── bin/             # 실행 스크립트
├── src/             # 소스 코드
│   ├── modules/     # 기능별 모듈
│   └── templates/   # Dockerfile 및 docker-compose.yml 템플릿
├── config/          # 설정 파일
│   └── messages/    # 다국어 메시지 파일
└── docs/            # 문서 파일
```

## 라이센스

MIT License 