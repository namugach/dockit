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
    
    # 최종 검증: 선택한 이름이 여전히 충돌하는지 확인
    while [ -d "./$chosen_name" ]; do
        printf "${RED}❌ $(printf "$MSG_CLONE_DIRECTORY_CONFLICT" "$chosen_name")${NC}\n" >&2
        read -p "$(printf "$MSG_CLONE_ENTER_NAME"): " chosen_name
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
    
    printf "${CYAN}[INFO] $MSG_CLONE_DETERMINING_NAME${NC}\n" >&2
    
    if [ -n "$provided_name" ]; then
        # 명령줄에서 이름이 지정된 경우
        echo "$provided_name"
    else
        # 대화형 모드
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

# Execute the actual cloning process
# 실제 복제 프로세스 실행
execute_clone() {
    local source_info="$1"
    local target_name="$2"
    
    printf "${CYAN}[INFO] $MSG_CLONE_STARTING_EXECUTION${NC}\n"
    
    # 1. Ensure container is running
    show_clone_progress 1 5 "컨테이너 상태 확인 및 시작"
    if ! ensure_container_running "$SOURCE_PROJECT_CONTAINER" "$SOURCE_PROJECT_STATE"; then
        printf "${RED}[ERROR] 컨테이너를 시작할 수 없습니다${NC}\n"
        return 1
    fi
    
    # 2. Docker commit with timestamp
    show_clone_progress 2 5 "Docker 이미지 커밋 실행"
    local new_image_name="${SOURCE_PROJECT_IMAGE}:clone-${CLONE_TIMESTAMP}"
    
    printf "${CYAN}[INFO] 새 이미지 생성 중: $new_image_name${NC}\n"
    if ! timeout $DOCKER_COMMIT_TIMEOUT docker commit "$SOURCE_PROJECT_CONTAINER" "$new_image_name"; then
        printf "${RED}[ERROR] Docker commit 실패${NC}\n"
        return 1
    fi
    printf "${GREEN}[SUCCESS] 이미지 커밋 완료${NC}\n"
    
    # 3. Create project structure
    show_clone_progress 3 5 "프로젝트 구조 생성"
    local target_dir="./$target_name"
    
    if ! mkdir -p "$target_dir/.dockit_project"; then
        printf "${RED}[ERROR] 프로젝트 디렉토리 생성 실패${NC}\n"
        return 1
    fi
    
    # 4. Copy and modify configuration files
    show_clone_progress 4 5 "설정 파일 복사 및 수정"
    
    # .dockit_project 폴더 전체 복사 (숨김파일 포함)
    if ! cp -r "$SOURCE_PROJECT_PATH/.dockit_project/." "$target_dir/.dockit_project/"; then
        printf "${RED}[ERROR] 설정 파일 복사 실패${NC}\n"
        return 1
    fi
    
    # .env 파일 수정
    local new_container_name="dockit-$(echo "$(pwd)/$target_name" | sed 's|/|-|g' | sed 's|^-||')"
    local env_file="$target_dir/.dockit_project/.env"
    local compose_file="$target_dir/.dockit_project/docker-compose.yml"
    
    # IMAGE_NAME과 CONTAINER_NAME 업데이트
    sed -i "s|IMAGE_NAME=.*|IMAGE_NAME=\"$new_image_name\"|" "$env_file"
    sed -i "s|CONTAINER_NAME=.*|CONTAINER_NAME=\"$new_container_name\"|" "$env_file"
    
    # docker-compose.yml 파일 수정
    if [ -f "$compose_file" ]; then
        # name 필드 업데이트
        sed -i "s|^name:.*|name: $new_container_name|" "$compose_file"
        
        # image 필드 업데이트 (실제 커밋된 이미지 이름 사용)
        sed -i "s|image:.*|image: $new_image_name|" "$compose_file"
        
        # container_name 필드 업데이트
        sed -i "s|container_name:.*|container_name: $new_container_name|" "$compose_file"
        
        # networks 섹션 업데이트
        sed -i "s|$SOURCE_PROJECT_CONTAINER|$new_container_name|g" "$compose_file"
        
        # labels 섹션 업데이트  
        sed -i "s|com.dockit.project=.*|com.dockit.project=$new_container_name\"|" "$compose_file"
        
        printf "${GREEN}[SUCCESS] docker-compose.yml 파일 수정 완료${NC}\n"
    fi
    
    printf "${GREEN}[SUCCESS] 설정 파일 수정 완료${NC}\n"
    
    # 5. Register in registry
    show_clone_progress 5 5 "레지스트리 등록"
    
    # 새 프로젝트 ID 생성
    local new_project_id=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 64 | head -n 1)
    local new_project_path="$(pwd)/$target_name"
    local current_timestamp=$(date +%s)
    
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
    
    echo "$updated_registry" > "$REGISTRY_FILE"
    
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