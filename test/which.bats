#!/usr/bin/env bats

load test_helper

create_executable() {
  local bin
  if [[ $1 == */* ]]; then bin="$1"
  else bin="${PHPENV_ROOT}/versions/${1}/bin"
  fi
  mkdir -p "$bin"
  touch "${bin}/$2"
  chmod +x "${bin}/$2"
}

@test "outputs path to executable" {
  create_executable "1.8" "php"
  create_executable "2.0" "phpunit"

  PHPENV_VERSION=1.8 run phpenv-which php
  assert_success "${PHPENV_ROOT}/versions/1.8/bin/php"

  PHPENV_VERSION=2.0 run phpenv-which phpunit
  assert_success "${PHPENV_ROOT}/versions/2.0/bin/phpunit"
}

@test "searches PATH for system version" {
  create_executable "${PHPENV_TEST_DIR}/bin" "kill-all-humans"
  create_executable "${PHPENV_ROOT}/shims" "kill-all-humans"

  PHPENV_VERSION=system run phpenv-which kill-all-humans
  assert_success "${PHPENV_TEST_DIR}/bin/kill-all-humans"
}

@test "searches PATH for system version (shims prepended)" {
  create_executable "${PHPENV_TEST_DIR}/bin" "kill-all-humans"
  create_executable "${PHPENV_ROOT}/shims" "kill-all-humans"

  PATH="${PHPENV_ROOT}/shims:$PATH" PHPENV_VERSION=system run phpenv-which kill-all-humans
  assert_success "${PHPENV_TEST_DIR}/bin/kill-all-humans"
}

@test "searches PATH for system version (shims appended)" {
  create_executable "${PHPENV_TEST_DIR}/bin" "kill-all-humans"
  create_executable "${PHPENV_ROOT}/shims" "kill-all-humans"

  PATH="$PATH:${PHPENV_ROOT}/shims" PHPENV_VERSION=system run phpenv-which kill-all-humans
  assert_success "${PHPENV_TEST_DIR}/bin/kill-all-humans"
}

@test "searches PATH for system version (shims spread)" {
  create_executable "${PHPENV_TEST_DIR}/bin" "kill-all-humans"
  create_executable "${PHPENV_ROOT}/shims" "kill-all-humans"

  PATH="${PHPENV_ROOT}/shims:${PHPENV_ROOT}/shims:/tmp/non-existent:$PATH:${PHPENV_ROOT}/shims" \
    PHPENV_VERSION=system run phpenv-which kill-all-humans
  assert_success "${PHPENV_TEST_DIR}/bin/kill-all-humans"
}

@test "version not installed" {
  create_executable "2.0" "phpunit"
  PHPENV_VERSION=1.9 run phpenv-which phpunit
  assert_failure "phpenv: version \`1.9' is not installed (set by PHPENV_VERSION environment variable)"
}

@test "no executable found" {
  create_executable "1.8" "phpunit"
  PHPENV_VERSION=1.8 run phpenv-which rake
  assert_failure "phpenv: rake: command not found"
}

@test "executable found in other versions" {
  create_executable "1.8" "php"
  create_executable "1.9" "phpunit"
  create_executable "2.0" "phpunit"

  PHPENV_VERSION=1.8 run phpenv-which phpunit
  assert_failure
  assert_output <<OUT
phpenv: phpunit: command not found

The \`phpunit' command exists in these PHP versions:
  1.9
  2.0
OUT
}

@test "carries original IFS within hooks" {
  hook_path="${PHPENV_TEST_DIR}/phpenv.d"
  mkdir -p "${hook_path}/which"
  cat > "${hook_path}/which/hello.bash" <<SH
hellos=(\$(printf "hello\\tugly world\\nagain"))
echo HELLO="\$(printf ":%s" "\${hellos[@]}")"
exit
SH

  PHPENV_HOOK_PATH="$hook_path" IFS=$' \t\n' PHPENV_VERSION=system run phpenv-which anything
  assert_success
  assert_output "HELLO=:hello:ugly:world:again"
}

@test "discovers version from phpenv-version-name" {
  mkdir -p "$PHPENV_ROOT"
  cat > "${PHPENV_ROOT}/version" <<<"1.8"
  create_executable "1.8" "php"

  mkdir -p "$PHPENV_TEST_DIR"
  cd "$PHPENV_TEST_DIR"

  PHPENV_VERSION= run phpenv-which php
  assert_success "${PHPENV_ROOT}/versions/1.8/bin/php"
}
