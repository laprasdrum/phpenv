#!/usr/bin/env bats

load test_helper

create_executable() {
  local bin="${PHPENV_ROOT}/versions/${1}/bin"
  mkdir -p "$bin"
  touch "${bin}/$2"
  chmod +x "${bin}/$2"
}

@test "empty rehash" {
  assert [ ! -d "${PHPENV_ROOT}/shims" ]
  run phpenv-rehash
  assert_success ""
  assert [ -d "${PHPENV_ROOT}/shims" ]
  rmdir "${PHPENV_ROOT}/shims"
}

@test "non-writable shims directory" {
  mkdir -p "${PHPENV_ROOT}/shims"
  chmod -w "${PHPENV_ROOT}/shims"
  run phpenv-rehash
  assert_failure "phpenv: cannot rehash: ${PHPENV_ROOT}/shims isn't writable"
}

@test "rehash in progress" {
  mkdir -p "${PHPENV_ROOT}/shims"
  touch "${PHPENV_ROOT}/shims/.phpenv-shim"
  run phpenv-rehash
  assert_failure "phpenv: cannot rehash: ${PHPENV_ROOT}/shims/.phpenv-shim exists"
}

@test "creates shims" {
  create_executable "1.8" "php"
  create_executable "1.8" "composer"
  create_executable "2.0" "php"
  create_executable "2.0" "phpunit"

  assert [ ! -e "${PHPENV_ROOT}/shims/php" ]
  assert [ ! -e "${PHPENV_ROOT}/shims/rake" ]
  assert [ ! -e "${PHPENV_ROOT}/shims/phpunit" ]

  run phpenv-rehash
  assert_success ""

  run ls "${PHPENV_ROOT}/shims"
  assert_success
  assert_output <<OUT
composer
php
phpunit
OUT
}

@test "removes outdated shims" {
  mkdir -p "${PHPENV_ROOT}/shims"
  touch "${PHPENV_ROOT}/shims/oldshim1"
  chmod +x "${PHPENV_ROOT}/shims/oldshim1"

  create_executable "2.0" "rake"
  create_executable "2.0" "php"

  run phpenv-rehash
  assert_success ""

  assert [ ! -e "${PHPENV_ROOT}/shims/oldshim1" ]
}

@test "do exact matches when removing stale shims" {
  create_executable "2.0" "unicorn_rails"
  create_executable "2.0" "phpunit-core"

  phpenv-rehash

  cp "$PHPENV_ROOT"/shims/{phpunit-core,phpunit}
  cp "$PHPENV_ROOT"/shims/{phpunit-core,rails}
  cp "$PHPENV_ROOT"/shims/{phpunit-core,uni}
  chmod +x "$PHPENV_ROOT"/shims/{phpunit,rails,uni}

  run phpenv-rehash
  assert_success ""

  assert [ ! -e "${PHPENV_ROOT}/shims/rails" ]
  assert [ ! -e "${PHPENV_ROOT}/shims/rake" ]
  assert [ ! -e "${PHPENV_ROOT}/shims/uni" ]
}

@test "binary install locations containing spaces" {
  create_executable "dirname1 p247" "php"
  create_executable "dirname2 preview1" "phpunit"

  assert [ ! -e "${PHPENV_ROOT}/shims/php" ]
  assert [ ! -e "${PHPENV_ROOT}/shims/phpunit" ]

  run phpenv-rehash
  assert_success ""

  run ls "${PHPENV_ROOT}/shims"
  assert_success
  assert_output <<OUT
php
phpunit
OUT
}

@test "carries original IFS within hooks" {
  hook_path="${PHPENV_TEST_DIR}/phpenv.d"
  mkdir -p "${hook_path}/rehash"
  cat > "${hook_path}/rehash/hello.bash" <<SH
hellos=(\$(printf "hello\\tugly world\\nagain"))
echo HELLO="\$(printf ":%s" "\${hellos[@]}")"
exit
SH

  PHPENV_HOOK_PATH="$hook_path" IFS=$' \t\n' run phpenv-rehash
  assert_success
  assert_output "HELLO=:hello:ugly:world:again"
}

@test "sh-rehash in bash" {
  create_executable "2.0" "php"
  PHPENV_SHELL=bash run phpenv-sh-rehash
  assert_success "hash -r 2>/dev/null || true"
  assert [ -x "${PHPENV_ROOT}/shims/php" ]
}

@test "sh-rehash in fish" {
  create_executable "2.0" "php"
  PHPENV_SHELL=fish run phpenv-sh-rehash
  assert_success ""
  assert [ -x "${PHPENV_ROOT}/shims/php" ]
}
