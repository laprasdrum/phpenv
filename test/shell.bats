#!/usr/bin/env bats

load test_helper

@test "no shell version" {
  mkdir -p "${PHPENV_TEST_DIR}/myproject"
  cd "${PHPENV_TEST_DIR}/myproject"
  echo "1.2.3" > .php-version
  PHPENV_VERSION="" run phpenv-sh-shell
  assert_failure "phpenv: no shell-specific version configured"
}

@test "shell version" {
  PHPENV_SHELL=bash PHPENV_VERSION="1.2.3" run phpenv-sh-shell
  assert_success 'echo "$PHPENV_VERSION"'
}

@test "shell version (fish)" {
  PHPENV_SHELL=fish PHPENV_VERSION="1.2.3" run phpenv-sh-shell
  assert_success 'echo "$PHPENV_VERSION"'
}

@test "shell unset" {
  PHPENV_SHELL=bash run phpenv-sh-shell --unset
  assert_success "unset PHPENV_VERSION"
}

@test "shell unset (fish)" {
  PHPENV_SHELL=fish run phpenv-sh-shell --unset
  assert_success "set -e PHPENV_VERSION"
}

@test "shell change invalid version" {
  run phpenv-sh-shell 1.2.3
  assert_failure
  assert_output <<SH
phpenv: version \`1.2.3' not installed
false
SH
}

@test "shell change version" {
  mkdir -p "${PHPENV_ROOT}/versions/1.2.3"
  PHPENV_SHELL=bash run phpenv-sh-shell 1.2.3
  assert_success 'export PHPENV_VERSION="1.2.3"'
}

@test "shell change version (fish)" {
  mkdir -p "${PHPENV_ROOT}/versions/1.2.3"
  PHPENV_SHELL=fish run phpenv-sh-shell 1.2.3
  assert_success 'setenv PHPENV_VERSION "1.2.3"'
}
