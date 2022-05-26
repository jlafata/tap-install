#!/bin/bash

set -e
set -u
set -o pipefail

# base everything relative to the directory of this script file
script_dir="$(cd $(dirname "$BASH_SOURCE[0]") && pwd)"

generated_dir="${script_dir}/generated"
mkdir -p "${generated_dir}"

values_file_default="${script_dir}/values.yaml"
values_file=${VALUES_FILE:-$values_file_default}

export INSTALL_REGISTRY_HOSTNAME=registry.tanzu.vmware.com
export INSTALL_REGISTRY_USERNAME=$(yq '.tanzunet.username' < "${values_file}")
export INSTALL_REGISTRY_PASSWORD=$(yq '.tanzunet.password' < "${values_file}")

ytt -f "${script_dir}/view-profile-tap-values.yaml" -f "${values_file}" --ignore-unknown-comments > "${generated_dir}/tap-values.yaml"

tanzu package installed update tap \
  --namespace tap-install \
  --package-name tap.tanzu.vmware.com \
  --version 1.1.0 \
  --values-file "${generated_dir}/tap-values.yaml"


