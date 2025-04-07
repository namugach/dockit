#!/bin/bash

# help 모듈 - 도움말 표시

# 공통 모듈 로드
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
source "$SCRIPT_DIR/common.sh"

# 설정 시스템 로드 (존재하는 경우)
if [ -f "$DOCKIT_ROOT/config/system.sh" ]; then
    source "$DOCKIT_ROOT/config/system.sh"
fi

# 다국어 도움말 출력 함수
show_help() {
    # config/system.sh가 로드되었고 print_message 함수가 사용 가능한지 확인
    if type print_message &>/dev/null; then
        # 다국어 메시지 시스템 활용
        cat << EOF

===== $(print_message MSG_TITLE) =====
$(print_message MSG_WELCOME)

$(print_message MSG_HELP_USAGE)

$(print_message MSG_HELP_COMMANDS)
$(print_message MSG_HELP_INSTALL)
$(print_message MSG_HELP_START)
$(print_message MSG_HELP_STOP)
$(print_message MSG_HELP_DOWN)
$(print_message MSG_HELP_CONNECT)
$(print_message MSG_HELP_STATUS)
$(print_message MSG_HELP_HELP)

$(print_message MSG_EXAMPLES_HEADER):
$(print_message MSG_EXAMPLE_INSTALL)
$(print_message MSG_EXAMPLE_START)
$(print_message MSG_EXAMPLE_STOP)
$(print_message MSG_EXAMPLE_DOWN)
$(print_message MSG_EXAMPLE_CONNECT)

$(print_message MSG_DIRECT_MODULES_HEADER):
$(print_message MSG_DIRECT_MODULES_DESC)
$(print_message MSG_EXAMPLE_MODULE_INSTALL)
$(print_message MSG_EXAMPLE_MODULE_CONNECT)

$(print_message MSG_CONFIG_FILES_HEADER):
$(print_message MSG_CONFIG_FILE_ENV)
$(print_message MSG_CONFIG_FILE_COMPOSE)
$(print_message MSG_CONFIG_FILE_LOG)
$(print_message MSG_CONFIG_FILE_SETTINGS)

=================================
EOF
    else
        # 기존 방식의 도움말 (변경 없음)
        cat << EOF

===== Dockit - Docker 개발 환경 도구 =====
간편한 Docker 개발 환경 관리 도구

사용법:
  ./dockit.sh <명령> [옵션...]

사용 가능한 명령:
  install    Docker 개발 환경 설치 및 설정
  start      컨테이너 시작
  stop       컨테이너 정지 (상태 유지)
  down       컨테이너 완전 제거
  connect    실행 중인 컨테이너에 접속
  status     컨테이너 상태 확인
  help       이 도움말 표시

예제:
  ./dockit.sh install    # 초기 설치 및 설정
  ./dockit.sh start      # 컨테이너 시작
  ./dockit.sh stop       # 컨테이너 정지 (상태 유지)
  ./dockit.sh down       # 컨테이너 완전 제거
  ./dockit.sh connect    # 컨테이너 접속

직접 모듈 실행:
  각 모듈은 직접 실행할 수도 있습니다:
  ./src/modules/install.sh    # install 모듈 직접 실행
  ./src/modules/connect.sh    # connect 모듈 직접 실행

설정 파일:
  .dockit/.env                # 사용자 설정이 저장되는 파일
  .dockit/docker-compose.yml  # Docker Compose 설정 파일
  .dockit/dockit.log          # 로그 파일
  config/settings.env         # 언어 및 기본 설정 파일

=================================
EOF
    fi
}

# 메인 함수
help_main() {
    show_help
}

# 직접 실행 시
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    help_main "$@"
fi 