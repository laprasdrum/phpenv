#!/usr/bin/env bats

load test_helper

create_hook() {
  mkdir -p "$1/$2"
  touch "$1/$2/$3"
}

@test "prints usage help given no argument" {
  run phpenv-hooks
  assert_failure "Usage: phpenv hooks <command>"
}

@test "prints list of hooks" {
  path1="${PHPENV_TEST_DIR}/phpenv.d"
  path2="${PHPENV_TEST_DIR}/etc/phpenv_hooks"
  create_hook "$path1" exec "hello.bash"
  create_hook "$path1" exec "ahoy.bash"
  create_hook "$path1" exec "invalid.sh"
  create_hook "$path1" which "boom.bash"
  create_hook "$path2" exec "bueno.bash"

  PHPENV_HOOK_PATH="$path1:$path2" run phpenv-hooks exec
  assert_success
  assert_output <<OUT
${PHPENV_TEST_DIR}/phpenv.d/exec/ahoy.bash
${PHPENV_TEST_DIR}/phpenv.d/exec/hello.bash
${PHPENV_TEST_DIR}/etc/phpenv_hooks/exec/bueno.bash
OUT
}

@test "supports hook paths with spaces" {
  path1="${PHPENV_TEST_DIR}/my hooks/phpenv.d"
  path2="${PHPENV_TEST_DIR}/etc/phpenv hooks"
  create_hook "$path1" exec "hello.bash"
  create_hook "$path2" exec "ahoy.bash"

  PHPENV_HOOK_PATH="$path1:$path2" run phpenv-hooks exec
  assert_success
  assert_output <<OUT
${PHPENV_TEST_DIR}/my hooks/phpenv.d/exec/hello.bash
${PHPENV_TEST_DIR}/etc/phpenv hooks/exec/ahoy.bash
OUT
}

@test "resolves relative paths" {
  path="${PHPENV_TEST_DIR}/phpenv.d"
  create_hook "$path" exec "hello.bash"
  mkdir -p "$HOME"

  PHPENV_HOOK_PATH="${HOME}/../phpenv.d" run phpenv-hooks exec
  assert_success "${PHPENV_TEST_DIR}/phpenv.d/exec/hello.bash"
}

@test "resolves symlinks" {
  path="${PHPENV_TEST_DIR}/phpenv.d"
  mkdir -p "${path}/exec"
  mkdir -p "$HOME"
  touch "${HOME}/hola.bash"
  ln -s "../../home/hola.bash" "${path}/exec/hello.bash"

  PHPENV_HOOK_PATH="$path" run phpenv-hooks exec
  assert_success "${HOME}/hola.bash"
}
