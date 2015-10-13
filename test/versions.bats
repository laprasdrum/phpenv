#!/usr/bin/env bats

load test_helper

create_version() {
  mkdir -p "${PHPENV_ROOT}/versions/$1"
}

setup() {
  mkdir -p "$PHPENV_TEST_DIR"
  cd "$PHPENV_TEST_DIR"
}

stub_system_php() {
  local stub="${PHPENV_TEST_DIR}/bin/php"
  mkdir -p "$(dirname "$stub")"
  touch "$stub" && chmod +x "$stub"
}

@test "no versions installed" {
  stub_system_php
  assert [ ! -d "${PHPENV_ROOT}/versions" ]
  run phpenv-versions
  assert_success "* system (set by ${PHPENV_ROOT}/version)"
}

@test "not even system php available" {
  PATH="$(path_without php)" run phpenv-versions
  assert_failure
  assert_output "Warning: no PHP detected on the system"
}

@test "bare output no versions installed" {
  assert [ ! -d "${PHPENV_ROOT}/versions" ]
  run phpenv-versions --bare
  assert_success ""
}

@test "single version installed" {
  stub_system_php
  create_version "1.9"
  run phpenv-versions
  assert_success
  assert_output <<OUT
* system (set by ${PHPENV_ROOT}/version)
  1.9
OUT
}

@test "single version bare" {
  create_version "1.9"
  run phpenv-versions --bare
  assert_success "1.9"
}

@test "multiple versions" {
  stub_system_php
  create_version "1.8.7"
  create_version "1.9.3"
  create_version "2.0.0"
  run phpenv-versions
  assert_success
  assert_output <<OUT
* system (set by ${PHPENV_ROOT}/version)
  1.8.7
  1.9.3
  2.0.0
OUT
}

@test "indicates current version" {
  stub_system_php
  create_version "1.9.3"
  create_version "2.0.0"
  PHPENV_VERSION=1.9.3 run phpenv-versions
  assert_success
  assert_output <<OUT
  system
* 1.9.3 (set by PHPENV_VERSION environment variable)
  2.0.0
OUT
}

@test "bare doesn't indicate current version" {
  create_version "1.9.3"
  create_version "2.0.0"
  PHPENV_VERSION=1.9.3 run phpenv-versions --bare
  assert_success
  assert_output <<OUT
1.9.3
2.0.0
OUT
}

@test "globally selected version" {
  stub_system_php
  create_version "1.9.3"
  create_version "2.0.0"
  cat > "${PHPENV_ROOT}/version" <<<"1.9.3"
  run phpenv-versions
  assert_success
  assert_output <<OUT
  system
* 1.9.3 (set by ${PHPENV_ROOT}/version)
  2.0.0
OUT
}

@test "per-project version" {
  stub_system_php
  create_version "1.9.3"
  create_version "2.0.0"
  cat > ".php-version" <<<"1.9.3"
  run phpenv-versions
  assert_success
  assert_output <<OUT
  system
* 1.9.3 (set by ${PHPENV_TEST_DIR}/.php-version)
  2.0.0
OUT
}

@test "ignores non-directories under versions" {
  create_version "1.9"
  touch "${PHPENV_ROOT}/versions/hello"

  run phpenv-versions --bare
  assert_success "1.9"
}

@test "lists symlinks under versions" {
  create_version "1.8.7"
  ln -s "1.8.7" "${PHPENV_ROOT}/versions/1.8"

  run phpenv-versions --bare
  assert_success
  assert_output <<OUT
1.8
1.8.7
OUT
}
