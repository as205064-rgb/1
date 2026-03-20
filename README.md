# Linux Security Automation Scripts

리눅스 서버의 기본 보안 상태를 점검하고, 간단한 하드닝을 적용하며, 인증 로그를 기반으로 보안 이벤트 리포트를 생성하기 위한 Bash 스크립트 모음입니다.

## Project Overview

이 프로젝트는 다음 3가지 목적을 중심으로 구성되어 있습니다.

- 시스템의 기본 보안 설정 점검
- UFW 기반 기본 방화벽 하드닝 적용
- SSH 및 계정 관련 인증 로그 분석 리포트 생성

보안 실습, 서버 점검 자동화, 포트폴리오용 리눅스 보안 프로젝트 예제로 활용할 수 있습니다.

## Files

### 1. `linux_audit.sh`
리눅스 시스템의 기본 보안 상태를 점검하는 스크립트입니다.

점검 항목:
- SSH root 로그인 허용 여부
- sudo 그룹 사용자 확인
- `/etc/passwd` 권한 점검
- `/etc/shadow` 권한 점검
- UFW 방화벽 상태 확인
- 활성화된 서비스 일부 확인
- 최근 로그인 기록 확인

실행 결과는 `audit_result.txt` 파일로 저장됩니다.

---

### 2. `hardening.sh`
UFW를 이용해 기본적인 방화벽 하드닝을 적용하는 스크립트입니다.

적용 내용:
- 기본 incoming 정책 차단
- 기본 outgoing 정책 허용
- OpenSSH 허용
- UFW 활성화
- 최종 방화벽 상태 출력

실행 결과는 `hardening_result.txt` 파일로 저장됩니다.

> 주의: 이 스크립트는 실제 시스템 설정을 변경합니다.

---

### 3. `log_report.sh`
리눅스 인증 로그(`/var/log/auth.log` 또는 `/var/log/secure`)를 분석하여 일일 보안 이벤트 리포트를 생성하는 스크립트입니다.

분석 항목:
- 실패한 SSH 로그인 상위 IP
- 실패 로그인 시도 대상 계정
- 성공한 SSH 로그인 기록
- 신규 사용자 생성 관련 이벤트
- sudo 사용 내역
- su 전환 이벤트
- root 직접 로그인 여부
- 일일 요약 통계

실행 결과는 `incident_report_YYYYMMDD.txt` 형식으로 저장됩니다.

## Requirements

- Linux environment
- Bash
- sudo privileges
- UFW installed (`hardening.sh` 사용 시)
- `/var/log/auth.log` 또는 `/var/log/secure` 읽기 권한 (`log_report.sh` 사용 시)

Ubuntu/Debian 기준 UFW 설치:
```bash
sudo apt install ufw
