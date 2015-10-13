#!/usr/bin/env bats

load test_helper

create_version() {
  mkdir -p "${PHPENV_ROOT}/versions/$1"
}

setup() {
  mkdir -p "$PHPENV_TEST_DIR"
  cd "$PHPENV_TEST_DIR"
}

@test "no version selected" {
  assert [ ! -d "${PHPENV_ROOT}/versions" ]
  run phpenv-version-name
  assert_success "system"
}

@test "system version is not checked for existance" {
  PHPENV_VERSION=system run phpenv-version-name
  assert_success "system"
}

@test "PHPENV_VERSION has precedence over local" {
  create_version "1.8.7"
  create_version "1.9.3"

  cat > ".php-version" <<<"1.8.7"
  run phpenv-version-name
  assert_success "1.8.7"

  PHPENV_VERSION=1.9.3 run phpenv-version-name
  assert_success "1.9.3"
}

@test "local file has precedence over global" {
  create_version "1.8.7"
  create_version "1.9.3"

  cat > "${PHPENV_ROOT}/version" <<<"1.8.7"
  run phpenv-version-name
  assert_success "1.8.7"

  cat > ".php-version" <<<"1.9.3"
  run phpenv-version-name
  assert_success "1.9.3"
}

@test "missing version" {
  PHPENV_VERSION=1.2 run phpenv-version-name
  assert_failure "phpenv: version \`1.2' is not installed (set by PHPENV_VERSION environment variable)"
}

@test "version with prefix in name" {
  create_version "1.8.7"
  cat > ".php-version" <<<"php-1.8.7"
  run phpenv-version-name
  assert_success
  assert_output "1.8.7"
}
