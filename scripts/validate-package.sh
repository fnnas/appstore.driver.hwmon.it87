#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <staged-package-dir>" >&2
    exit 2
fi

package_dir=$1
app_archive="${package_dir}/app.tgz"

required_files=(
    "package/manifest:manifest"
    "package/cmd/main:cmd/main"
    "package/cmd/install_init:cmd/install_init"
    "package/cmd/install_callback:cmd/install_callback"
    "package/cmd/upgrade_init:cmd/upgrade_init"
    "package/cmd/upgrade_callback:cmd/upgrade_callback"
    "package/cmd/uninstall_init:cmd/uninstall_init"
    "package/cmd/uninstall_callback:cmd/uninstall_callback"
    "package/cmd/common:cmd/common"
    "package/config/privilege:config/privilege"
    "package/config/resource:config/resource"
    "package/app.tgz:app.tgz"
)

for required_file in "${required_files[@]}"; do
    display_path=${required_file%%:*}
    relative_path=${required_file#*:}
    if [ ! -f "${package_dir}/${relative_path}" ]; then
        echo "Missing required package file: ${display_path}" >&2
        exit 1
    fi
done

tar_entries=$(tar -tzf "$app_archive")

require_tar_entry() {
    local expected_entry=$1

    if ! printf '%s\n' "$tar_entries" | grep -Eq "^${expected_entry}(/|$)"; then
        echo "Missing app.tgz entry: ${expected_entry}" >&2
        exit 1
    fi
}

require_tar_entry "app/ite-it87_6.12.18-trim_3"
require_tar_entry "app/ite-it87_6.18.6-trim-297-amd64"
require_tar_entry "app/ite-it87_6.18.18-trim-427-amd64"
require_tar_entry "app/ite-it87_6.18.18-trim-570-amd64"
require_tar_entry "app/ite-it87_6.18.18-trim-587-amd64"
require_tar_entry "app/ite-it87_6.18.18-trim-717-amd64"
require_tar_entry "app/ite-it87_6.18.18.c788-trim-amd64"
require_tar_entry "ui"

echo "Package layout validated: ${package_dir}"
