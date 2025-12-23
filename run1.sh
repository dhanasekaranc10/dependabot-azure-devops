#!/usr/bin/env bash
set -euo pipefail

echo " Dependabot Core – Azure DevOps Runner"



: "${AZURE_ACCESS_TOKEN:?Missing AZURE_ACCESS_TOKEN}"
: "${PACKAGE_MANAGER:?Missing PACKAGE_MANAGER}"
: "${PROJECT_PATH:?Missing PROJECT_PATH}"
: "${DIRECTORY_PATH:?Missing DIRECTORY_PATH}"

export AZURE_ACCESS_TOKEN
export DEPENDABOT_SOURCE=azure

cd /dependabot

echo " Running Dependabot"
echo "  Package manager : $PACKAGE_MANAGER"
echo "  Repo            : $PROJECT_PATH"
echo "  Directory       : $DIRECTORY_PATH"

bundle exec ruby bin/run.rb \
  "$PACKAGE_MANAGER" \
  "$PROJECT_PATH" \
  --directory "$DIRECTORY_PATH"

echo "Dependabot finished successfully"
