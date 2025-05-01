#!/bin/bash
set -e

# Check if we received package names from the comment
if [[ -z "$1" ]]; then
  echo "No package names provided."
  exit 1
fi

# Extract the package names from the comment
PACKAGE_NAMES=($@)  # All arguments after /release-beta will be treated as package names
echo "Packages to release: ${PACKAGE_NAMES[@]}"

# Install dependencies and prepare the environment
yarn install
yarn workspaces foreach --all --topological --no-private run build

# Function to increment version for beta releases
increment_beta_version() {
  PACKAGE_NAME=$1
  LATEST_STABLE_VERSION=$(npm view $PACKAGE_NAME version || jq -r .version package.json)
  
  BETA_PATTERN="${LATEST_STABLE_VERSION}-beta."
  LATEST_BETA_VERSION=$(npm view $PACKAGE_NAME versions --json | jq -r '[.[] | select(contains("'"$BETA_PATTERN"'"))] | last')

  if [[ -n "$LATEST_BETA_VERSION" && "$LATEST_BETA_VERSION" != "null" ]]; then
      BETA_NUMBER=$(echo "$LATEST_BETA_VERSION" | sed -E "s/.*-beta\.([0-9]+)$/\1/")
      NEW_BETA_NUMBER=$((BETA_NUMBER + 1))
      NEW_VERSION="${LATEST_STABLE_VERSION}-beta.${NEW_BETA_NUMBER}"
  else
      NEW_VERSION="${LATEST_STABLE_VERSION}-beta.0"
  fi

  echo "Bumping $PACKAGE_NAME to $NEW_VERSION"
  jq --arg new_version "$NEW_VERSION" '.version = $new_version' package.json > package.tmp.json && mv package.tmp.json package.json

  yarn npm publish --tag beta --access public
}

# Loop through each package and release it in the specified order
for PACKAGE in "${PACKAGE_NAMES[@]}"; do
  echo "📦 Processing package: $PACKAGE"
  
  # Navigate to the package directory
  PKG_DIR="packages/$PACKAGE"
  if [[ ! -d "$PKG_DIR" ]]; then
    echo "Package directory $PKG_DIR not found. Skipping."
    continue
  fi

  cd "$PKG_DIR"

  # Increment version and publish as beta
  increment_beta_version "$PACKAGE"

  cd - > /dev/null
done
