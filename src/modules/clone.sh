#!/bin/bash

# Clone Module for Dockit
# 프로젝트 복제 모듈

# Load common module
# 공통 모듈 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh" "clone"

# Load modules
# 모듈 로드
source "$MODULES_DIR/registry.sh"

# Clone specific constants
# Clone 관련 상수 정의
readonly CONTAINER_START_TIMEOUT=30
readonly DOCKER_COMMIT_TIMEOUT=300
readonly CLONE_TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Global variables for rollback tracking
# 롤백 추적을 위한 전역 변수
ROLLBACK_CREATED_IMAGE=""
ROLLBACK_CREATED_DIR=""
ROLLBACK_REGISTRY_ID=""
ROLLBACK_ENABLED=true

# Rollback mechanism for cleanup on failure
# 실패 시 정리를 위한 롤백 메커니즘
execute_rollback() {
    local exit_code="${1:-1}"
    
    if [ "$ROLLBACK_ENABLED" != "true" ]; then
        printf "${YELLOW}[WARN] 롤백이 비활성화되어 있습니다${NC}\n"
        return $exit_code
    fi
    
    printf "${RED}[ERROR] 복제 실패! 롤백을 시작합니다...${NC}\n"
    
    local rollback_errors=0
    
    # 1. Remove registry entry if created
    if [ -n "$ROLLBACK_REGISTRY_ID" ]; then
        printf "${CYAN}[ROLLBACK] 레지스트리 항목 제거 중: $ROLLBACK_REGISTRY_ID${NC}\n"
        if command -v jq &> /dev/null && [ -f "$REGISTRY_FILE" ]; then
            local temp_file=$(mktemp)
            if jq "del(.\"$ROLLBACK_REGISTRY_ID\")" "$REGISTRY_FILE" > "$temp_file" 2>/dev/null; then
                mv "$temp_file" "$REGISTRY_FILE"
                printf "${GREEN}[ROLLBACK] 레지스트리 항목 제거 완료${NC}\n"
            else
                printf "${RED}[ROLLBACK] 레지스트리 항목 제거 실패${NC}\n"
                rollback_errors=$((rollback_errors + 1))
                rm -f "$temp_file"
            fi
        else
            printf "${YELLOW}[ROLLBACK] jq가 없거나 레지스트리 파일이 없습니다${NC}\n"
        fi
    fi
    
    # 2. Remove created directory if exists
    if [ -n "$ROLLBACK_CREATED_DIR" ] && [ -d "$ROLLBACK_CREATED_DIR" ]; then
        printf "${CYAN}[ROLLBACK] 생성된 디렉토리 제거 중: $ROLLBACK_CREATED_DIR${NC}\n"
        if rm -rf "$ROLLBACK_CREATED_DIR"; then
            printf "${GREEN}[ROLLBACK] 디렉토리 제거 완료${NC}\n"
        else
            printf "${RED}[ROLLBACK] 디렉토리 제거 실패${NC}\n"
            rollback_errors=$((rollback_errors + 1))
        fi
    fi
    
    # 3. Remove created Docker image if exists
    if [ -n "$ROLLBACK_CREATED_IMAGE" ]; then
        printf "${CYAN}[ROLLBACK] 생성된 Docker 이미지 제거 중: $ROLLBACK_CREATED_IMAGE${NC}\n"
        if docker rmi "$ROLLBACK_CREATED_IMAGE" 2>/dev/null; then
            printf "${GREEN}[ROLLBACK] Docker 이미지 제거 완료${NC}\n"
        else
            printf "${YELLOW}[ROLLBACK] Docker 이미지 제거 실패 (이미 제거되었거나 존재하지 않음)${NC}\n"
            # Docker image removal failure is not critical for rollback
        fi
    fi
    
    if [ $rollback_errors -eq 0 ]; then
        printf "${GREEN}[ROLLBACK] 롤백이 성공적으로 완료되었습니다${NC}\n"
    else
        printf "${RED}[ROLLBACK] 롤백 중 $rollback_errors개의 오류가 발생했습니다${NC}\n"
    fi
    
    # Reset rollback variables
    ROLLBACK_CREATED_IMAGE=""
    ROLLBACK_CREATED_DIR=""
    ROLLBACK_REGISTRY_ID=""
    
    return $exit_code
}

# Trap function to handle unexpected exits
# 예상치 못한 종료를 처리하는 트랩 함수
cleanup_on_exit() {
    if [ -n "$ROLLBACK_CREATED_IMAGE" ] || [ -n "$ROLLBACK_CREATED_DIR" ] || [ -n "$ROLLBACK_REGISTRY_ID" ]; then
        printf "${YELLOW}[WARN] 예상치 못한 종료가 감지되었습니다. 롤백을 실행합니다...${NC}\n"
        execute_rollback $?
    fi
}

# Set trap for cleanup on script exit
trap cleanup_on_exit EXIT INT TERM

# Security validation functions
# 보안 검증 함수들

# Validate project name input (prevent injection attacks)
# 프로젝트 이름 입력 검증 (인젝션 공격 방지)
validate_project_name() {
    local name="$1"
    
    # Check for empty or null
    [ -z "$name" ] && return 1
    
    # Allow only alphanumeric, hyphens, underscores (no special chars, paths, spaces)
    [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]] || return 1
    
    # Prevent reserved names and dangerous patterns
    case "$name" in
        "." | ".." | "root" | "admin" | "sudo" | "docker" | "bin" | "etc" | "var" | "tmp")
            return 1
            ;;
        *"/"* | *"\\"* | *"|"* | *"&"* | *";"* | *"\`"* | *"$"* | *"("* | *")"*)
            return 1
            ;;
    esac
    
    # Length limits (1-50 characters)
    local len=${#name}
    [ $len -ge 1 ] && [ $len -le 50 ]
}

# Safely escape string for sed command
# sed 명령어용 문자열 안전 이스케이프
escape_for_sed() {
    local input="$1"
    # Escape special characters for sed
    echo "$input" | sed 's/[[\.*^$()+?{|]/\\&/g'
}

# Validate container/image names for Docker safety
# Docker 안전성을 위한 컨테이너/이미지 이름 검증
validate_docker_name() {
    local name="$1"
    
    # Docker name requirements: lowercase, alphanumeric, hyphens, underscores, periods, slashes
    [[ "$name" =~ ^[a-z0-9._/-]+$ ]] || return 1
    
    # Must not start with period, hyphen, or slash
    [[ "$name" =~ ^[a-z0-9] ]] || return 1
    
    return 0
}

# Extract project name from IMAGE_NAME or path
# IMAGE_NAME 또는 경로에서 프로젝트 이름 추출
extract_project_name() {
    local source="$1"
    
    # IMAGE_NAME에서 추출하는 경우 (dockit-home-hgs-dockit_work-a → a)
    if [[ "$source" =~ ^dockit- ]]; then
        echo "$source" | sed 's/^dockit-.*-//'
    else
        # 경로에서 직접 추출하는 경우 (/home/hgs/dockit_work/a → a)
        basename "$source"
    fi
}

# Check for name conflicts and generate alternative names
# 이름 충돌 검사 및 대안 이름 생성
resolve_conflicts() {
    local desired_name="$1"
    local current_dir="$2"
    local counter=2
    local final_name="$desired_name"
    
    # 현재 디렉토리에서 충돌 검사
    while [ -d "$current_dir/$final_name" ]; do
        final_name="${desired_name}-${counter}"
        counter=$((counter + 1))
    done
    
    echo "$final_name"
}

# Interactive project name input
# 대화형 프로젝트 이름 입력
prompt_for_name() {
    local source_id="$1"
    local default_name="$2"
    local suggested_name="$3"
    local user_input
    
    printf "${CYAN}$(printf "$MSG_CLONE_STARTING" "$source_id")${NC}\n" >&2
    
    if [ "$default_name" != "$suggested_name" ]; then
        # 충돌이 있는 경우
        printf "${YELLOW}⚠️  $(printf "$MSG_CLONE_DIRECTORY_EXISTS" "$default_name")${NC}\n" >&2
        printf "${GREEN}💡 $(printf "$MSG_CLONE_SUGGESTED_NAME" "$suggested_name")${NC}\n" >&2
        read -p "$(printf "$MSG_CLONE_ENTER_NAME") (${suggested_name}): " user_input
    else
        # 충돌이 없는 경우
        read -p "$(printf "$MSG_CLONE_ENTER_NAME") (${default_name}): " user_input
    fi
    
    # 사용자 입력이 없으면 suggested_name 사용
    local chosen_name="${user_input:-$suggested_name}"
    
    # 보안 검증 및 충돌 확인 루프
    while true; do
        # 보안 검증: 프로젝트 이름 유효성 검사
        if ! validate_project_name "$chosen_name"; then
            printf "${RED}❌ 잘못된 프로젝트 이름: '$chosen_name'${NC}\n" >&2
            printf "${YELLOW}📋 허용되는 문자: 영문, 숫자, 하이픈(-), 언더스코어(_)${NC}\n" >&2
            printf "${YELLOW}📋 길이: 1-50자, 특수문자/공백/경로문자 금지${NC}\n" >&2
            read -p "$(printf "$MSG_CLONE_ENTER_NAME"): " chosen_name
            continue
        fi
        
        # 디렉토리 충돌 확인
        if [ -d "./$chosen_name" ]; then
            printf "${RED}❌ $(printf "$MSG_CLONE_DIRECTORY_CONFLICT" "$chosen_name")${NC}\n" >&2
            read -p "$(printf "$MSG_CLONE_ENTER_NAME"): " chosen_name
            continue
        fi
        
        # 모든 검증 통과
        break
    done
    
    echo "$chosen_name"
}

# Parse clone command arguments
# Clone 명령어 인수 파싱
parse_clone_arguments() {
    local source_project="$1"
    local target_name="$2"
    
    # 소스 프로젝트 필수 확인
    if [ -z "$source_project" ]; then
        printf "${RED}Error: $MSG_CLONE_ERROR_NO_SOURCE${NC}\n"
        printf "${YELLOW}$MSG_CLONE_USAGE${NC}\n"
        return 1
    fi
    
    echo "SOURCE_PROJECT=$source_project"
    echo "TARGET_NAME=$target_name"
    return 0
}

# Resolve project number to full project ID
# 프로젝트 번호를 전체 프로젝트 ID로 변환
resolve_project_id() {
    local input="$1"
    
    # 숫자인지 확인
    if [[ "$input" =~ ^[0-9]+$ ]]; then
        # 번호를 ID로 변환
        local registry_json=$(cat "$REGISTRY_FILE")
        local count=0
        while IFS= read -r project_id; do
            count=$((count + 1))
            if [ "$count" -eq "$input" ]; then
                echo "$project_id"
                return 0
            fi
        done < <(echo "$registry_json" | jq -r 'keys[]')
        return 1  # 번호에 해당하는 프로젝트 없음
    else
        # 이미 ID 형태인 경우 (전체 또는 축약)
        local registry_json=$(cat "$REGISTRY_FILE")
        # 전체 ID인지 확인
        if echo "$registry_json" | jq -e --arg id "$input" 'has($id)' > /dev/null; then
            echo "$input"
            return 0
        fi
        # 축약 ID인지 확인 (앞 12자리)
        while IFS= read -r project_id; do
            if [ "${project_id:0:12}" = "$input" ]; then
                echo "$project_id"
                return 0
            fi
        done < <(echo "$registry_json" | jq -r 'keys[]')
        return 1  # 일치하는 프로젝트 없음
    fi
}

# Get project information from registry
# 레지스트리에서 프로젝트 정보 조회
get_project_info() {
    local project_id="$1"
    local -n path_ref=$2
    local -n image_ref=$3
    local -n container_ref=$4
    local -n state_ref=$5
    
    local registry_json=$(cat "$REGISTRY_FILE")
    
    # 레지스트리에서 프로젝트 정보 추출
    path_ref=$(echo "$registry_json" | jq -r --arg id "$project_id" '.[$id].path')
    state_ref=$(echo "$registry_json" | jq -r --arg id "$project_id" '.[$id].state')
    
    # 프로젝트 경로의 .env 파일에서 이미지 및 컨테이너 정보 추출
    local env_file="$path_ref/.dockit_project/.env"
    if [ -f "$env_file" ]; then
        image_ref=$(grep "^IMAGE_NAME=" "$env_file" | cut -d'=' -f2 | sed 's/^"\|"$//g')
        container_ref=$(grep "^CONTAINER_NAME=" "$env_file" | cut -d'=' -f2 | sed 's/^"\|"$//g')
    else
        return 1
    fi
    
    # 정보가 올바르게 추출되었는지 확인
    if [ -z "$path_ref" ] || [ "$path_ref" = "null" ]; then
        return 1
    fi
    
    return 0
}

# Gather source project information
# 소스 프로젝트 정보 수집
gather_source_info() {
    local source_project="$1"
    
    printf "${CYAN}[INFO] $MSG_CLONE_GATHERING_INFO${NC}\n"
    
    # 1. 프로젝트 ID 해결
    local project_id
    project_id=$(resolve_project_id "$source_project")
    if [ $? -ne 0 ]; then
        printf "${RED}[ERROR] 프로젝트 #$source_project을(를) 찾을 수 없습니다${NC}\n"
        return 1
    fi
    
    # 2. 프로젝트 정보 조회
    local project_path project_image project_container project_state
    if ! get_project_info "$project_id" project_path project_image project_container project_state; then
        printf "${RED}[ERROR] 프로젝트 정보를 읽을 수 없습니다${NC}\n"
        return 1
    fi
    
    # 3. 글로벌 변수로 저장 (다른 함수에서 사용)
    SOURCE_PROJECT_ID="$project_id"
    SOURCE_PROJECT_PATH="$project_path"
    SOURCE_PROJECT_IMAGE="$project_image"
    SOURCE_PROJECT_CONTAINER="$project_container"
    SOURCE_PROJECT_STATE="$project_state"
    
    printf "${GREEN}[SUCCESS] $MSG_CLONE_INFO_SUCCESS${NC}\n"
    printf "${CYAN}[DEBUG] Path: $project_path${NC}\n"
    printf "${CYAN}[DEBUG] Image: $project_image${NC}\n"
    printf "${CYAN}[DEBUG] Container: $project_container${NC}\n"
    printf "${CYAN}[DEBUG] State: $project_state${NC}\n"
    
    return 0
}

# Determine target project name
# 대상 프로젝트 이름 결정
determine_target_name() {
    local extracted_name="$1"
    local provided_name="$2"
    
    if [ -n "$provided_name" ]; then
        # 명령줄에서 이름이 지정된 경우 - 보안 검증 필요 (조용한 모드)
        if ! validate_project_name "$provided_name"; then
            printf "${RED}[ERROR] 잘못된 프로젝트 이름: '$provided_name'${NC}\n" >&2
            printf "${YELLOW}[INFO] 허용되는 문자: 영문, 숫자, 하이픈(-), 언더스코어(_)${NC}\n" >&2
            printf "${YELLOW}[INFO] 길이: 1-50자, 특수문자/공백/경로문자 금지${NC}\n" >&2
            return 1
        fi
        
        # 디렉토리 충돌 확인
        if [ -d "./$provided_name" ]; then
            printf "${RED}[ERROR] $(printf "$MSG_CLONE_DIRECTORY_CONFLICT" "$provided_name")${NC}\n" >&2
            return 1
        fi
        
        echo "$provided_name"
    else
        # 대화형 모드 - 이때만 안내 메시지 출력
        printf "${CYAN}[INFO] $MSG_CLONE_DETERMINING_NAME${NC}\n" >&2
        local default_name="$extracted_name"
        local suggested_name=$(resolve_conflicts "$default_name" ".")
        prompt_for_name "1" "$default_name" "$suggested_name"
    fi
}

# Ensure container is running
# 컨테이너 실행 확인 및 자동 시작
ensure_container_running() {
    local container_name="$1"
    local container_state="$2"
    
    printf "${CYAN}[INFO] 컨테이너 상태 확인 중: $container_name${NC}\n"
    
    # 컨테이너 상태가 running이 아닌 경우 시작 시도
    if [ "$container_state" != "running" ]; then
        printf "${YELLOW}[WARN] 컨테이너가 중지되어 있습니다. 자동 시작 중...${NC}\n"
        
        # Docker start 명령 실행
        if docker start "$container_name" > /dev/null 2>&1; then
            printf "${GREEN}[SUCCESS] 컨테이너가 성공적으로 시작되었습니다${NC}\n"
            
            # 컨테이너가 완전히 시작될 때까지 대기
            local wait_count=0
            while [ $wait_count -lt $CONTAINER_START_TIMEOUT ]; do
                if docker inspect "$container_name" --format='{{.State.Running}}' 2>/dev/null | grep -q "true"; then
                    printf "${GREEN}[SUCCESS] 컨테이너 시작 완료${NC}\n"
                    return 0
                fi
                sleep 1
                wait_count=$((wait_count + 1))
            done
            
            printf "${RED}[ERROR] 컨테이너 시작 시간 초과 (${CONTAINER_START_TIMEOUT}초)${NC}\n"
            return 1
        else
            printf "${RED}[ERROR] 컨테이너 시작 실패: $container_name${NC}\n"
            return 1
        fi
    else
        printf "${GREEN}[SUCCESS] 컨테이너가 이미 실행 중입니다${NC}\n"
        return 0
    fi
}

# Container preparation phase
# 컨테이너 준비 단계
execute_container_preparation() {
    printf "${CYAN}[INFO] 컨테이너 상태 확인 및 준비 중...${NC}\n"
    
    if ! ensure_container_running "$SOURCE_PROJECT_CONTAINER" "$SOURCE_PROJECT_STATE"; then
        printf "${RED}[ERROR] 컨테이너를 시작할 수 없습니다${NC}\n"
        return 1
    fi
    
    return 0
}

# Docker commit phase
# Docker 커밋 단계
execute_docker_commit() {
    local target_name="$1"
    local -n new_image_ref=$2
    
    printf "${CYAN}[INFO] Docker 이미지 커밋 실행 중...${NC}\n"
    
    new_image_ref="${SOURCE_PROJECT_IMAGE}:clone-${CLONE_TIMESTAMP}"
    
    printf "${CYAN}[INFO] 새 이미지 생성 중: $new_image_ref${NC}\n"
    if ! timeout $DOCKER_COMMIT_TIMEOUT docker commit "$SOURCE_PROJECT_CONTAINER" "$new_image_ref"; then
        printf "${RED}[ERROR] Docker commit 실패${NC}\n"
        return 1
    fi
    
    # Track created image for rollback
    ROLLBACK_CREATED_IMAGE="$new_image_ref"
    
    printf "${GREEN}[SUCCESS] 이미지 커밋 완료${NC}\n"
    return 0
}

# Project structure setup phase
# 프로젝트 구조 설정 단계
execute_project_setup() {
    local target_name="$1"
    local -n target_dir_ref=$2
    
    printf "${CYAN}[INFO] 프로젝트 구조 생성 중...${NC}\n"
    
    target_dir_ref="./$target_name"
    
    if ! mkdir -p "$target_dir_ref/.dockit_project"; then
        printf "${RED}[ERROR] 프로젝트 디렉토리 생성 실패${NC}\n"
        return 1
    fi
    
    # Track created directory for rollback
    ROLLBACK_CREATED_DIR="$(pwd)/$target_name"
    
    # .dockit_project 폴더 전체 복사 (숨김파일 포함)
    if ! cp -r "$SOURCE_PROJECT_PATH/.dockit_project/." "$target_dir_ref/.dockit_project/"; then
        printf "${RED}[ERROR] 설정 파일 복사 실패${NC}\n"
        return 1
    fi
    
    printf "${GREEN}[SUCCESS] 프로젝트 구조 생성 완료${NC}\n"
    return 0
}

# Configuration update phase
# 설정 파일 업데이트 단계
execute_configuration_update() {
    local target_name="$1"
    local target_dir="$2"
    local new_image_name="$3"
    local -n new_container_name_ref=$4
    
    printf "${CYAN}[INFO] 설정 파일 수정 중...${NC}\n"
    
    # 안전한 컨테이너 이름 생성 (보안 강화)
    local safe_pwd=$(basename "$(pwd)" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g')
    local safe_target=$(echo "$target_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g')
    new_container_name_ref="dockit-${safe_pwd}-${safe_target}"
    
    # Docker 이름 규칙 검증
    if ! validate_docker_name "$new_container_name_ref"; then
        printf "${RED}[ERROR] 생성된 컨테이너 이름이 Docker 규칙에 맞지 않습니다: $new_container_name_ref${NC}\n"
        return 1
    fi
    
    local env_file="$target_dir/.dockit_project/.env"
    local compose_file="$target_dir/.dockit_project/docker-compose.yml"
    
    # 안전한 sed 명령어 사용 (명령어 주입 방지)
    local escaped_image_name=$(escape_for_sed "$new_image_name")
    local escaped_container_name=$(escape_for_sed "$new_container_name_ref")
    
    # IMAGE_NAME과 CONTAINER_NAME 업데이트
    sed -i "s|IMAGE_NAME=.*|IMAGE_NAME=\"${escaped_image_name}\"|" "$env_file"
    sed -i "s|CONTAINER_NAME=.*|CONTAINER_NAME=\"${escaped_container_name}\"|" "$env_file"
    
    # docker-compose.yml 파일 수정 (보안 강화)
    if [ -f "$compose_file" ]; then
        # 원본 컨테이너 이름도 안전하게 이스케이프
        local escaped_source_container=$(escape_for_sed "$SOURCE_PROJECT_CONTAINER")
        
        # name 필드 업데이트
        sed -i "s|^name:.*|name: ${escaped_container_name}|" "$compose_file"
        
        # image 필드 업데이트 (실제 커밋된 이미지 이름 사용)
        sed -i "s|image:.*|image: ${escaped_image_name}|" "$compose_file"
        
        # container_name 필드 업데이트
        sed -i "s|container_name:.*|container_name: ${escaped_container_name}|" "$compose_file"
        
        # networks 섹션 업데이트 (안전한 치환)
        sed -i "s|${escaped_source_container}|${escaped_container_name}|g" "$compose_file"
        
        # labels 섹션 업데이트  
        sed -i "s|com.dockit.project=.*|com.dockit.project=${escaped_container_name}\"|" "$compose_file"
        
        printf "${GREEN}[SUCCESS] docker-compose.yml 파일 수정 완료${NC}\n"
    fi
    
    printf "${GREEN}[SUCCESS] 설정 파일 수정 완료${NC}\n"
    return 0
}

# Registry registration phase
# 레지스트리 등록 단계
execute_registry_registration() {
    local target_name="$1"
    
    printf "${CYAN}[INFO] 레지스트리 등록 중...${NC}\n"
    
    # 새 프로젝트 ID 생성
    local new_project_id=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 64 | head -n 1)
    local new_project_path="$(pwd)/$target_name"
    local current_timestamp=$(date +%s)
    
    # Track registry ID for rollback before adding to registry
    ROLLBACK_REGISTRY_ID="$new_project_id"
    
    # 레지스트리에 새 프로젝트 추가
    local registry_json=$(cat "$REGISTRY_FILE")
    local updated_registry=$(echo "$registry_json" | jq --arg id "$new_project_id" \
        --arg path "$new_project_path" \
        --arg timestamp "$current_timestamp" \
        '. + {($id): {
            "path": $path,
            "created": ($timestamp | tonumber),
            "state": "ready",
            "last_seen": ($timestamp | tonumber),
            "base_image": "",
            "image_name": ""
        }}')
    
    if ! echo "$updated_registry" > "$REGISTRY_FILE"; then
        printf "${RED}[ERROR] 레지스트리 등록 실패${NC}\n"
        return 1
    fi
    
    printf "${GREEN}[SUCCESS] 레지스트리 등록 완료${NC}\n"
    return 0
}

# Main clone execution orchestrator (refactored for single responsibility)
# 메인 복제 실행 오케스트레이터 (단일 책임 원칙으로 리팩토링)
execute_clone() {
    local source_info="$1"
    local target_name="$2"
    
    printf "${CYAN}[INFO] $MSG_CLONE_STARTING_EXECUTION${NC}\n"
    
    # Reset rollback variables at start
    ROLLBACK_CREATED_IMAGE=""
    ROLLBACK_CREATED_DIR=""
    ROLLBACK_REGISTRY_ID=""
    
    # Phase 1: Container preparation
    show_clone_progress 1 5 "컨테이너 상태 확인 및 시작"
    if ! execute_container_preparation; then
        execute_rollback 1
        return 1
    fi
    
    # Phase 2: Docker commit
    show_clone_progress 2 5 "Docker 이미지 커밋 실행"
    local new_image_name
    if ! execute_docker_commit "$target_name" new_image_name; then
        execute_rollback 1
        return 1
    fi
    
    # Phase 3: Project structure setup
    show_clone_progress 3 5 "프로젝트 구조 생성"
    local target_dir
    if ! execute_project_setup "$target_name" target_dir; then
        execute_rollback 1
        return 1
    fi
    
    # Phase 4: Configuration update
    show_clone_progress 4 5 "설정 파일 복사 및 수정"
    local new_container_name
    if ! execute_configuration_update "$target_name" "$target_dir" "$new_image_name" new_container_name; then
        execute_rollback 1
        return 1
    fi
    
    # Phase 5: Registry registration
    show_clone_progress 5 5 "레지스트리 등록"
    if ! execute_registry_registration "$target_name"; then
        execute_rollback 1
        return 1
    fi
    
    # Success: Clear rollback tracking (clone completed successfully)
    ROLLBACK_CREATED_IMAGE=""
    ROLLBACK_CREATED_DIR=""
    ROLLBACK_REGISTRY_ID=""
    
    printf "${GREEN}[SUCCESS] $MSG_CLONE_EXECUTION_SUCCESS${NC}\n"
    return 0
}

# Show clone progress
# 복제 진행상황 표시
show_clone_progress() {
    local step="$1"
    local total="$2"
    local message="$3"
    
    echo -e "${CYAN}[${step}/${total}] ${message}${NC}"
}

# Main clone function
# 메인 복제 함수
clone_main() {
    printf "${CYAN}=== $MSG_CLONE_MODULE_TITLE ===${NC}\n"
    echo ""
    
    # 1. Parse arguments
    local source_project="$1"
    local target_name="$2"
    
    if ! parse_clone_arguments "$source_project" "$target_name"; then
        return 1
    fi
    
    # 2. Gather source information
    if ! gather_source_info "$source_project"; then
        printf "${RED}[ERROR] $MSG_CLONE_ERROR_INFO_FAILED${NC}\n"
        return 1
    fi
    
    # 3. Determine target name
    local extracted_name
    if [ -n "$SOURCE_PROJECT_IMAGE" ]; then
        extracted_name=$(extract_project_name "$SOURCE_PROJECT_IMAGE")
    else
        extracted_name=$(extract_project_name "$SOURCE_PROJECT_PATH")
    fi
    
    local final_name
    final_name=$(determine_target_name "$extracted_name" "$target_name")
    
    # 프로젝트 이름 결정 실패 시 종료
    if [ $? -ne 0 ] || [ -z "$final_name" ]; then
        printf "${RED}[ERROR] 유효한 프로젝트 이름을 결정할 수 없습니다${NC}\n"
        return 1
    fi
    
    printf "${GREEN}[INFO] $(printf "$MSG_CLONE_TARGET_NAME" "$final_name")${NC}\n"
    
    # 4. Execute clone
    if ! execute_clone "source_info" "$final_name"; then
        printf "${RED}[ERROR] $MSG_CLONE_ERROR_EXECUTION_FAILED${NC}\n"
        return 1
    fi
    
    # 5. Show completion message
    echo ""
    printf "${GREEN}✅ $MSG_CLONE_COMPLETED${NC}\n"
    printf "${YELLOW}$MSG_CLONE_NEXT_STEPS${NC}\n"
    echo "  cd $final_name"
    echo "  dockit start"
    
    return 0
}

# Execute main function if script is run directly
# 스크립트가 직접 실행되면 메인 함수 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    clone_main "$@"
fi