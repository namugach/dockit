# 개발 및 디버깅 도구

이 디렉토리에는 dockit 프로젝트의 개발 및 디버깅을 위한 유틸리티 스크립트들이 포함되어 있습니다.
일반 사용자는 이 파일들을 사용할 필요가 없으며, 개발자와 기여자를 위한 도구입니다.

## 포함된 도구

### config_test.sh

설정 시스템(config)이 올바르게 작동하는지 테스트하는 스크립트입니다.
다음 항목들을 검사합니다:

- 설정 파일 존재 여부 확인
- 다국어 메시지 파일 확인
- 설정 변수 로드 테스트
- 메시지 출력 함수 테스트
- 템플릿 처리 함수 테스트

사용법:
```bash
./src/dev/config_test.sh
```

### debug.sh

현재 설정 정보를 출력하는 간단한 디버깅 스크립트입니다.
다음 정보들을 확인할 수 있습니다:

- 현재 선택된 언어 및 관련 설정
- 베이스 이미지 및 로케일 설정
- 다국어 메시지 샘플 출력
- Dockerfile 템플릿 경로 확인

사용법:
```bash
./src/dev/debug.sh
```

## 개발자 참고사항

이 스크립트들은 시스템 설정 파일(`config/system.sh`)을 로드하므로, 
해당 파일이 존재하고 올바른 형식이어야 합니다.
디버깅 중에 오류가 발생할 경우 `config/settings.env` 파일과 
`config/messages` 디렉토리의 메시지 파일들을 확인하세요. 

# 모듈 테스트 프레임워크 (Module Test Framework)

이 디렉토리는 Dockit 프로젝트의 모듈 테스트 프레임워크를 포함하고 있습니다.

## 개요

모듈 테스트 프레임워크는 각 모듈의 기능을 독립적으로 테스트할 수 있게 해주는 도구입니다. 이 프레임워크는 다음과 같은 장점을 제공합니다:

- 일관된 테스트 환경 제공
- 중복 코드 제거
- 테스트 결과 추적 및 요약
- 모듈별 테스트 격리

## 사용법

### 1. 테스트 실행

특정 모듈의 테스트를 실행하려면 다음 명령을 사용합니다:

```bash
./src/dev/module_test.sh [모듈명]
```

예를 들면:

```bash
./src/dev/module_test.sh migrate   # 마이그레이션 모듈 테스트
./src/dev/module_test.sh status    # 상태 확인 모듈 테스트
```

### 2. 새 모듈 테스트 추가

새로운 모듈에 대한 테스트를 추가하려면:

1. `src/dev/[모듈명]_test.sh` 파일을 생성합니다.
2. 다음 함수들을 구현합니다:
   - `setup_[모듈명]_test()`: 테스트 환경을 설정
   - `test_[기능명]()`: 각 테스트 케이스 구현
   - `run_module_tests()`: 모든 테스트 케이스 실행
   - `cleanup_test()` (선택적): 테스트 후 정리 작업 수행

### 3. 테스트 파일 템플릿

새 모듈 테스트 파일의 기본 형식:

```bash
#!/bin/bash

# [모듈명]_test.sh - [모듈 설명] 테스트

# 테스트 설정
setup_[모듈명]_test() {
    log_info "[모듈명] 테스트 환경 설정 중..."
    
    # 테스트 환경 설정 코드
    
    log_info "[모듈명] 테스트 환경 설정 완료"
}

# 테스트 케이스 1
test_[기능1]() {
    # 테스트 코드
    
    # 결과 확인
    if [ 조건 ]; then
        log_info "성공: [성공 메시지]"
        return 0
    else
        log_error "실패: [실패 메시지]"
        return 1
    fi
}

# 테스트 케이스 2
test_[기능2]() {
    # 테스트 코드
    
    # 결과 확인
    if [ 조건 ]; then
        log_info "성공: [성공 메시지]"
        return 0
    else
        log_error "실패: [실패 메시지]"
        return 1
    fi
}

# 모듈 테스트 실행
run_module_tests() {
    # 테스트 환경 설정
    setup_[모듈명]_test
    
    # 테스트 케이스 실행
    run_test "[기능1] 테스트" test_[기능1]
    run_test "[기능2] 테스트" test_[기능2]
}

# 테스트 정리 작업 (선택적)
cleanup_test() {
    # 테스트 정리 코드
}

# 스크립트가 직접 실행될 때 테스트 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "이 파일은 module_test.sh를 통해 실행해야 합니다."
    echo "예: ./src/dev/module_test.sh [모듈명]"
    exit 1
fi
```

## 유의사항

1. 테스트 파일은 반드시 `module_test.sh`를 통해 실행되어야 합니다.
2. 모의 함수(mocking)를 사용해 외부 의존성을 제거하세요.
3. 테스트가 완료되면 `cleanup_test()` 함수를 구현하여 테스트 후 정리 작업을 수행하세요.
4. 각 테스트 케이스는 독립적으로 실행 가능해야 합니다.

## 예제

현재 구현된 테스트 예제:

- `migrate_test.sh`: 마이그레이션 모듈 테스트
- `status_test.sh`: 상태 확인 모듈 테스트

이 예제들을 참고하여 새로운 모듈 테스트를 작성하세요. 