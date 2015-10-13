#!/usr/bin/env bats

load test_helper

setup() {
  mkdir -p "$PHPENV_TEST_DIR"
  cd "$PHPENV_TEST_DIR"
}

create_file() {
  mkdir -p "$(dirname "$1")"
  touch "$1"
}

@test "prints global file if no version files exist" {
  assert [ ! -e "${PHPENV_ROOT}/version" ]
  assert [ ! -e ".php-version" ]
  run phpenv-version-file
  assert_success "${PHPENV_ROOT}/version"
}

@test "detects 'global' file" {
  create_file "${PHPENV_ROOT}/global"
  run phpenv-version-file
  assert_success "${PHPENV_ROOT}/global"
}

@test "detects 'default' file" {
  create_file "${PHPENV_ROOT}/default"
  run phpenv-version-file
  assert_success "${PHPENV_ROOT}/default"
}

@test "'version' has precedence over 'global' and 'default'" {
  create_file "${PHPENV_ROOT}/version"
  create_file "${PHPENV_ROOT}/global"
  create_file "${PHPENV_ROOT}/default"
  run phpenv-version-file
  assert_success "${PHPENV_ROOT}/version"
}

@test "in current directory" {
  create_file ".php-version"
  run phpenv-version-file
  assert_success "${PHPENV_TEST_DIR}/.php-version"
}

@test "legacy file in current directory" {
  create_file ".phpenv-version"
  run phpenv-version-file
  assert_success "${PHPENV_TEST_DIR}/.phpenv-version"
}

@test ".php-version has precedence over legacy file" {
  create_file ".php-version"
  create_file ".phpenv-version"
  run phpenv-version-file
  assert_success "${PHPENV_TEST_DIR}/.php-version"
}

@test "in parent directory" {
  create_file ".php-version"
  mkdir -p project
  cd project
  run phpenv-version-file
  assert_success "${PHPENV_TEST_DIR}/.php-version"
}

@test "topmost file has precedence" {
  create_file ".php-version"
  create_file "project/.php-version"
  cd project
  run phpenv-version-file
  assert_success "${PHPENV_TEST_DIR}/project/.php-version"
}

@test "legacy file has precedence if higher" {
  create_file ".php-version"
  create_file "project/.phpenv-version"
  cd project
  run phpenv-version-file
  assert_success "${PHPENV_TEST_DIR}/project/.phpenv-version"
}

@test "PHPENV_DIR has precedence over PWD" {
  create_file "widget/.php-version"
  create_file "project/.php-version"
  cd project
  PHPENV_DIR="${PHPENV_TEST_DIR}/widget" run phpenv-version-file
  assert_success "${PHPENV_TEST_DIR}/widget/.php-version"
}

@test "PWD is searched if PHPENV_DIR yields no results" {
  mkdir -p "widget/blank"
  create_file "project/.php-version"
  cd project
  PHPENV_DIR="${PHPENV_TEST_DIR}/widget/blank" run phpenv-version-file
  assert_success "${PHPENV_TEST_DIR}/project/.php-version"
}
