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
    
    printf "${CYAN}$(printf "$MSG_CLONE_STARTING" "$source_id")${NC}\n"
    
    if [ "$default_name" != "$suggested_name" ]; then
        # 충돌이 있는 경우
        printf "${YELLOW}⚠️  $(printf "$MSG_CLONE_DIRECTORY_EXISTS" "$default_name")${NC}\n"
        printf "${GREEN}💡 $(printf "$MSG_CLONE_SUGGESTED_NAME" "$suggested_name")${NC}\n"
        read -p "$(printf "$MSG_CLONE_ENTER_NAME") (${suggested_name}): " user_input
    else
        # 충돌이 없는 경우
        read -p "$(printf "$MSG_CLONE_ENTER_NAME") (${default_name}): " user_input
    fi
    
    # 사용자 입력이 없으면 suggested_name 사용
    local chosen_name="${user_input:-$suggested_name}"
    
    # 최종 검증: 선택한 이름이 여전히 충돌하는지 확인
    while [ -d "./$chosen_name" ]; do
        printf "${RED}❌ $(printf "$MSG_CLONE_DIRECTORY_CONFLICT" "$chosen_name")${NC}\n"
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

# Gather source project information
# 소스 프로젝트 정보 수집
gather_source_info() {
    local source_project="$1"
    
    printf "${CYAN}[INFO] $MSG_CLONE_GATHERING_INFO${NC}\n"
    
    # 레지스트리에서 프로젝트 정보 조회
    # TODO: Implement registry lookup
    # - Get project path
    # - Get IMAGE_NAME and CONTAINER_NAME
    # - Check container status
    
    printf "${GREEN}[SUCCESS] $MSG_CLONE_INFO_SUCCESS${NC}\n"
    return 0
}

# Determine target project name
# 대상 프로젝트 이름 결정
determine_target_name() {
    local extracted_name="$1"
    local provided_name="$2"
    
    printf "${CYAN}[INFO] $MSG_CLONE_DETERMINING_NAME${NC}\n"
    
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

# Execute the actual cloning process
# 실제 복제 프로세스 실행
execute_clone() {
    local source_info="$1"
    local target_name="$2"
    
    printf "${CYAN}[INFO] $MSG_CLONE_STARTING_EXECUTION${NC}\n"
    
    # TODO: Implement clone execution
    # 1. Ensure container is running
    # 2. Docker commit with timestamp
    # 3. Create project structure
    # 4. Copy and modify configuration files
    # 5. Register in registry
    
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
    local extracted_name="example_project"  # TODO: Extract from actual source
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