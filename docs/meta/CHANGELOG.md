# Changelog

모든 주요 변경 사항이 이 파일에 기록됩니다.

## [1.2.0] - 2025-01-29

### 추가됨
- **UID 충돌 감지 및 조건부 사용자 처리**
  - Dockerfile 템플릿에서 기존 사용자(예: ubuntu) 존재 시 자동 감지
  - 호스트 UID와 동일한 컨테이너 사용자에게 자동 비밀번호 설정
  - `getent passwd ${USER_UID}` 를 통한 UID 기반 사용자 확인
  - `usermod + openssl passwd + passwd -u` 조합으로 안전한 비밀번호 설정
- **build 명령어 --no-cache 옵션**
  - `dockit build --no-cache` 옵션 추가
  - Docker 이미지 캐싱 문제 해결
  - 강제 리빌드 지원
- **사용자 Dockerfile 커스터마이징 지원**
  - `.dockit_project/Dockerfile` 직접 사용으로 변경
  - 사용자가 생성된 Dockerfile을 수정 가능
  - 수정 사항이 빌드에 즉시 반영

### 개선됨
- **build 모듈 아키텍처 개선**
  - 템플릿에서 임시 파일 생성 방식 제거
  - init에서 생성한 `.dockit_project/Dockerfile` 직접 활용
  - 더 직관적이고 예측 가능한 빌드 프로세스
- **베이스 이미지 호환성 향상**
  - 다양한 베이스 이미지의 기존 사용자와 호환
  - UID 충돌 시나리오에 대한 자동 처리
  - 더 안정적인 사용자 권한 관리

### 수정됨
- **UID 충돌로 인한 비밀번호 설정 실패 문제 해결**
  - 호스트 사용자명(예: hgs)에 비밀번호 설정 시도 시 실패하던 문제
  - 실제 컨테이너 사용자(예: ubuntu)에게 비밀번호 설정되도록 수정
  - sudo 권한 정상 동작 확인
- **Docker 캐싱으로 인한 Dockerfile 수정사항 미반영 문제 해결**
  - --no-cache 옵션으로 강제 리빌드 지원
  - 템플릿 수정사항이 확실히 반영되도록 개선

## [1.1.0] - 2025-01-27

### 추가됨
- 새로운 명령어들
  - `up`: 컨테이너를 백그라운드에서 시작 (번호, "this", "all" 옵션 지원)
  - `run`: 상호작용 없이 자동으로 초기화, 빌드, 시작을 수행
  - `join`: 초기화, 빌드, 시작, 접속을 한 번에 수행
  - `list`: dockit으로 생성된 모든 컨테이너 목록 조회
  - `ps`: 컨테이너 프로세스 상태 확인
  - `registry`: 컨테이너 레지스트리 관리
  - `migrate`: 새 버전으로 업그레이드
  - `build`: 개발 환경용 Docker 이미지 빌드
- 자동완성 시스템 구현
  - bash 자동완성 지원 (`src/completion/bash.sh`)
  - zsh 자동완성 지원 (`src/completion/zsh.sh`)
  - 공통 자동완성 로직 (`src/completion/completion-common.sh`)
- 유틸리티 시스템 확장
  - 로깅 시스템 (`src/utils/log.sh`)
  - 비동기 작업 처리 (`src/utils/async_tasks.sh`)
  - 시스템 유틸리티 (`src/utils/system.sh`)
  - 파일 처리 유틸리티 (`src/utils/file.sh`)
  - 범용 유틸리티 (`src/utils/utils.sh`)
- 개발 및 테스트 도구
  - 모듈 테스트 도구 (`src/dev/module_test.sh`)
  - 상태 테스트 도구 (`src/dev/status_test.sh`)
  - 설정 테스트 도구 (`src/dev/config_test.sh`)
  - 마이그레이션 테스트 도구 (`src/dev/migrate_test.sh`)
  - 디버깅 도구 (`src/dev/debug.sh`)
- 컨테이너 베이스 모듈 (`src/modules/container_base.sh`)

### 개선됨
- 모듈식 아키텍처 강화로 코드 재사용성 향상
- 명령어 옵션 시스템 확장 (번호, "this", "all" 옵션)
- 오류 처리 및 로깅 시스템 개선
- 프로젝트 구조 최적화

### 수정됨
- 초기화 중단 시 `.dockit_project` 디렉토리 잔존 문제 해결
- 로그 권한 관련 문제 수정
- 레지스트리 중복 등록 문제 해결

## [1.0.0] - 2023-04-13

### 추가됨
- 다국어 메시지 시스템 구현 (한국어/영어 지원)
- Docker 개발 환경 초기화 및 관리 기능
- 컨테이너 시작, 정지, 제거 명령어
- 컨테이너 접속 및 상태 확인 기능
- 사용자 설정에 맞는 Docker 이미지 자동 빌드 기능
- 시스템 전역 설치 및 제거 스크립트
- 완전한 문서화 (README 및 상세 메뉴얼)

### 변경됨
- 프로젝트 구조 개선 및 모듈화
- 설정 파일들을 `.dockit_project` 디렉토리에 모아서 관리
- 오류 처리 및 로깅 시스템 향상

### 수정됨
- 초기화 중단 시 `.dockit_project` 디렉토리 잔존 문제 해결
- 명령어 실행 전 초기화 상태 확인 로직 수정
- 다국어 메시지 로드 관련 오류 수정 