#!/usr/bin/env bash

# async_tasks.sh - 멀티 작업 스피너 유틸리티 (완료 메시지 유지)

# 스크립트 디렉토리 경로 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTILS_DIR="$SCRIPT_DIR"
SRC_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MODULES_DIR="$SRC_DIR/modules"

# messages 로드 여부 확인
# 다른 모듈에서 이미 로드했을 수 있음
if [ -z "$MSG_ASYNC_DONE" ]; then
  # 메시지가 로드되지 않은 경우 기본값 설정
  MSG_ASYNC_DONE="Done"
fi

declare -a tasks pids
lines=0        # 스피너 줄 수
orig_stty=""

# 1. 기본 변수
init_spinner_vars() {
  # 다양한 스피너 스타일 (주석 해제하여 사용)
  # 1. 브레이스 스타일 (기본)
  frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
  delay=0.12
  # frames=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █ ▇ ▆ ▅ ▄ ▃ ▂ ▁ )
  # delay=0.08
  cyan=$'\033[36m'; reset=$'\033[0m'
}

# 2. 작업 추가
add_task() { tasks+=("$1|$2"); }

# 3. 작업 실행
run_tasks() {
  pids=()
  for i in "${!tasks[@]}"; do
    eval "${tasks[$i]#*|}" &     # 명령 부분만 실행
    pids[$i]=$!
  done
}

# 4. 스피너 초기화
init_spinner() {
  lines=${#tasks[@]}
  tput civis
  orig_stty=$(stty -g); stty -echo     # 입력 에코 끔

  for t in "${tasks[@]}"; do
    printf "[ ] %s\n" "${t%%|*}"
  done
  printf "\033[%dA" "$lines"
}

# 5. 스피너 루프 ##########################
run_spinner() {
  local frame_idx=0
  while :; do
    local all_done=1
    for i in "${!tasks[@]}"; do
      printf "\033[%dG" 1
      if kill -0 "${pids[$i]}" 2>/dev/null; then
        all_done=0
        local f=${frames[$(((frame_idx+i)%${#frames[@]}))]}
        printf "${cyan}%s${reset} %s\033[K\n" "$f" "${tasks[$i]%%|*}"
      else
        printf "${cyan}✔${reset} %s\033[K\n" "${tasks[$i]%%|*}"
      fi
    done
    (( all_done )) && break
    (( frame_idx++ ))
    printf "\033[%dA" "$lines"
    sleep "$delay"
  done
}

# 6. 정리 
cleanup() {
  local mode=$1   # normal / interrupt
  local done_msg=$2  # 완료 메시지
  
  for pid in "${pids[@]}"; do kill "$pid" 2>/dev/null; done
  [[ -n $orig_stty ]] && stty "$orig_stty"
  tput cnorm

  if [[ $mode == "normal" ]]; then
    # 스피너 영역만 지우고 완료 메시지 출력
    [[ $lines -gt 0 ]] && printf "\033[%dA\033[J" "$lines"
    if [ -n "$done_msg" ]; then
      printf "${cyan}✔${reset} %s\n" "$done_msg"
    fi
  else
    # 강제 종료 시 화면 전부 정리
    printf "\033[2J\033[H"
  fi
  exit
}

# 7. 메인 
async_tasks() {
  local done_message="${1:-$MSG_ASYNC_DONE}"  # 기본값으로 메시지 변수 사용
  
  trap "cleanup interrupt \"$done_message\"" INT TERM
  trap "cleanup normal \"$done_message\"" EXIT  # 단독 실행일 때만 EXIT 트랩
  
  init_spinner_vars
  run_tasks
  init_spinner
  run_spinner
  cleanup normal "$done_message"  # 직접 호출해도 EXIT 트랩은 중복 실행 안 됨
}

async_tasks_hide_finish_message() {
  local done_message="${1:-$MSG_ASYNC_DONE}"  # 기본값으로 메시지 변수 사용
  
  trap "cleanup interrupt " INT TERM
  trap "cleanup normal " EXIT  # 단독 실행일 때만 EXIT 트랩
  
  init_spinner_vars
  run_tasks
  init_spinner
  run_spinner
}
# 8. 테스트 
# echo "멀티 작업 스피너 테스트"
# echo "------------------------"
# add_task "로그 파일 정리 중..."          "sleep 5"
# add_task "캐시 삭제 중..."              "sleep 3"
# add_task "설정 파일 업데이트 중..."      "sleep 6"
# add_task "서비스 재시작 중..."          "sleep 4"
# async_tasks
