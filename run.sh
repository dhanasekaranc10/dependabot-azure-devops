#!/usr/bin/env bash
set -euo pipefail


echo " Dependabot Internal "

required_vars=(
  AZURE_ACCESS_TOKEN
  PACKAGE_MANAGER
  PROJECT_PATH
  DIRECTORY_PATH
)

for var in "${required_vars[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "ERROR: Environment variable '$var' is not set"
    exit 1
  fi
done

echo "Environment variables validated"


export AZURE_ACCESS_TOKEN
export DEPENDABOT_SOURCE="azure"
export DEPENDABOT_PROJECT_PATH="${PROJECT_PATH}"
export DEPENDABOT_DIRECTORY="${DIRECTORY_PATH}"

export BUNDLE_WITHOUT="test:development"


cd /dependabot

echo "Running Dependabot Core from:"
pwd


echo "Starting Dependabot update run"
echo "  - Package manager : ${PACKAGE_MANAGER}"
echo "  - Repo path       : ${PROJECT_PATH}"
echo "  - Directory       : ${DIRECTORY_PATH}"

bundle exec ruby bin/run.rb \
  "${PACKAGE_MANAGER}" \
  "${DEPENDABOT_PROJECT_PATH}" \
  --directory "${DEPENDABOT_DIRECTORY}"

echo Dependabot run completed successfully"
