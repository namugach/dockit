#!/bin/bash

# 언어 메타데이터 / Language Metadata
LANG_CODE="ko"
LANG_NAME="한국어"
LANG_LOCALE="ko_KR.UTF-8"
LANG_TIMEZONE="Asia/Seoul"
LANG_DIRECTION="ltr"
LANG_VERSION="1.0"
LANG_AUTHOR="Dockit Team"

# 한국어 메시지 정의

# 공통 메시지
MSG_WELCOME="Docker 개발 환경 설정"
MSG_INPUT_DEFAULT="(엔터 키를 누르면 괄호 안의 기본값이 사용됩니다)"
MSG_CURRENT_SETTINGS="다음 기본값으로 설정됩니다:"
MSG_USERNAME="사용자 이름"
MSG_USER_UID="사용자 UID"
MSG_USER_GID="사용자 GID"
MSG_PASSWORD="비밀번호"
MSG_WORKDIR="작업 디렉토리"
MSG_IMAGE_NAME="이미지 이름"
MSG_CONTAINER_NAME="컨테이너 이름"
MSG_SELECT_OPTION="선택하세요:"
MSG_USE_DEFAULT="기본값으로 계속 진행"
MSG_MODIFY_VALUES="각 값을 수정"
MSG_CANCEL="취소"
MSG_SELECT_CHOICE="선택"
MSG_INPUT_USERNAME="사용자 이름"
MSG_INPUT_UID="사용자 UID"
MSG_INPUT_GID="사용자 GID"
MSG_INPUT_PASSWORD="사용자 비밀번호"
MSG_INPUT_WORKDIR="작업 디렉토리 이름"
MSG_INPUT_IMAGE_NAME="이미지 이름"
MSG_INPUT_CONTAINER_NAME="컨테이너 이름"
MSG_FINAL_SETTINGS="최종 설정 정보:"
MSG_INIT_CANCELLED="초기화가 취소되었습니다."
MSG_INVALID_CHOICE="잘못된 선택입니다. 초기화가 취소되었습니다."
MSG_COMMON_LOADING_CONFIG="설정 파일 로드 중: %s"
MSG_COMMON_CONFIG_NOT_FOUND="설정 파일을 찾을 수 없습니다. 기본값을 사용합니다."
MSG_COMMON_BASE_IMAGE_NOT_SET="BASE_IMAGE가 설정되지 않았습니다. 기본 이미지를 사용합니다."
MSG_COMMON_USING_BASE_IMAGE="사용할 베이스 이미지: %s"
MSG_COMMON_CONTAINER_RUNNING="컨테이너가 실행 중입니다: %s"
MSG_COMMON_CONTAINER_STOPPED="컨테이너가 중지되었습니다: %s"
MSG_COMMON_CONTAINER_NOT_FOUND="컨테이너가 존재하지 않습니다: %s"
MSG_COMMON_COMPOSE_NOT_FOUND="docker-compose.yml 파일을 찾을 수 없습니다"
MSG_COMMON_NOT_INITIALIZED="초기화가 필요합니다. init 명령을 실행하세요: \n\ndockit init"

# init 모듈 메시지
MSG_INIT_START="초기화 시작..."
MSG_CREATING_DOCKIT_DIR=".dockit 디렉토리 생성 중..."
MSG_DOCKIT_DIR_CREATED=".dockit 디렉토리가 생성되었습니다."
MSG_OLD_LOG_FOUND="이전 버전의 로그 파일 발견, 삭제 중..."
MSG_OLD_LOG_REMOVED="이전 버전의 로그 파일이 삭제되었습니다."
MSG_MOVING_ENV="기존 .env 파일을 새 위치로 이동 중..."
MSG_ENV_MOVED=".env 파일이 이동되었습니다."
MSG_MOVING_COMPOSE="기존 docker-compose.yml 파일을 새 위치로 이동 중..."
MSG_COMPOSE_MOVED="docker-compose.yml 파일이 이동되었습니다."
MSG_MOVING_LOG="기존 로그 파일을 새 위치로 이동 중..."
MSG_LOG_MOVED="로그 파일이 이동되었습니다."
MSG_CREATING_DOCKERFILE="Dockerfile 템플릿 파일 생성 중..."
MSG_DOCKERFILE_CREATED="Dockerfile 템플릿 파일이 생성되었습니다."
MSG_DOCKERFILE_FAILED="Dockerfile 템플릿 파일 생성에 실패했습니다."
MSG_BUILDING_IMAGE="Docker 이미지 빌드 중:"
MSG_MULTILANG_SETTINGS="다국어 설정 시스템 활용:"
MSG_PROCESSING_TEMPLATE="기존 방식으로 템플릿 처리 중..."
MSG_IMAGE_BUILT="Docker 이미지가 성공적으로 빌드되었습니다:"
MSG_IMAGE_BUILD_FAILED="Docker 이미지 빌드 중 오류가 발생했습니다."
MSG_CREATING_COMPOSE="Docker Compose 파일 생성 중..."
MSG_COMPOSE_CREATED="Docker Compose 파일이 생성되었습니다."
MSG_COMPOSE_FAILED="Docker Compose 파일 생성에 실패했습니다."
MSG_START_CONTAINER_NOW="컨테이너를 시작할까요?"
MSG_STARTING_CONTAINER="컨테이너 시작 중..."
MSG_CONTAINER_STARTED="컨테이너가 성공적으로 시작되었습니다!"
MSG_CONTAINER_START_FAILED="컨테이너 시작 중 오류가 발생했습니다."
MSG_CHECK_DOCKER="1. Docker 서비스가 실행 중인지 확인하세요"
MSG_CHECK_PORTS="2. 포트 충돌이 없는지 확인하세요"
MSG_CHECK_IMAGE="3. 이미지가 존재하는지 확인하세요 (없다면 초기화 필요)"
MSG_CONNECT_CONTAINER_NOW="컨테이너에 접속할까요?"
MSG_CONNECTING_CONTAINER="컨테이너에 접속 중..."
MSG_SKIPPING_CONNECT="컨테이너 접속을 건너뜁니다."
MSG_CONNECT_LATER="나중에 컨테이너에 접속하려면:"
MSG_START_LATER="나중에 컨테이너를 시작하려면:"

# down 모듈 메시지
MSG_DOWN_START="컨테이너 제거 모듈 실행 중..."
MSG_CONTAINER_STOPPED="컨테이너가 성공적으로 제거되었습니다."
MSG_CONTAINER_STOP_FAILED="컨테이너 제거 중 오류가 발생했습니다."

# stop 모듈 메시지
MSG_STOP_START="컨테이너 정지 모듈 실행 중..."
MSG_CONTAINER_NOT_FOUND="제거할 컨테이너가 없습니다."
MSG_CONTAINER_STOPPED="컨테이너가 성공적으로 중지되었습니다."
MSG_CONTAINER_STOP_FAILED="컨테이너 중지 중 오류가 발생했습니다."
MSG_CONTAINER_STOPPED_INFO="컨테이너가 중지되었습니다. 다시 시작하려면: dockit start"

# connect 모듈 메시지
MSG_CONNECT_START="컨테이너 접속 모듈 실행 중..."
MSG_CONTAINER_NOT_RUNNING="컨테이너가 실행 중이지 않습니다."
MSG_START_CONTAINER_FIRST="먼저 컨테이너를 시작해야 합니다:"
MSG_WANT_START_CONTAINER="컨테이너를 지금 시작할까요?"
MSG_START_CANCELLED="컨테이너 시작이 취소되었습니다."
MSG_CONNECTED="컨테이너에 성공적으로 접속했습니다."
MSG_CONNECT_FAILED="컨테이너 접속 중 오류가 발생했습니다."

# status 모듈 메시지
MSG_STATUS_START="상태 확인 모듈 실행 중..."
MSG_CONTAINER_STATUS="컨테이너 상태:"
MSG_CONTAINER_ID="컨테이너 ID"
MSG_CONTAINER_STATE="상태"
MSG_CONTAINER_CREATED="생성 시간"
MSG_CONTAINER_IMAGE="이미지"
MSG_CONTAINER_IP="IP 주소"
MSG_CONTAINER_PORTS="포트"
MSG_STATUS_COMPLETE="상태 확인이 완료되었습니다."
MSG_STATUS_PROJECT_CONFIG="프로젝트 Dockit 설정 정보:"
MSG_STATUS_VERSION="Dockit 버전"
MSG_STATUS_IMAGE_NAME="이미지 이름"
MSG_STATUS_CONTAINER_NAME="컨테이너 이름"
MSG_STATUS_USERNAME="사용자 이름"
MSG_STATUS_USER_UID="사용자 UID"
MSG_STATUS_USER_GID="사용자 GID"
MSG_STATUS_WORKDIR="작업 디렉토리"

# start 모듈 메시지
MSG_START_START="컨테이너 시작 모듈 실행 중..."
MSG_CONTAINER_ALREADY_RUNNING="컨테이너가 이미 실행 중입니다."

# 일반 메시지
MSG_GOODBYE="Docker 환경을 종료합니다"

# 상태 메시지
MSG_CONTAINER_RUNNING="컨테이너가 실행 중입니다"
MSG_CONTAINER_NOT_EXIST="컨테이너가 존재하지 않습니다"
MSG_CONTAINER_NOT_FOUND="해당 컨테이너를 찾을 수 없습니다"
MSG_IMAGE_EXIST="도커 이미지가 존재합니다"
MSG_IMAGE_NOT_EXIST="도커 이미지가 존재하지 않습니다"

# 명령어 관련 메시지
MSG_START_CONTAINER="컨테이너를 시작합니다"
MSG_STOP_CONTAINER="컨테이너를 중지합니다"
MSG_DOWN_CONTAINER="컨테이너를 완전히 제거합니다"
MSG_CONNECT_CONTAINER="컨테이너에 접속합니다"
MSG_CHECKING_STATUS="상태를 확인합니다"
MSG_INITIALIZING="초기화를 진행합니다"
MSG_CMD_SUCCESS="명령이 성공적으로 실행되었습니다"
MSG_CMD_FAILED="명령 실행에 실패했습니다"

# 질문 메시지
MSG_CONFIRM_STOP="실행 중인 컨테이너를 중지하시겠습니까? (y/n): "
MSG_CONFIRM_DOWN="컨테이너를 완전히 제거하시겠습니까? (y/n): "
MSG_CONFIRM_START="새 컨테이너를 시작하시겠습니까? (y/n): "
MSG_CONFIRM_INIT="초기화를 진행하시겠습니까? (y/n): "

# 도움말 메시지
MSG_HELP_USAGE="사용법: dockit [명령어]"
MSG_HELP_COMMANDS="사용 가능한 명령어:"
MSG_HELP_INIT="  init     - Docker 개발 환경 초기화"
MSG_HELP_START="  start    - 컨테이너 시작"
MSG_HELP_STOP="  stop     - 컨테이너 중지"
MSG_HELP_DOWN="  down     - 컨테이너 완전히 제거"
MSG_HELP_CONNECT="  connect  - 컨테이너에 접속"
MSG_HELP_STATUS="  status   - 컨테이너 상태 확인"
MSG_HELP_MIGRATE="  migrate  - 새 버전으로 업그레이드"
MSG_HELP_HELP="  help     - 도움말 표시"
MSG_HELP_VERSION="  version  - 버전 정보 표시"

# 도움말 추가 메시지
MSG_TITLE="Docker 개발 환경 도구"
MSG_EXAMPLES_HEADER="예제"
MSG_EXAMPLE_INIT="  dockit init      # 초기 설정 및 환경 구성"
MSG_EXAMPLE_START="  dockit start    # 컨테이너 시작"
MSG_EXAMPLE_STOP="  dockit stop     # 컨테이너 정지 (상태 유지)"
MSG_EXAMPLE_DOWN="  dockit down     # 컨테이너 완전 제거"
MSG_EXAMPLE_CONNECT="  dockit connect  # 컨테이너 접속"

MSG_CONFIG_FILES_HEADER="설정 파일"
MSG_CONFIG_FILE_ENV="  .dockit/.env                # 사용자 설정이 저장되는 파일"
MSG_CONFIG_FILE_COMPOSE="  .dockit/docker-compose.yml  # Docker Compose 설정 파일"
MSG_CONFIG_FILE_LOG="  .dockit/dockit.log          # 로그 파일"
MSG_CONFIG_FILE_SETTINGS="  config/settings.env         # 언어 및 기본 설정 파일"

# 시스템 메시지
MSG_SYSTEM_DEBUG_INITIAL_LANG="===== 초기 언어 설정 상태 ====="
MSG_SYSTEM_DEBUG_LANG_VAR="환경 변수 LANGUAGE: %s"
MSG_SYSTEM_DEBUG_SYS_LANG="시스템 로케일 LANG: %s"
MSG_SYSTEM_DEBUG_CONFIG_LANG="설정 파일 언어: %s"
MSG_SYSTEM_DEBUG_NO_CONFIG="설정 파일 언어: 파일 없음"
MSG_SYSTEM_DEBUG_END="================================="
MSG_SYSTEM_LANG_FROM_ENV="환경 변수 LANGUAGE"
MSG_SYSTEM_LANG_FROM_SYS="시스템 로케일 LANG"
MSG_SYSTEM_LANG_FROM_CONFIG="설정 파일"
MSG_SYSTEM_DEBUG_AFTER_LOAD="===== 설정 파일 로드 후 상태 ====="
MSG_SYSTEM_DEBUG_LOADED_LANG="로드된 LANGUAGE 값: %s"
MSG_SYSTEM_DEBUG_CONFIG_LANG_VALUE="설정 파일의 LANGUAGE 값: %s"
MSG_SYSTEM_DEBUG_LOAD_END="==================================="
MSG_SYSTEM_DEBUG_LOAD_FROM_CONFIG="설정 파일에서 언어 설정 로드: %s"
MSG_SYSTEM_NO_CONFIG_FILE="설정 파일이 없습니다: %s"
MSG_SYSTEM_FINAL_LANG="최종 언어 설정: %s (출처: %s)"
MSG_SYSTEM_DEBUG_INTEGRATED_MSG="통합 메시지 로딩 시스템 사용: %s"
MSG_SYSTEM_DEBUG_LEGACY_MSG="기존 메시지 로딩 방식 사용"
MSG_SYSTEM_DEBUG_LOAD_MSG_FILE="메시지 파일 로드: %s"
MSG_SYSTEM_LANG_FILE_NOT_FOUND="언어 파일을 찾을 수 없습니다: %s. 영어로 대체합니다."
MSG_SYSTEM_MSG_NOT_FOUND="메시지를 찾을 수 없음: %s"
MSG_SYSTEM_DEBUG_SYS_INFO="===== 시스템 설정 정보 ====="
MSG_SYSTEM_DEBUG_LANG="언어: %s"
MSG_SYSTEM_DEBUG_BASE_IMG="베이스 이미지: %s"
MSG_SYSTEM_DEBUG_LOCALE="로케일: %s"
MSG_SYSTEM_DEBUG_TIMEZONE="시간대: %s"
MSG_SYSTEM_DEBUG_WORKDIR="작업 디렉토리: %s"
MSG_SYSTEM_DEBUG_TEMPLATE_DIR="템플릿 디렉토리: %s"
MSG_SYSTEM_DEBUG_DOCKERFILE="Dockerfile 템플릿: %s"
MSG_SYSTEM_DEBUG_INFO_END="=========================="
MSG_SYSTEM_TEMPLATE_NOT_FOUND="템플릿 파일을 찾을 수 없습니다: %s"
MSG_SYSTEM_TEMPLATE_PROCESSING="템플릿 처리 중: %s -> %s"
MSG_SYSTEM_FILE_CREATED="파일이 생성되었습니다: %s"
MSG_SYSTEM_FILE_CREATE_FAILED="파일 생성에 실패했습니다: %s"

# 디버그 테스트 메시지
MSG_SYSTEM_DEBUG_MSG_TEST="===== 메시지 출력 테스트 ====="
MSG_SYSTEM_DEBUG_WELCOME="환영 메시지: %s"
MSG_SYSTEM_DEBUG_HELP="도움말 사용법: %s"
MSG_SYSTEM_DEBUG_CONTAINER="컨테이너 상태 메시지: %s"
MSG_SYSTEM_DEBUG_CONFIRM="확인 메시지: %s"
MSG_SYSTEM_DEBUG_TEMPLATE_TEST="===== 템플릿 처리 테스트 ====="
MSG_SYSTEM_DEBUG_TEMPLATE_PATH="템플릿 경로: %s"
MSG_SYSTEM_DEBUG_TEMPLATE_PROCESS="템플릿 처리 함수 테스트..."
MSG_SYSTEM_DEBUG_TEMPLATE_SUCCESS="템플릿 처리 성공!"
MSG_SYSTEM_DEBUG_TEMPLATE_FAILED="템플릿 처리 실패!"
MSG_SYSTEM_DEBUG_TEMPLATE_PREVIEW="처리된 Dockerfile 첫 10줄:"
MSG_SYSTEM_DEBUG_COMPLETE="디버그 테스트 완료!"
MSG_SYSTEM_DEBUG_PASSWORD="기본 비밀번호: %s"

# install 모듈 메시지
MSG_INSTALL_START="dockit 설치를 시작합니다..."
MSG_INSTALL_CHECKING_DEPENDENCIES="의존성 확인 중..."
MSG_INSTALL_DOCKER_MISSING="Docker가 설치되어 있지 않습니다. 먼저 Docker를 설치해주세요."
MSG_INSTALL_COMPOSE_MISSING="Docker Compose가 설치되어 있지 않습니다. 먼저 Docker Compose를 설치해주세요."
MSG_INSTALL_TOOL_MISSING="%s이(가) 설치되어 있지 않습니다. 먼저 %s을(를) 설치해주세요."
MSG_INSTALL_DEPENDENCIES_OK="모든 의존성이 충족되었습니다."
MSG_INSTALL_CHECKING_EXISTING="기존 설치 확인 중..."
MSG_INSTALL_ALREADY_INSTALLED="dockit이 이미 설치되어 있습니다."
MSG_INSTALL_REINSTALL="다시 설치하시겠습니까? [y/N]"
MSG_INSTALL_CANCELLED="설치가 취소되었습니다."
MSG_INSTALL_DIR_EXISTS="프로젝트 디렉토리가 이미 존재합니다: %s"
MSG_INSTALL_OVERWRITE="덮어쓰시겠습니까? [y/N]"
MSG_INSTALL_CHECKING_PERMISSIONS="권한 확인 중..."
MSG_INSTALL_NO_PERMISSION="쓰기 권한이 없습니다: %s"
MSG_INSTALL_USE_SUDO="sudo로 실행하거나 디렉토리 권한을 확인해주세요."
MSG_INSTALL_CREATING_DIRS="디렉토리 생성 중..."
MSG_INSTALL_INSTALLING_FILES="프로젝트 파일 설치 중..."
MSG_INSTALL_PATH="설치 경로: %s"
MSG_INSTALL_INSTALLING_COMPLETION="자동완성 스크립트 설치 중..."
MSG_INSTALL_ADDING_PATH="PATH에 설치 디렉토리를 추가합니다."
MSG_INSTALL_COMPLETED="설치가 완료되었습니다!"
MSG_INSTALL_CMD_AVAILABLE="dockit 명령어를 사용할 수 있습니다."
MSG_INSTALL_HELP_TIP="도움말을 보려면 'dockit help'를 실행하세요."
MSG_INSTALL_FAILED="설치에 실패했습니다."
MSG_INSTALL_SHELL_RESTART="새로운 셸을 시작하거나 'source ~/.bashrc' 또는 'source ~/.zshrc'를 실행하세요."
MSG_INSTALL_CHECK_DOCKER="Docker가 실행 중인지 확인하세요."
MSG_INSTALL_CHECK_PORTS="포트 80, 443이 사용 가능한지 확인하세요."
MSG_INSTALL_CHECK_IMAGE="이미지가 존재하는지 확인하세요."
MSG_INSTALL_COMPLETE="설치가 완료되었습니다."
MSG_INSTALL_FAILED="설치에 실패했습니다."

# 자동완성 관련 메시지
MSG_INSTALL_GLOBAL_COMPLETION="시스템 전역 자동완성 설치 완료"
MSG_INSTALL_COMPLETION_HELP="* 자동완성을 사용하려면 탭(TAB) 키를 누르세요"
MSG_INSTALL_COMPLETION_ENABLE="명령어 완성 기능을 활성화하려면 다음 명령어로 쉘을 다시 로드하세요:"
MSG_INSTALL_BASH_RELOAD="Bash 쉘의 경우:"
MSG_INSTALL_ZSH_RELOAD="Zsh 쉘의 경우:"
MSG_INSTALL_ZSH_COMPLETION_ADDED="Zsh 완성 설정이 추가되었습니다"
MSG_INSTALL_ZSH_COMPLETION_ACTIVATE="자동완성 기능 활성화"
MSG_INSTALL_ZSH_COMPLETION_ADD_PATH="dockit 자동완성 경로 추가"
MSG_INSTALL_ZSH_COMPLETION_LOAD="dockit 자동완성 직접 로드"

# init.sh 추가 메시지
MSG_INIT_GETTING_USER_INPUT="사용자 입력 받는 중..."
MSG_CONFIG_SAVED="설정이 저장되었습니다."
MSG_INIT_VERSION_HEADER="Dockit v%s"
MSG_INIT_VERSION_SEPARATOR="====================="
MSG_INIT_COMPLETE="초기화가 완료되었습니다."
MSG_TEMPLATE_GENERATED="생성됨: %s"

# 제거 모듈 메시지
MSG_UNINSTALL_START="dockit 제거를 시작합니다..."
MSG_UNINSTALL_CONFIRM="dockit을 제거하시겠습니까? 모든 프로그램 파일과 설정이 삭제됩니다."
MSG_UNINSTALL_CANCELLED="제거가 취소되었습니다."
MSG_UNINSTALL_REMOVING_SCRIPT="dockit 스크립트 제거 중..."
MSG_UNINSTALL_SCRIPT_REMOVED="dockit 스크립트가 성공적으로 제거되었습니다."
MSG_UNINSTALL_SCRIPT_NOT_FOUND="dockit 스크립트를 찾을 수 없습니다:"
MSG_UNINSTALL_REMOVING_FILES="프로젝트 파일 제거 중..."
MSG_UNINSTALL_FILES_REMOVED="프로젝트 파일이 성공적으로 제거되었습니다."
MSG_UNINSTALL_DIR_NOT_FOUND="프로젝트 디렉토리를 찾을 수 없습니다:"
MSG_UNINSTALL_REMOVE_FAILED="프로젝트 디렉토리를 완전히 제거하지 못했습니다:"
MSG_UNINSTALL_REMOVING_COMPLETION="자동완성 스크립트 제거 중..."
MSG_UNINSTALL_BASH_REMOVED="Bash 자동완성 스크립트가 제거되었습니다."
MSG_UNINSTALL_ZSH_REMOVED="Zsh 자동완성 스크립트가 제거되었습니다."
MSG_UNINSTALL_REMOVING_COMPLETION_CONFIG="쉘 자동완성 설정 제거 중..."
MSG_UNINSTALL_REMOVED_BASH_COMPLETION="Bash 자동완성 설정이 제거되었습니다."
MSG_UNINSTALL_REMOVED_ZSH_COMPLETION="Zsh 자동완성 설정이 제거되었습니다."
MSG_UNINSTALL_REMOVED_GLOBAL_COMPLETION="전역 자동완성 스크립트가 제거되었습니다."
MSG_UNINSTALL_REMOVING_CONFIG="설정 디렉토리 제거 중..."
MSG_UNINSTALL_CONFIG_REMOVED="설정 디렉토리가 성공적으로 제거되었습니다."
MSG_UNINSTALL_REMOVING_PATH="PATH에서 dockit 제거 중..."
MSG_UNINSTALL_REMOVED_BASHRC=".bashrc에서 제거되었습니다"
MSG_UNINSTALL_REMOVED_ZSHRC=".zshrc에서 제거되었습니다"
MSG_UNINSTALL_CLEANING_DIRS="설치 디렉토리 정리 중..."
MSG_UNINSTALL_REMOVED_EMPTY_DIR="빈 디렉토리 제거됨:"
MSG_UNINSTALL_SUCCESSFUL="제거가 성공적으로 완료되었습니다!"
MSG_UNINSTALL_INCOMPLETE="제거가 완전하지 않을 수 있습니다. 수동으로 확인해주세요."
MSG_UNINSTALL_RESTART_SHELL="셸을 다시 시작하거나 'source ~/.bashrc' 또는 'source ~/.zshrc'를 실행해주세요."

# 자동완성 메시지
MSG_COMPLETION_INIT="dockit 프로젝트 초기화"
MSG_COMPLETION_START="컨테이너 시작"
MSG_COMPLETION_STOP="컨테이너 중지"
MSG_COMPLETION_DOWN="컨테이너 완전히 제거"
MSG_COMPLETION_STATUS="컨테이너 상태 확인"
MSG_COMPLETION_CONNECT="컨테이너에 접속"
MSG_COMPLETION_HELP="도움말 표시"
MSG_COMPLETION_VERSION="버전 정보 표시"
MSG_COMPLETION_MIGRATE="프로젝트를 새 버전으로 마이그레이션"

# 공통 모듈 테스트 메시지
MSG_COMMON_TESTING_FUNCTION="generate_container_name 함수 테스트 중..."
MSG_COMMON_CURRENT_DIR="현재 디렉토리"
MSG_COMMON_GENERATED_NAME="생성된 이름"
MSG_COMMON_TESTING_EXPLICIT="명시적 경로로 테스트"

# language setup messages
MSG_INSTALL_LANGUAGE_SETUP="언어 설정 중..."
MSG_INSTALL_LANGUAGE_AVAILABLE="사용 가능한 언어:"
MSG_INSTALL_LANGUAGE_DEFAULT="기본값"
MSG_INSTALL_LANGUAGE_SELECT="언어를 선택하세요"
MSG_INSTALL_LANGUAGE_SELECTED="선택한 언어: %s (%s)"
MSG_INSTALL_LANGUAGE_INVALID="잘못된 선택입니다. 기본값을 사용합니다: %s (%s)"

# 버전 유효성 검사 메시지
MSG_VERSION_CHECK_HEADER="버전 호환성 검사 중..."
MSG_VERSION_PROJECT_HIGHER="경고: 이 프로젝트는 더 높은 버전의 dockit으로 생성되었습니다 (프로젝트: %s, 현재: %s)."
MSG_VERSION_DOWNLOAD_LATEST="최신 버전을 다운로드하세요: https://github.com/namugach/dockit/archive/refs/heads/main.zip"
MSG_VERSION_PROJECT_LOWER="경고: 이 프로젝트는 이전 버전의 dockit으로 생성되었습니다 (프로젝트: %s, 현재: %s)."
MSG_VERSION_POSSIBLE_INCOMPATIBILITY="버전 차이로 인한 호환성 문제가 발생할 수 있습니다."
MSG_VERSION_MIN_REQUIRED="이 기능은 최소 %s 버전 이상이 필요합니다 (현재: %s)."
MSG_VERSION_FEATURE_UNAVAILABLE="이 기능은 현재 버전에서 사용할 수 없습니다."
MSG_VERSION_COMPARE_ERROR="버전 비교 중 오류가 발생했습니다."

# 마이그레이션 모듈 메시지
# Migration module messages

# 마이그레이션 기본 과정 메시지
# Basic migration process messages
MSG_MIGRATE_START="마이그레이션 모듈을 시작합니다."
MSG_MIGRATE_PROCESSING="마이그레이션을 처리하는 중..."
MSG_MIGRATE_SUCCESS="마이그레이션이 성공적으로 완료되었습니다. 현재 버전: %s"
MSG_MIGRATE_FAILED="마이그레이션에 실패했습니다: %s"
MSG_MIGRATE_PROCESS_STARTED="%s에서 %s로 마이그레이션 프로세스를 시작합니다."
MSG_MIGRATE_PROCESS_COMPLETED="마이그레이션 프로세스가 성공적으로 완료되었습니다."

# 버전 관련 메시지
# Version related messages
MSG_MIGRATE_CHECKING="버전 정보를 확인하는 중..."
MSG_MIGRATE_CURRENT_VER="현재 버전: %s"
MSG_MIGRATE_TARGET_VER="대상 버전: %s"
MSG_MIGRATE_UP_TO_DATE="이미 최신 버전입니다. 마이그레이션이 필요하지 않습니다."
MSG_MIGRATE_DOWNGRADE_NOT_SUPPORTED="현재 버전이 대상 버전보다 높습니다. 다운그레이드는 지원되지 않습니다."
MSG_MIGRATE_NO_CURRENT_VERSION="현재 버전을 확인할 수 없습니다. 마이그레이션이 중단되었습니다."
MSG_MIGRATE_NO_VERSION_FILE="%s에서 버전 파일을 찾을 수 없습니다."
MSG_MIGRATE_EMPTY_VERSION="대상 버전이 비어 있습니다."

# 사용자 상호작용 메시지
# User interaction messages
MSG_MIGRATE_CONFIRM="새 버전으로 마이그레이션을 진행하시겠습니까?"
MSG_MIGRATE_CANCELLED="사용자에 의해 마이그레이션이 취소되었습니다."

# 백업 관련 메시지
# Backup related messages
MSG_MIGRATE_BACKING_UP="기존 설정을 백업하는 중..."
MSG_MIGRATE_BACKUP_CREATED="백업이 생성되었습니다: %s"
MSG_MIGRATE_BACKUP_FAILED="백업 생성에 실패했습니다."
MSG_MIGRATE_NO_CONFIG="백업할 기존 설정이 없습니다."
MSG_MIGRATE_SAVED_CONFIG="이전 설정이 %s에 저장되었습니다."
MSG_MIGRATE_NO_OLD_CONFIG="이전 설정을 찾을 수 없습니다."

# 롤백 관련 메시지
# Rollback related messages
MSG_MIGRATE_ROLLBACK="변경 사항을 롤백하는 중..."
MSG_MIGRATE_ROLLBACK_SUCCESS="롤백이 성공적으로 완료되었습니다."
MSG_MIGRATE_ROLLBACK_FAILED="롤백에 실패했습니다: %s"
MSG_MIGRATE_NO_BACKUP="롤백을 위한 백업을 찾을 수 없습니다."

# 설정 관련 메시지
# Settings related messages
MSG_MIGRATE_UPDATING_ENV="환경 설정을 업데이트하는 중..."
MSG_MIGRATE_SETTINGS_FAILED="설정 마이그레이션에 실패했습니다."
MSG_MIGRATE_NO_ENV="이전 .env 파일을 찾을 수 없습니다."
MSG_MIGRATE_SAVE_FAILED="이전 설정 저장에 실패했습니다."

# 초기화 관련 메시지
# Initialization related messages
MSG_MIGRATE_INIT_FAILED="새 환경 초기화에 실패했습니다."
MSG_MIGRATE_INIT_NOT_FOUND="Init 모듈을 찾을 수 없습니다."
MSG_MIGRATE_BACKUP_INIT_FAILED="백업 및 초기화에 실패했습니다."
MSG_MIGRATE_DIR_STRUCTURE_FAILED="마이그레이션 디렉토리 구조 생성에 실패했습니다."

# 마이그레이션 로직 관련 메시지
# Migration logic related messages
MSG_MIGRATE_CHECKING_LOGIC="%s에서 %s로의 버전별 마이그레이션 로직을 확인하는 중입니다."
MSG_MIGRATE_PATH_FOUND="%s에서 %s로의 직접 마이그레이션 경로를 찾았습니다."
MSG_MIGRATE_NO_DIRECT_PATH="직접 마이그레이션 경로를 찾을 수 없어 증분 마이그레이션을 확인합니다."
MSG_MIGRATE_LOGIC_COMPLETED="버전별 마이그레이션이 완료되었습니다."
MSG_MIGRATE_MIGRATING="%s에서 %s로 마이그레이션하는 중..."
MSG_MIGRATE_PATH_MISSING="%s에서 %s로의 마이그레이션 경로가 없습니다."
MSG_MIGRATE_PARTIALLY_REACHED="마이그레이션이 %s까지만 도달하고 %s에는 도달하지 못했습니다."
MSG_MIGRATE_LOGIC_FAILED="버전별 마이그레이션 로직 실행에 실패했습니다."

# 마이그레이션 단계 관련 메시지
# Migration steps related messages
MSG_MIGRATE_EXECUTING_STEPS="%s에서 %s로 마이그레이션 단계를 실행 중입니다."
MSG_MIGRATE_STEPS_COMPLETED="모든 마이그레이션 단계가 성공적으로 완료되었습니다."
MSG_MIGRATE_STEPS_FAILED="마이그레이션 단계 실행에 실패했습니다."

# 스크립트 관련 메시지
# Script related messages
MSG_MIGRATE_SCRIPT_FOUND="마이그레이션 스크립트를 찾았습니다: %s"
MSG_MIGRATE_SCRIPT_SUCCESS="마이그레이션 스크립트가 성공적으로 실행되었습니다."
MSG_MIGRATE_SCRIPT_FAILED="마이그레이션 스크립트 실행에 실패했습니다."

# 버전별 실패 메시지
# Version-specific failure messages
MSG_MIGRATE_MAJOR_FAILED="메이저 버전 마이그레이션에 실패했습니다."
MSG_MIGRATE_MINOR_FAILED="마이너 버전 마이그레이션에 실패했습니다."
MSG_MIGRATE_PATCH_FAILED="패치 버전 마이그레이션에 실패했습니다." 