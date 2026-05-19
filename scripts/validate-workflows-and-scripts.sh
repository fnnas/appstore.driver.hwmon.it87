#!/usr/bin/env bash
set -euo pipefail

package_scripts=(
  package/cmd/main
  package/cmd/install_init
  package/cmd/install_callback
  package/cmd/upgrade_init
  package/cmd/upgrade_callback
  package/cmd/uninstall_init
  package/cmd/uninstall_callback
)

package_common_scripts=(
  package/cmd/common
)

script_files=()
if [[ -d scripts ]]; then
  while IFS= read -r script_file; do
    script_files+=("${script_file}")
  done < <(find scripts -maxdepth 1 -type f -name "*.sh" | sort)
fi

shell_files=("${package_scripts[@]}" "${package_common_scripts[@]}" "${script_files[@]}")

print_step() {
  printf '\n==> %s\n' "$1"
}

require_tool() {
  local tool_name=$1
  local install_hint=$2

  if ! command -v "${tool_name}" >/dev/null 2>&1; then
    printf 'Missing required tool: %s\n' "${tool_name}" >&2
    printf 'Install %s before running this validator. %s\n' "${tool_name}" "${install_hint}" >&2
    exit 127
  fi
}

print_step "Checking required validation tools"
require_tool shellcheck "For GitHub Actions, install shellcheck before invoking this script; locally use your package manager, for example apt-get install shellcheck."

print_step "Checking Bash syntax with bash -n"
bash -n "${shell_files[@]}"

print_step "Running ShellCheck static analysis"
shellcheck "${shell_files[@]}"

print_step "Workflow and shell validation completed"
