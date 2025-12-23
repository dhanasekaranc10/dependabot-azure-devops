set -euo pipefail

echo "Dependabot started"


REQUIRED_VARS=(
  "ADO_DEPENDABOT_PAT"
  "PROJECT_PATH"
  "PACKAGE_MANAGER"
  "DIRECTORY_PATH"
)


for VAR in "${REQUIRED_VARS[@]}"; do
  if [[ -z "${!VAR:-}" ]]; then
    echo "[ERROR] Required environment variable '$VAR' is not set"
    exit 1
  fi
done


echo "[Dependabot] Configuration:"
echo "  - Package manager : ${PACKAGE_MANAGER}"
echo "  - Project path    : ${PROJECT_PATH}"
echo "  - Directory path  : ${DIRECTORY_PATH}"


export AZURE_ACCESS_TOKEN="${ADO_DEPENDABOT_PAT}"


echo "[Dependabot] Starting dependency update process:"

ruby /app/update.rb


echo "Dependabot Execution completed successfully"
