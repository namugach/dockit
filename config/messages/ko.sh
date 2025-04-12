#!/bin/bash

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
MSG_COMMON_DIRECT_EXECUTE_ERROR="이 스크립트는 직접 실행할 수 없습니다. dockit.sh를 통해 사용하세요."
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
MSG_CONTAINER_STOPPED_INFO="컨테이너가 중지되었습니다. 다시 시작하려면: ./dockit.sh start"

# connect 모듈 메시지
MSG_CONNECT_START="컨테이너 접속 모듈 실행 중..."
MSG_CONTAINER_NOT_RUNNING="컨테이너가 실행 중이지 않습니다."
MSG_START_CONTAINER_FIRST="먼저 컨테이너를 시작해야 합니다: ./dockit.sh start"
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

# start 모듈 메시지
MSG_START_START="컨테이너 시작 모듈 실행 중..."
MSG_CONTAINER_ALREADY_RUNNING="컨테이너가 이미 실행 중입니다."

# 일반 메시지
MSG_GOODBYE="Docker 환경을 종료합니다"

# 상태 메시지
MSG_CONTAINER_RUNNING="컨테이너가 실행 중입니다"
MSG_CONTAINER_NOT_EXIST="컨테이너가 존재하지 않습니다"
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
MSG_HELP_USAGE="사용법: dockit.sh [명령어]"
MSG_HELP_COMMANDS="사용 가능한 명령어:"
MSG_HELP_INIT="  init     - Docker 개발 환경 초기화"
MSG_HELP_START="  start    - 컨테이너 시작"
MSG_HELP_STOP="  stop     - 컨테이너 중지"
MSG_HELP_DOWN="  down     - 컨테이너 완전히 제거"
MSG_HELP_CONNECT="  connect  - 컨테이너에 접속"
MSG_HELP_STATUS="  status   - 컨테이너 상태 확인"
MSG_HELP_HELP="  help     - 도움말 표시"
MSG_HELP_VERSION="  version  - 버전 정보 표시"

# 도움말 추가 메시지
MSG_TITLE="Docker 개발 환경 도구"
MSG_EXAMPLES_HEADER="예제"
MSG_EXAMPLE_INIT="  ./dockit.sh init      # 초기 설정 및 환경 구성"
MSG_EXAMPLE_START="  ./dockit.sh start    # 컨테이너 시작"
MSG_EXAMPLE_STOP="  ./dockit.sh stop     # 컨테이너 정지 (상태 유지)"
MSG_EXAMPLE_DOWN="  ./dockit.sh down     # 컨테이너 완전 제거"
MSG_EXAMPLE_CONNECT="  ./dockit.sh connect  # 컨테이너 접속"

MSG_DIRECT_MODULES_HEADER="직접 모듈 실행"
MSG_DIRECT_MODULES_DESC="  각 모듈은 직접 실행할 수도 있습니다:"
MSG_EXAMPLE_MODULE_INIT="  ./src/modules/init.sh    # init 모듈 직접 실행"
MSG_EXAMPLE_MODULE_CONNECT="  ./src/modules/connect.sh    # connect 모듈 직접 실행"

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
MSG_INSTALL_START="설치 모듈 실행 중..."
MSG_INSTALL_COMPLETE="설치가 완료되었습니다!"
MSG_INSTALL_FAILED="설치 중 오류가 발생했습니다."
MSG_INSTALL_CHECK_DOCKER="1. Docker 서비스가 실행 중인지 확인하세요"
MSG_INSTALL_CHECK_PORTS="2. 포트 충돌이 없는지 확인하세요"
MSG_INSTALL_CHECK_IMAGE="3. 이미지가 존재하는지 확인하세요 (없다면 초기화 필요)"

# install 로그 메시지
MSG_INSTALL_CHECK_DEPS="의존성 확인 중..."
MSG_INSTALL_DOCKER_NOT_FOUND="Docker가 설치되어 있지 않습니다. 먼저 Docker를 설치해주세요."
MSG_INSTALL_COMPOSE_NOT_FOUND="Docker Compose가 설치되어 있지 않습니다. 먼저 Docker Compose를 설치해주세요."
MSG_INSTALL_TOOL_NOT_FOUND="%s가 설치되어 있지 않습니다. 먼저 %s를 설치해주세요."
MSG_INSTALL_DEPS_SATISFIED="모든 의존성이 충족되었습니다."
MSG_INSTALL_CHECK_EXISTING="기존 설치 확인 중..."
MSG_INSTALL_ALREADY_INSTALLED="dockit이 이미 설치되어 있습니다."
MSG_INSTALL_REINSTALL_PROMPT="재설치하시겠습니까? [y/N]: "
MSG_INSTALL_CANCELLED="설치가 취소되었습니다."
MSG_INSTALL_DIR_EXISTS="프로젝트 디렉토리가 이미 존재합니다: %s"
MSG_INSTALL_OVERWRITE_PROMPT="덮어쓰시겠습니까? [y/N]: "
MSG_INSTALL_NO_PERMISSION="쓰기 권한이 없습니다: %s"
MSG_INSTALL_TRY_SUDO="sudo로 실행하거나 디렉토리 권한을 확인해주세요."
MSG_INSTALL_ROOT_WARNING="root로 실행 중입니다. 권장되지 않습니다."
MSG_INSTALL_CONTINUE_PROMPT="계속하시겠습니까? [y/N]: "
MSG_INSTALL_CREATE_DIRS="설치 디렉토리 생성 중..."
MSG_INSTALL_PROJECT_FILES="프로젝트 파일 설치 중..."
MSG_INSTALL_COMPLETION_SCRIPTS="자동완성 스크립트 설치 중..."
MSG_INSTALL_ADD_PATH="PATH에 추가 중..."
MSG_INSTALL_SUCCESS="설치가 완료되었습니다!"
MSG_INSTALL_USE_COMMAND="이제 'dockit' 명령어를 사용할 수 있습니다."
MSG_INSTALL_TRY_HELP="시도해보세요: dockit --help"
MSG_INSTALL_FAILED="설치에 실패했습니다!"
MSG_INSTALL_STARTING="dockit 설치 시작..."
MSG_INSTALL_RESTART_SHELL="쉘을 재시작하거나 다음 명령을 실행하세요: source ~/.bashrc (또는 ~/.zshrc)" 