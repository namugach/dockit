#!/bin/bash

# help 모듈 - 도움말 표시

# 공통 모듈 로드
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
source "$SCRIPT_DIR/common.sh"

# 도움말 출력 함수
show_help() {
    cat << EOF

===== Dockit - Docker 개발 환경 도구 =====
간편한 Docker 개발 환경 관리 도구

사용법:
  ./dockit.sh <명령> [옵션...]

사용 가능한 명령:
  install    Docker 개발 환경 설치 및 설정
  start      컨테이너 시작
  stop       컨테이너 정지
  connect    실행 중인 컨테이너에 접속
  status     컨테이너 상태 확인
  help       이 도움말 표시

예제:
  ./dockit.sh install    # 초기 설치 및 설정
  ./dockit.sh start      # 컨테이너 시작
  ./dockit.sh connect    # 컨테이너 접속

직접 모듈 실행:
  각 모듈은 직접 실행할 수도 있습니다:
  ./modules/install.sh    # install 모듈 직접 실행
  ./modules/connect.sh    # connect 모듈 직접 실행

설정 파일:
  .env    # 사용자 설정이 저장되는 파일

=================================
EOF
}

# 메인 함수
help_main() {
    show_help
}

# 직접 실행 시
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    help_main "$@"
fi 