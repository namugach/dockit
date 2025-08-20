#!/bin/bash

# container_base.sh - 컨테이너 액션 관련 공통 함수
# container_base.sh - Common utility functions for containers

# Load utils
# 유틸리티 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$UTILS_DIR/async_tasks.sh"

# 사용법 표시 함수
# Show usage function
show_usage() {
    log "INFO" "$MSG_STOP_USAGE"
    echo -e "  dockit stop <no> - $MSG_STOP_USAGE_NO"
    echo -e "  dockit stop this - $MSG_STOP_USAGE_THIS"
    echo -e "  dockit stop all - $MSG_STOP_USAGE_ALL"
    echo ""
}

# 컨테이너 존재 여부 확인 함수
# Function to check if container exists
container_exists() {
    local container_id="$1"
    docker container inspect "$container_id" &>/dev/null
    return $?
}

# 컨테이너 실행 상태 확인 함수
# Function to check container running state
is_container_running() {
    local container_id="$1"
    [ "$(docker container inspect -f '{{.State.Running}}' "$container_id")" = "true" ]
    return $?
}

# 컨테이너 설명 가져오기 함수
# Function to get container description
get_container_description() {
    local container_id="$1"
    local container_short=${container_id:0:12}
    local name=$(docker inspect --format "{{.Name}}" "$container_id" 2>/dev/null | sed 's/^\///')
    
    local container_desc="$container_short"
    [ -n "$name" ] && container_desc="$container_desc ($name)"
    
    echo "$container_desc"
}

# 도커 컨테이너 정보 캐싱
# Cache docker container info
get_container_info() {
    local container_id="$1"
    local info_type="$2"  # name, status 등
    
    case "$info_type" in
        "name")
            docker inspect --format "{{.Name}}" "$container_id" 2>/dev/null | sed 's/^\///'
            ;;
        "status")
            docker inspect --format "{{.State.Status}}" "$container_id" 2>/dev/null
            ;;
        "running")
            docker inspect --format "{{.State.Running}}" "$container_id" 2>/dev/null
            ;;
        *)
            echo ""
            return 1
            ;;
    esac
    
    return 0
}

# 컨테이너 ID 목록 가져오기 (필터 적용)
# Get container ID list with filter
get_container_ids() {
    local filter="$1"  # 필터 (예: 모든 컨테이너, 실행 중인 컨테이너 등)
    
    docker ps -a --filter "label=com.dockit=true" $filter --format "{{.ID}}"
}

perform_all_containers_action() {
    # -- 1) 메시지 설정 --------------------------------
    local start_msg="$1"
    local result_msg="$2"
    local empty_msg="$3"
    local spinner_txt="$4"
    local -n dockir_cmd="$5"
    # dockir_cmd 에 들어갈 내용 
    # docker ps -a --filter label=com.dockit=true \
    #                   --filter status=running --format '{{.ID}}'
    log "INFO" "$start_msg"

    # -- 2) 대상 컨테이너 목록 --------------------------
    # 실행 중인 컨테이너만 대상으로 함
    mapfile -t cids < <("${docker_cmd[@]}")

    [[ ${#cids[@]} -eq 0 ]] && { log "INFO" "$empty_msg"; return 0; }

    # -- 3) 성공/실패 카운트용 임시 파일 ----------------
    local tmp; tmp=$(mktemp)
    echo "0 0" > "$tmp"    # success fail

    # -- 4) 각 컨테이너 작업 큐에 등록 ------------------
    for cid in "${cids[@]}"; do
        local short=${cid:0:12}
        local name=$(get_container_info "$cid" "name")
        [[ -n $name ]] && short="$short ($name)"

        local spinner=$(printf "$MSG_CONTAINER_ACTION_FORMAT" "$short" "$spinner_txt")

        add_task "$spinner" "
            if container_action '$cid' true >/dev/null 2>&1; then
                awk '{\$1++}1' $tmp > ${tmp}.n && mv ${tmp}.n $tmp
            else
                awk '{\$2++}1' $tmp > ${tmp}.n && mv ${tmp}.n $tmp
            fi
        "
    done

    # -- 5) 비동기 작업 실행 ----------------------------
    async_tasks_no_exit "$MSG_TASKS_DONE"

    # -- 6) 결과 집계 & 출력 -----------------------------
    local ok fail
    read -r ok fail < "$tmp"
    rm -f "$tmp"

    (( fail > 0 )) && log "INFO" "$(printf "$result_msg" "$ok" "$fail")"
    return 0
}