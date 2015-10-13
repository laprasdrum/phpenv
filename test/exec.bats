#!/usr/bin/env bats

load test_helper

create_executable() {
  name="${1?}"
  shift 1
  bin="${PHPENV_ROOT}/versions/${PHPENV_VERSION}/bin"
  mkdir -p "$bin"
  { if [ $# -eq 0 ]; then cat -
    else echo "$@"
    fi
  } | sed -Ee '1s/^ +//' > "${bin}/$name"
  chmod +x "${bin}/$name"
}

@test "fails with invalid version" {
  export PHPENV_VERSION="2.0"
  run phpenv-exec php -v
  assert_failure "phpenv: version \`2.0' is not installed (set by PHPENV_VERSION environment variable)"
}

@test "completes with names of executables" {
  export PHPENV_VERSION="2.0"
  create_executable "php" "#!/bin/sh"
  create_executable "phpunit" "#!/bin/sh"

  phpenv-rehash
  run phpenv-completions exec
  assert_success
  assert_output <<OUT
php
phpunit
OUT
}

@test "supports hook path with spaces" {
  hook_path="${PHPENV_TEST_DIR}/custom stuff/phpenv hooks"
  mkdir -p "${hook_path}/exec"
  echo "export HELLO='from hook'" > "${hook_path}/exec/hello.bash"

  export PHPENV_VERSION=system
  PHPENV_HOOK_PATH="$hook_path" run phpenv-exec env
  assert_success
  assert_line "HELLO=from hook"
}

@test "carries original IFS within hooks" {
  hook_path="${PHPENV_TEST_DIR}/phpenv.d"
  mkdir -p "${hook_path}/exec"
  cat > "${hook_path}/exec/hello.bash" <<SH
hellos=(\$(printf "hello\\tugly world\\nagain"))
echo HELLO="\$(printf ":%s" "\${hellos[@]}")"
SH

  export PHPENV_VERSION=system
  PHPENV_HOOK_PATH="$hook_path" IFS=$' \t\n' run phpenv-exec env
  assert_success
  assert_line "HELLO=:hello:ugly:world:again"
}

@test "forwards all arguments" {
  export PHPENV_VERSION="2.0"
  create_executable "php" <<SH
#!$BASH
echo \$0
for arg; do
  # hack to avoid bash builtin echo which can't output '-e'
  printf "  %s\\n" "\$arg"
done
SH

  run phpenv-exec php -w "/path to/php script.rb" -- extra args
  assert_success
  assert_output <<OUT
${PHPENV_ROOT}/versions/2.0/bin/php
  -w
  /path to/php script.rb
  --
  extra
  args
OUT
}

@test "supports php -S <cmd>" {
  export PHPENV_VERSION="2.0"

  # emulate `php -S' behavior
  create_executable "php" <<SH
#!$BASH
if [[ \$1 == "-S"* ]]; then
  found="\$(PATH="\${PHPPATH:-\$PATH}" which \$2)"
  # assert that the found executable has php for shebang
  if head -1 "\$found" | grep php >/dev/null; then
    \$BASH "\$found"
  else
    echo "php: no PHP script found in input (LoadError)" >&2
    exit 1
  fi
else
  echo 'php 2.0 (phpenv test)'
fi
SH

  create_executable "rake" <<SH
#!/usr/bin/env php
echo "hello rake"
SH

  phpenv-rehash
  run php -S rake
  assert_success "hello rake"
}
