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

# clone 전용 비차단 async_tasks (exit하지 않음)
# Non-blocking async_tasks for clone (does not exit)
async_tasks_no_exit() {
  local done_message="${1:-$MSG_ASYNC_DONE}"  # 기본값으로 메시지 변수 사용
  
  # EXIT 트랩 없이 INT/TERM만 처리
  trap "cleanup_no_exit interrupt \"$done_message\"" INT TERM
  
  init_spinner_vars
  run_tasks
  init_spinner
  run_spinner
  cleanup_no_exit normal "$done_message"
  
  # 트랩 해제
  trap - INT TERM
}

# clone 전용 정리 함수 (exit하지 않음)
# Cleanup function for clone (does not exit)
cleanup_no_exit() {
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
    return 1  # exit 대신 return 사용
  fi
}

# 8. Docker pull 실시간 출력 함수 (메인 제목 스피너 + 하위 항목 들여쓰기)
async_docker_pull_with_live_output() {
    local image="$1"
    local display_name="$2"
    local done_message="${3:-이미지 다운로드 완료}"
    
    # 기존 스피너 설정 재사용
    init_spinner_vars
    
    # 색상 정의
    local purple=$'\033[35m'
    local gray=$'\033[90m'        # 회색 (하위 항목용)
    local green=$'\033[32m'
    local red=$'\033[31m'
    
    # 진행률 표시 제한 변수
    local frame_idx=0
    local max_lines=5
    local recent_lines=()
    local main_title="이미지 다운로드: $display_name"
    
    trap "cleanup_docker_live interrupt \"$done_message\"" INT TERM
    
    # 초기 메인 제목 출력
    local spinner=${frames[0]}
    printf "${purple}${spinner}${reset} %s\n" "$main_title"
    
    # Docker pull을 실행하며 출력을 실시간으로 표시
    local exit_code=0
    stdbuf -o0 -e0 docker pull "$image" 2>&1 | while IFS= read -r line; do
        local spinner=${frames[$((frame_idx % ${#frames[@]}))]}
        ((frame_idx++))
        
        # 하위 항목들 (들여쓰기 2칸 + 회색 색상 + 고정 아이콘)
        if [[ "$line" =~ ^[a-f0-9]+:.*Downloading.*MB ]]; then
            recent_lines+=("  ${gray}⬇${reset} $line")
        elif [[ "$line" =~ ^[a-f0-9]+:.*Extracting.*MB ]]; then
            recent_lines+=("  ${gray}📦${reset} $line")
        elif [[ "$line" =~ ^[a-f0-9]+:.*(Download complete|Pull complete|Already exists) ]]; then
            recent_lines+=("  ${green}✔${reset} $line")
        elif [[ "$line" =~ ^[a-f0-9]+:.*Pulling.*fs.*layer ]]; then
            recent_lines+=("  ${gray}•${reset} $line")
        elif [[ "$line" =~ ^[a-f0-9]+:.*Waiting ]]; then
            recent_lines+=("  ${gray}⏳${reset} $line")
        elif [[ "$line" =~ ^[a-f0-9]+:.*Verifying.*Checksum ]]; then
            recent_lines+=("  ${gray}🔍${reset} $line")
        elif [[ "$line" =~ Status:.*Downloaded.*newer.*image ]]; then
            recent_lines+=("  ${green}✔${reset} $line")
        elif [[ "$line" =~ (Error|error|failed|denied|invalid) ]]; then
            recent_lines+=("  ${red}❌${reset} $line")
        elif [[ "$line" =~ ^[a-f0-9]+: ]]; then
            recent_lines+=("  ${gray}•${reset} $line")
        elif [[ "$line" =~ Digest:.* ]]; then
            recent_lines+=("  ${gray}🔑${reset} $line")
        else
            # 기타 출력도 들여쓰기로 표시
            recent_lines+=("  ${gray}•${reset} $line")
        fi
        
        # 최근 5줄만 유지
        if [ ${#recent_lines[@]} -gt $max_lines ]; then
            recent_lines=("${recent_lines[@]:1}")
        fi
        
        # 전체 화면 지우고 다시 출력 (메인 제목 + 하위 항목들)
        local total_lines=$((1 + ${#recent_lines[@]}))
        printf "\033[%dA\033[J" "$total_lines"
        
        # 메인 제목 (계속 회전하는 스피너)
        printf "${purple}${spinner}${reset} %s\n" "$main_title"
        
        # 하위 항목들 출력
        for recent_line in "${recent_lines[@]}"; do
            printf "%s\n" "$recent_line"
        done
        
        sleep "$delay"
    done
    
    # PIPESTATUS 배열로 docker pull의 실제 종료 코드 확인
    exit_code=${PIPESTATUS[0]}
    
    # 진행률 표시 영역 정리
    local total_lines=$((1 + ${#recent_lines[@]}))
    if [ $total_lines -gt 0 ]; then
        printf "\033[%dA\033[J" "$total_lines"
    fi
    
    if [ $exit_code -eq 0 ]; then
        printf "${green}✔${reset} %s\n" "$done_message"
    else
        printf "${red}❌${reset} 이미지 다운로드 실패\n"
    fi
    
    trap - INT TERM
    return $exit_code
}

# Docker pull 정리 함수
cleanup_docker_live() {
    local mode=$1
    local done_msg=$2
    
    if [[ $mode == "interrupt" ]]; then
        printf "\n${cyan}❌${reset} Docker 다운로드가 중단되었습니다.\n"
        return 1
    fi
}


# 9. 독립 스피너 시스템 (비동기 스피너)
# 스피너 상태 파일들
declare -g spinner_state_file=""
declare -g spinner_control_file=""
declare -g spinner_pid=""

# 독립 스피너 시작
start_independent_spinner() {
    local main_title="$1"
    local temp_dir="${TMPDIR:-/tmp}"
    
    # 고유 파일명 생성 (PID 기반)
    spinner_state_file="$temp_dir/dockit_spinner_state_$$"
    spinner_control_file="$temp_dir/dockit_spinner_control_$$"
    
    # 초기 상태 설정
    cat > "$spinner_state_file" << EOF
title=$main_title
lines_count=0
EOF
    
    # 제어 파일 생성 (스피너 실행 신호)
    touch "$spinner_control_file"
    
    # 스피너 백그라운드 프로세스 시작
    (
        init_spinner_vars
        local frame_idx=0
        local purple=$'\033[35m'
        local gray=$'\033[90m'
        local green=$'\033[32m'
        local red=$'\033[31m'
        
        # 초기 화면 설정
        tput civis  # 커서 숨기기
        
        while [[ -f "$spinner_control_file" ]]; do
            # 상태 파일에서 최신 정보 읽기
            if [[ -f "$spinner_state_file" ]]; then
                local title=""
                local lines_count=0
                local current_lines=()
                
                while IFS='=' read -r key value; do
                    case "$key" in
                        title) title="$value" ;;
                        lines_count) lines_count="$value" ;;
                        line_*) current_lines+=("$value") ;;
                    esac
                done < "$spinner_state_file"
                
                # 스피너 프레임 계산
                local spinner=${frames[$((frame_idx % ${#frames[@]}))]}
                ((frame_idx++))
                
                # 이전 출력 지우기 (메인 제목 + 하위 라인들)
                local total_lines=$((1 + lines_count))
                if [[ $total_lines -gt 1 ]]; then
                    printf "\033[%dA\033[J" "$total_lines"
                elif [[ $frame_idx -gt 1 ]]; then
                    printf "\033[1A\033[J"
                fi
                
                # 메인 제목 출력 (스피너 포함)
                if [[ -n "$title" ]]; then
                    printf "${purple}${spinner}${reset} %s\n" "$title"
                fi
                
                # 하위 라인들 출력
                for line in "${current_lines[@]}"; do
                    if [[ -n "$line" ]]; then
                        printf "%s\n" "$line"
                    fi
                done
            fi
            
            sleep "$delay"
        done
        
        # 정리
        tput cnorm  # 커서 보이기
    ) &
    
    spinner_pid=$!
}

# 스피너 상태 업데이트
update_spinner_state() {
    local new_lines=("$@")
    
    if [[ -n "$spinner_state_file" && -f "$spinner_control_file" ]]; then
        # 상태 파일에서 제목 읽기
        local title=""
        if [[ -f "$spinner_state_file" ]]; then
            title=$(grep "^title=" "$spinner_state_file" | cut -d'=' -f2-)
        fi
        
        # 새로운 상태 파일 작성
        {
            echo "title=$title"
            echo "lines_count=${#new_lines[@]}"
            local i=0
            for line in "${new_lines[@]}"; do
                echo "line_$i=$line"
                ((i++))
            done
        } > "$spinner_state_file"
    fi
}

# 독립 스피너 정지
stop_independent_spinner() {
    local exit_code=${1:-0}
    local final_message="$2"
    
    # 제어 파일 삭제 (스피너 종료 신호)
    [[ -f "$spinner_control_file" ]] && rm -f "$spinner_control_file"
    
    # 스피너 프로세스 종료 대기
    if [[ -n "$spinner_pid" ]]; then
        wait "$spinner_pid" 2>/dev/null || true
    fi
    
    # 상태 파일 정리
    [[ -f "$spinner_state_file" ]] && rm -f "$spinner_state_file"
    
    # 최종 메시지 출력
    if [[ -n "$final_message" ]]; then
        local green=$'\033[32m'
        local red=$'\033[31m'
        local reset=$'\033[0m'
        
        if [[ $exit_code -eq 0 ]]; then
            printf "${green}✔${reset} %s\n" "$final_message"
        else
            printf "${red}❌${reset} %s\n" "$final_message"
        fi
    fi
    
    # 커서 복원
    tput cnorm
}

# 독립 스피너 기반 Docker pull 함수
async_docker_pull_with_independent_spinner() {
    local image="$1"
    local display_name="$2"
    local done_message="${3:-이미지 다운로드 완료}"
    
    # 기존 스피너 설정 재사용
    init_spinner_vars
    
    # 색상 정의
    local gray=$'\033[90m'
    local green=$'\033[32m'
    local red=$'\033[31m'
    local reset=$'\033[0m'
    
    local main_title="이미지 다운로드: $display_name"
    local max_lines=5
    local recent_lines=()
    
    # 독립 스피너 시작
    start_independent_spinner "$main_title"
    
    # 정리 함수 설정
    trap "stop_independent_spinner 1 \"다운로드가 중단되었습니다\"; return 1" INT TERM
    
    # Docker pull을 실행하며 출력을 별도로 처리
    local exit_code=0
    while IFS= read -r line; do
        # 하위 항목들 파싱 (기존 로직 유지)
        if [[ "$line" =~ ^[a-f0-9]+:.*Downloading.*MB ]]; then
            recent_lines+=("  ${gray}⬇${reset} $line")
        elif [[ "$line" =~ ^[a-f0-9]+:.*Extracting.*MB ]]; then
            recent_lines+=("  ${gray}📦${reset} $line")
        elif [[ "$line" =~ ^[a-f0-9]+:.*(Download complete|Pull complete|Already exists) ]]; then
            recent_lines+=("  ${green}✔${reset} $line")
        elif [[ "$line" =~ ^[a-f0-9]+:.*Pulling.*fs.*layer ]]; then
            recent_lines+=("  ${gray}•${reset} $line")
        elif [[ "$line" =~ ^[a-f0-9]+:.*Waiting ]]; then
            recent_lines+=("  ${gray}⏳${reset} $line")
        elif [[ "$line" =~ ^[a-f0-9]+:.*Verifying.*Checksum ]]; then
            recent_lines+=("  ${gray}🔍${reset} $line")
        elif [[ "$line" =~ Status:.*Downloaded.*newer.*image ]]; then
            recent_lines+=("  ${green}✔${reset} $line")
        elif [[ "$line" =~ (Error|error|failed|denied|invalid) ]]; then
            recent_lines+=("  ${red}❌${reset} $line")
        elif [[ "$line" =~ ^[a-f0-9]+: ]]; then
            recent_lines+=("  ${gray}•${reset} $line")
        elif [[ "$line" =~ Digest:.* ]]; then
            recent_lines+=("  ${gray}🔑${reset} $line")
        else
            # 기타 출력도 들여쓰기로 표시
            recent_lines+=("  ${gray}•${reset} $line")
        fi
        
        # 최근 5줄만 유지
        if [[ ${#recent_lines[@]} -gt $max_lines ]]; then
            recent_lines=("${recent_lines[@]:1}")
        fi
        
        # 스피너 상태 업데이트 (Docker 출력이 있을 때만)
        update_spinner_state "${recent_lines[@]}"
        
    done < <(stdbuf -o0 -e0 docker pull "$image" 2>&1)
    
    # docker pull 종료 코드 확인
    exit_code=${PIPESTATUS[0]}
    
    # 스피너 정지 및 최종 메시지 출력
    if [[ $exit_code -eq 0 ]]; then
        stop_independent_spinner 0 "$done_message"
    else
        stop_independent_spinner 1 "이미지 다운로드 실패"
    fi
    
    # 트랩 해제
    trap - INT TERM
    
    return $exit_code
}

# 10. 테스트용 예제 (주석 처리됨)
# echo "멀티 작업 스피너 테스트"
# echo "------------------------"
# add_task "로그 파일 정리 중..."          "sleep 5"
# add_task "캐시 삭제 중..."              "sleep 3" 
# add_task "설정 파일 업데이트 중..."      "sleep 6"
# add_task "서비스 재시작 중..."          "sleep 4"
# async_tasks
