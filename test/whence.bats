#!/usr/bin/env bats

load test_helper

create_executable() {
  local bin="${PHPENV_ROOT}/versions/${1}/bin"
  mkdir -p "$bin"
  touch "${bin}/$2"
  chmod +x "${bin}/$2"
}

@test "finds versions where present" {
  create_executable "1.8" "php"
  create_executable "1.8" "rake"
  create_executable "2.0" "php"
  create_executable "2.0" "phpunit"

  run phpenv-whence php
  assert_success
  assert_output <<OUT
1.8
2.0
OUT

  run phpenv-whence rake
  assert_success "1.8"

  run phpenv-whence phpunit
  assert_success "2.0"
}
