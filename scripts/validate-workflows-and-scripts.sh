#!/usr/bin/env bash
set -euo pipefail

package_scripts=(
  package/cmd/main
  package/cmd/build_module_chroot
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

translation_files=(
  package/i18n/en
  package/i18n/zh
  package/i18n/ja-JP
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
shellcheck -P SCRIPTDIR "${shell_files[@]}"

translation_schema() {
  awk '
    { sub(/\r$/, "") }
    /^[[:space:]]*$/ { next }
    /^\[[a-z_]+\]$/ { section = substr($0, 2, length($0) - 2); next }
    /^[a-z_][a-z0-9_]*=".+"$/ {
      key = section "." substr($0, 1, index($0, "=") - 1)
      if (section == "" || seen[key]++) {
        print "Invalid or duplicate translation key: " key > "/dev/stderr"
        exit 1
      }
      print key ":" gsub(/%s/, "%s")
      next
    }
    { print "Invalid translation line: " $0 > "/dev/stderr"; exit 1 }
  ' "$1" | sort
}

print_step "Checking translation keys and parameters"
english_schema=$(translation_schema package/i18n/en)
for translation_file in "${translation_files[@]:1}"; do
  localized_schema=$(translation_schema "$translation_file")
  if [[ "$english_schema" != "$localized_schema" ]]; then
    echo "Translation keys or parameters differ from English: ${translation_file}" >&2
    diff -u <(printf '%s\n' "$english_schema") <(printf '%s\n' "$localized_schema") || true
    exit 1
  fi
done

translation_keys=$(printf '%s\n' "$english_schema" | cut -d: -f1)
template_references=$(grep -hoE '\$\{[a-z_]+\.[a-z_]+\}' package/manifest package/wizard/install | sed 's/^${//; s/}$//')
runtime_references=$(grep -hoE '(report_error|i18n_message) [a-z_][a-z0-9_]*' "${package_scripts[@]}" "${package_common_scripts[@]}" | awk '{ print "runtime." $2 }')
while IFS= read -r translation_key; do
  if ! grep -Fxq "$translation_key" <<<"$translation_keys"; then
    echo "Missing translation key: ${translation_key}" >&2
    exit 1
  fi
done < <(printf '%s\n' "$template_references" "$runtime_references" | sort -u)

print_step "Checking translated kernel support lists"
english_kernels=$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+(\.c[0-9]+)?-trim#[0-9]+' package/i18n/en | sort)
for translation_file in "${translation_files[@]:1}"; do
  localized_kernels=$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+(\.c[0-9]+)?-trim#[0-9]+' "$translation_file" | sort)
  if [[ "$english_kernels" != "$localized_kernels" ]]; then
    echo "Kernel support list differs from English: ${translation_file}" >&2
    exit 1
  fi
done

print_step "Workflow and shell validation completed"
