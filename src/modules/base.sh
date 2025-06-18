#!/bin/bash

# Base Module for Dockit
# 베이스 이미지 관리 모듈

# Load common module first
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Load colors utility
BASE_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BASE_SCRIPT_DIR/../utils/colors.sh"

# Config file paths
CONFIG_DIR="$PROJECT_ROOT/config"
BASE_IMAGE_LIST_FILE="$CONFIG_DIR/base_image_list"
BASE_IMAGE_FILE="$CONFIG_DIR/base_image"

# Load messages
load_messages() {
    if [ -f "$CONFIG_DIR/load.sh" ]; then
        source "$CONFIG_DIR/load.sh"
        load_messages "$LANGUAGE"
    fi
}

# Show usage information
show_usage() {
    echo -e "${CYAN}$MSG_BASE_USAGE_TITLE${NC}"
    echo ""
    echo -e "${YELLOW}$MSG_BASE_USAGE_COMMANDS${NC}"
    echo -e "  $MSG_BASE_USAGE_LIST"
    echo -e "  $MSG_BASE_USAGE_SET"
    echo -e "  $MSG_BASE_USAGE_ADD"
    echo -e "  $MSG_BASE_USAGE_REMOVE"
    echo -e "  $MSG_BASE_USAGE_VALIDATE"
    echo -e "  $MSG_BASE_USAGE_RESET"
    echo ""
    echo -e "${YELLOW}$MSG_BASE_USAGE_EXAMPLES${NC}"
    echo -e "  $MSG_BASE_USAGE_EXAMPLE_LIST"
    echo -e "  $MSG_BASE_USAGE_EXAMPLE_SET"
    echo -e "  $MSG_BASE_USAGE_EXAMPLE_ADD"
    echo -e "  $MSG_BASE_USAGE_EXAMPLE_REMOVE"
}

# Get current base image
get_current_base_image() {
    if [ -f "$BASE_IMAGE_FILE" ]; then
        cat "$BASE_IMAGE_FILE" 2>/dev/null | head -n1 | tr -d ' \n'
    else
        echo "namugach/ubuntu-basic:24.04-kor-deno"
    fi
}

# Convert number to image name
# 번호를 이미지 이름으로 변환
get_image_by_number() {
    local number="$1"
    
    if [ ! -f "$BASE_IMAGE_LIST_FILE" ]; then
        return 1
    fi
    
    # Check if input is a number
    if ! [[ "$number" =~ ^[0-9]+$ ]]; then
        echo "$number"  # Return as is if not a number
        return 0
    fi
    
    local count=0
    while IFS= read -r image; do
        [ -z "$image" ] && continue
        count=$((count + 1))
        
        if [ "$count" -eq "$number" ]; then
            echo "$image"
            return 0
        fi
    done < "$BASE_IMAGE_LIST_FILE"
    
    return 1  # Number not found
}

# List all available base images
list_base_images() {
    echo -e "${CYAN}$MSG_BASE_LIST_TITLE${NC}"
    
    if [ ! -f "$BASE_IMAGE_LIST_FILE" ]; then
        echo -e "${RED}$MSG_BASE_ERROR_LIST_NOT_FOUND${NC}"
        return 1
    fi
    
    local current_image=$(get_current_base_image)
    echo -e "${GREEN}$MSG_BASE_LIST_CURRENT${NC} ${YELLOW}$current_image${NC}"
    echo ""
    
    local count=0
    while IFS= read -r image; do
        [ -z "$image" ] && continue
        count=$((count + 1))
        
        if [ "$image" = "$current_image" ]; then
            printf "  ${GREEN}%2d. * %s${NC} ${CYAN}%s${NC}\n" "$count" "$image" "$MSG_BASE_LIST_CURRENT_MARKER"
        else
            printf "  %2d.   %s\n" "$count" "$image"
        fi
    done < "$BASE_IMAGE_LIST_FILE"
    
    if [ $count -eq 0 ]; then
        echo -e "${YELLOW}$MSG_BASE_LIST_NO_IMAGES${NC}"
    fi
}

# Set base image
set_base_image() {
    local input="$1"
    
    if [ -z "$input" ]; then
        echo -e "${RED}$MSG_BASE_SET_ERROR_NO_IMAGE${NC}"
        echo -e "${YELLOW}$MSG_BASE_SET_USAGE${NC}"
        return 1
    fi
    
    # Convert number to image name if needed
    local new_image
    if [[ "$input" =~ ^[0-9]+$ ]]; then
        new_image=$(get_image_by_number "$input")
        if [ $? -ne 0 ] || [ -z "$new_image" ]; then
            echo -e "${RED}$(printf "$MSG_BASE_SET_ERROR_INVALID_NUMBER" "$input")${NC}"
            echo -e "${YELLOW}$MSG_BASE_SET_USAGE_NUMBER${NC}"
            return 1
        fi
        echo -e "${CYAN}$(printf "$MSG_BASE_SET_SELECTED_NUMBER" "$input" "$new_image")${NC}"
    else
        new_image="$input"
    fi
    
    # Check if image exists in list
    if ! grep -Fxq "$new_image" "$BASE_IMAGE_LIST_FILE" 2>/dev/null; then
        echo -e "${RED}$(printf "$MSG_BASE_SET_ERROR_NOT_FOUND" "$new_image")${NC}"
        return 1
    fi
    
    # Set new base image
    echo "$new_image" > "$BASE_IMAGE_FILE"
    echo -e "${GREEN}$(printf "$MSG_BASE_SET_SUCCESS" "$new_image")${NC}"
}

# Add base image to list
add_base_image() {
    local new_image="$1"
    
    if [ -z "$new_image" ]; then
        echo -e "${RED}$MSG_BASE_ADD_ERROR_NO_IMAGE${NC}"
        echo -e "${YELLOW}$MSG_BASE_ADD_USAGE${NC}"
        return 1
    fi
    
    # Check if image already exists
    if grep -Fxq "$new_image" "$BASE_IMAGE_LIST_FILE" 2>/dev/null; then
        echo -e "${RED}$(printf "$MSG_BASE_ADD_ERROR_DUPLICATE" "$new_image")${NC}"
        return 1
    fi
    
    # Add image to list
    echo "$new_image" >> "$BASE_IMAGE_LIST_FILE"
    echo -e "${GREEN}$(printf "$MSG_BASE_ADD_SUCCESS" "$new_image")${NC}"
}

# Remove base image
remove_base_image() {
    if [ $# -eq 0 ]; then
        echo -e "${RED}$MSG_BASE_REMOVE_ERROR_NO_IMAGE${NC}"
        echo -e "${YELLOW}$MSG_BASE_REMOVE_USAGE${NC}"
        return 1
    fi
    
    if [ ! -f "$BASE_IMAGE_LIST_FILE" ]; then
        echo -e "${RED}$MSG_BASE_ERROR_LIST_NOT_FOUND${NC}"
        return 1
    fi
    
    local current_image=$(get_current_base_image)
    local removed_count=0
    local failed_count=0
    local skipped_count=0
    
    # First pass: convert all numbers to image names
    local images_to_remove=()
    for input in "$@"; do
        local image_to_remove
        if [[ "$input" =~ ^[0-9]+$ ]]; then
            image_to_remove=$(get_image_by_number "$input")
            if [ $? -ne 0 ] || [ -z "$image_to_remove" ]; then
                echo -e "${RED}$(printf "$MSG_BASE_REMOVE_ERROR_INVALID_NUMBER" "$input")${NC}"
                failed_count=$((failed_count + 1))
                continue
            fi
            echo -e "${CYAN}$(printf "$MSG_BASE_REMOVE_SELECTED_NUMBER" "$input" "$image_to_remove")${NC}"
        else
            image_to_remove="$input"
        fi
        images_to_remove+=("$image_to_remove")
    done
    
    # Second pass: process each image
    for image_to_remove in "${images_to_remove[@]}"; do
        # Check if image exists
        if ! grep -Fxq "$image_to_remove" "$BASE_IMAGE_LIST_FILE"; then
            echo -e "${RED}$(printf "$MSG_BASE_REMOVE_ERROR_NOT_FOUND" "$image_to_remove")${NC}"
            failed_count=$((failed_count + 1))
            continue
        fi
        
        # Check if it's the currently selected image
        if [ "$image_to_remove" = "$current_image" ]; then
            echo -e "${YELLOW}$(printf "$MSG_BASE_REMOVE_SKIP_CURRENT" "$image_to_remove")${NC}"
            skipped_count=$((skipped_count + 1))
            continue
        fi
        
        # Remove from list
        grep -Fxv "$image_to_remove" "$BASE_IMAGE_LIST_FILE" > "${BASE_IMAGE_LIST_FILE}.tmp"
        mv "${BASE_IMAGE_LIST_FILE}.tmp" "$BASE_IMAGE_LIST_FILE"
        
        echo -e "${GREEN}$(printf "$MSG_BASE_REMOVE_SUCCESS" "$image_to_remove")${NC}"
        removed_count=$((removed_count + 1))
    done
    
    # Show summary if multiple items were processed
    if [ $# -gt 1 ]; then
        echo ""
        echo -e "${CYAN}$(printf "$MSG_BASE_REMOVE_SUMMARY" "$removed_count" "$skipped_count" "$failed_count")${NC}"
    fi
    
    # Return appropriate exit code
    if [ $removed_count -gt 0 ]; then
        return 0
    else
        return 1
    fi
}

# Validate all base images
validate_base_images() {
    echo -e "${CYAN}$MSG_BASE_VALIDATE_START${NC}"
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}$MSG_BASE_VALIDATE_ERROR_DOCKER${NC}"
        return 1
    fi
    
    if [ ! -f "$BASE_IMAGE_LIST_FILE" ]; then
        echo -e "${RED}$MSG_BASE_ERROR_LIST_NOT_FOUND${NC}"
        return 1
    fi
    
    local failed_count=0
    local total_count=0
    
    while IFS= read -r image; do
        [ -z "$image" ] && continue
        total_count=$((total_count + 1))
        
        echo -e "$(printf "$MSG_BASE_VALIDATE_CHECKING" "$image")"
        
        if ! docker image inspect "$image" &>/dev/null; then
            echo -e "${RED}$(printf "$MSG_BASE_VALIDATE_ERROR_NOT_FOUND" "$image")${NC}"
            failed_count=$((failed_count + 1))
        else
            echo -e "${GREEN}✓${NC} $image"
        fi
    done < "$BASE_IMAGE_LIST_FILE"
    
    if [ $failed_count -eq 0 ]; then
        echo -e "${GREEN}$MSG_BASE_VALIDATE_SUCCESS${NC}"
        return 0
    else
        echo -e "${RED}$(printf "$MSG_BASE_VALIDATE_FAILED" "$failed_count")${NC}"
        return 1
    fi
}

# Reset to default base images
reset_base_images() {
    echo -ne "$MSG_BASE_RESET_CONFIRM"
    read -r confirmation
    
    if [[ ! $confirmation =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}$MSG_BASE_RESET_CANCELLED${NC}"
        return 0
    fi
    
    # Reset base image list
    cat > "$BASE_IMAGE_LIST_FILE" << 'EOF'
namugach/ubuntu-basic:24.04-kor-deno
ubuntu:24.04
ubuntu:22.04
ubuntu:20.04
node:20
node:18
python:3.11
python:3.10
alpine:latest
debian:bookworm
EOF
    
    # Reset current base image
    echo "namugach/ubuntu-basic:24.04-kor-deno" > "$BASE_IMAGE_FILE"
    
    echo -e "${GREEN}$MSG_BASE_RESET_SUCCESS${NC}"
}

# Main function
base_main() {
    if [ $# -eq 0 ]; then
        show_usage
        return 0
    fi
    
    case "$1" in
        "list"|"ls")
            list_base_images
            ;;
        "set")
            set_base_image "$2"
            ;;
        "add")
            add_base_image "$2"
            ;;
        "remove"|"rm")
            shift  # Remove the first argument ("remove" or "rm")
            remove_base_image "$@"
            ;;
        "validate"|"check")
            validate_base_images
            ;;
        "reset")
            reset_base_images
            ;;
        *)
            echo -e "${RED}$(printf "$MSG_BASE_ERROR_UNKNOWN_COMMAND" "$1")${NC}"
            echo ""
            show_usage
            return 1
            ;;
    esac
}

# Execute main function if script is run directly
# 스크립트가 직접 실행되면 메인 함수 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    base_main "$@"
fi 