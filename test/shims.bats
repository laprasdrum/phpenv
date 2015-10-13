#!/usr/bin/env bats

load test_helper

@test "no shims" {
  run phpenv-shims
  assert_success
  assert [ -z "$output" ]
}

@test "shims" {
  mkdir -p "${PHPENV_ROOT}/shims"
  touch "${PHPENV_ROOT}/shims/php"
  touch "${PHPENV_ROOT}/shims/irb"
  run phpenv-shims
  assert_success
  assert_line "${PHPENV_ROOT}/shims/php"
  assert_line "${PHPENV_ROOT}/shims/irb"
}

@test "shims --short" {
  mkdir -p "${PHPENV_ROOT}/shims"
  touch "${PHPENV_ROOT}/shims/php"
  touch "${PHPENV_ROOT}/shims/irb"
  run phpenv-shims --short
  assert_success
  assert_line "irb"
  assert_line "php"
}
