#!/usr/bin/env bats

load test_helper

@test "blank invocation" {
  run phpenv
  assert_success
  assert [ "${lines[0]}" = "phpenv 0.4.0" ]
}

@test "invalid command" {
  run phpenv does-not-exist
  assert_failure
  assert_output "phpenv: no such command \`does-not-exist'"
}

@test "default PHPENV_ROOT" {
  PHPENV_ROOT="" HOME=/home/mislav run phpenv root
  assert_success
  assert_output "/home/mislav/.phpenv"
}

@test "inherited PHPENV_ROOT" {
  PHPENV_ROOT=/opt/phpenv run phpenv root
  assert_success
  assert_output "/opt/phpenv"
}

@test "default PHPENV_DIR" {
  run phpenv echo PHPENV_DIR
  assert_output "$(pwd)"
}

@test "inherited PHPENV_DIR" {
  dir="${BATS_TMPDIR}/myproject"
  mkdir -p "$dir"
  PHPENV_DIR="$dir" run phpenv echo PHPENV_DIR
  assert_output "$dir"
}

@test "invalid PHPENV_DIR" {
  dir="${BATS_TMPDIR}/does-not-exist"
  assert [ ! -d "$dir" ]
  PHPENV_DIR="$dir" run phpenv echo PHPENV_DIR
  assert_failure
  assert_output "phpenv: cannot change working directory to \`$dir'"
}

@test "adds its own libexec to PATH" {
  run phpenv echo "PATH"
  assert_success "${BATS_TEST_DIRNAME%/*}/libexec:$PATH"
}

@test "adds plugin bin dirs to PATH" {
  mkdir -p "$PHPENV_ROOT"/plugins/php-build/bin
  mkdir -p "$PHPENV_ROOT"/plugins/phpenv-each/bin
  run phpenv echo -F: "PATH"
  assert_success
  assert_line 0 "${BATS_TEST_DIRNAME%/*}/libexec"
  assert_line 1 "${PHPENV_ROOT}/plugins/phpenv-each/bin"
  assert_line 2 "${PHPENV_ROOT}/plugins/php-build/bin"
}

@test "PHPENV_HOOK_PATH preserves value from environment" {
  PHPENV_HOOK_PATH=/my/hook/path:/other/hooks run phpenv echo -F: "PHPENV_HOOK_PATH"
  assert_success
  assert_line 0 "/my/hook/path"
  assert_line 1 "/other/hooks"
  assert_line 2 "${PHPENV_ROOT}/phpenv.d"
}

@test "PHPENV_HOOK_PATH includes phpenv built-in plugins" {
  run phpenv echo "PHPENV_HOOK_PATH"
  assert_success ":${PHPENV_ROOT}/phpenv.d:${BATS_TEST_DIRNAME%/*}/phpenv.d:/usr/local/etc/phpenv.d:/etc/phpenv.d:/usr/lib/phpenv/hooks"
}
