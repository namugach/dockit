#!/bin/bash

# 한국어 메시지 파일

# 일반 메시지
MSG_WELCOME="Docker 개발 환경 설정"
MSG_GOODBYE="Docker 환경을 종료합니다"

# 상태 메시지
MSG_CONTAINER_RUNNING="컨테이너가 실행 중입니다"
MSG_CONTAINER_STOPPED="컨테이너가 정지되었습니다"
MSG_CONTAINER_NOT_EXIST="컨테이너가 존재하지 않습니다"
MSG_IMAGE_EXIST="도커 이미지가 존재합니다"
MSG_IMAGE_NOT_EXIST="도커 이미지가 존재하지 않습니다"

# 명령어 관련 메시지
MSG_START_CONTAINER="컨테이너를 시작합니다"
MSG_STOP_CONTAINER="컨테이너를 중지합니다"
MSG_DOWN_CONTAINER="컨테이너를 완전히 제거합니다"
MSG_CONNECT_CONTAINER="컨테이너에 접속합니다"
MSG_CHECKING_STATUS="상태를 확인합니다"
MSG_INSTALLING="설치를 진행합니다"
MSG_CMD_SUCCESS="명령이 성공적으로 실행되었습니다"
MSG_CMD_FAILED="명령 실행에 실패했습니다"

# 질문 메시지
MSG_CONFIRM_STOP="실행 중인 컨테이너를 중지하시겠습니까? (y/n): "
MSG_CONFIRM_DOWN="컨테이너를 완전히 제거하시겠습니까? (y/n): "
MSG_CONFIRM_START="새 컨테이너를 시작하시겠습니까? (y/n): "
MSG_CONFIRM_INSTALL="설치를 진행하시겠습니까? (y/n): "

# 도움말 메시지
MSG_HELP_USAGE="사용법: dockit.sh [명령어]"
MSG_HELP_COMMANDS="사용 가능한 명령어:"
MSG_HELP_INSTALL="  install  - Docker 개발 환경 설치"
MSG_HELP_START="  start    - 컨테이너 시작"
MSG_HELP_STOP="  stop     - 컨테이너 중지"
MSG_HELP_DOWN="  down     - 컨테이너 완전히 제거"
MSG_HELP_CONNECT="  connect  - 컨테이너에 접속"
MSG_HELP_STATUS="  status   - 컨테이너 상태 확인"
MSG_HELP_HELP="  help     - 도움말 표시"

# 도움말 추가 메시지
MSG_TITLE="Docker 개발 환경 도구"
MSG_EXAMPLES_HEADER="예제"
MSG_EXAMPLE_INSTALL="  ./dockit.sh install    # 초기 설치 및 설정"
MSG_EXAMPLE_START="  ./dockit.sh start      # 컨테이너 시작"
MSG_EXAMPLE_STOP="  ./dockit.sh stop       # 컨테이너 정지 (상태 유지)"
MSG_EXAMPLE_DOWN="  ./dockit.sh down       # 컨테이너 완전 제거"
MSG_EXAMPLE_CONNECT="  ./dockit.sh connect    # 컨테이너 접속"

MSG_DIRECT_MODULES_HEADER="직접 모듈 실행"
MSG_DIRECT_MODULES_DESC="  각 모듈은 직접 실행할 수도 있습니다:"
MSG_EXAMPLE_MODULE_INSTALL="  ./src/modules/install.sh    # install 모듈 직접 실행"
MSG_EXAMPLE_MODULE_CONNECT="  ./src/modules/connect.sh    # connect 모듈 직접 실행"

MSG_CONFIG_FILES_HEADER="설정 파일"
MSG_CONFIG_FILE_ENV="  .dockit/.env                # 사용자 설정이 저장되는 파일"
MSG_CONFIG_FILE_COMPOSE="  .dockit/docker-compose.yml  # Docker Compose 설정 파일"
MSG_CONFIG_FILE_LOG="  .dockit/dockit.log          # 로그 파일"
MSG_CONFIG_FILE_SETTINGS="  config/settings.env         # 언어 및 기본 설정 파일" 