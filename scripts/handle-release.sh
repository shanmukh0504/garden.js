#!/bin/bash
set -e

COMMIT_EMAIL=$(git log -1 --pretty=format:'%ae')
COMMIT_NAME=$(git log -1 --pretty=format:'%an')

git fetch --tags
git fetch origin main:refs/remotes/origin/main

IS_PR=false
if [[ "$GITHUB_EVENT_NAME" == "issue_comment" ]]; then
  IS_PR=true
fi

if [[ $1 == "beta" ]]; then
  VERSION_BUMP="prerelease"
else
  LAST_COMMIT_MSG=$(git log -1 --pretty=%B)

  if [[ $LAST_COMMIT_MSG == patch:* || $LAST_COMMIT_MSG == chore:* ]]; then
    VERSION_BUMP="patch"
  elif [[ $LAST_COMMIT_MSG == fix:* ]]; then
    VERSION_BUMP="minor"
  elif [[ $LAST_COMMIT_MSG == feat:* ]]; then
    VERSION_BUMP="major"
  else
    echo "Commit message does not match patch, chore, fix, or feat. Skipping publishing."
    exit 0
  fi
fi

echo "Version bump type detected: $VERSION_BUMP"

if [[ "$IS_PR" == "true" && -n "$PR_BRANCH" ]]; then
  git fetch origin "$PR_BRANCH:$PR_BRANCH"
  RAW_CHANGED=$(git diff --name-only origin/main..."$PR_BRANCH" | grep '^packages/' | awk -F/ '{print $2}' | sort -u)
else
  if git describe --tags --abbrev=0 >/dev/null 2>&1; then
    LATEST_TAG=$(git describe --tags --abbrev=0)
    RAW_CHANGED=$(git diff --name-only "$LATEST_TAG"...HEAD | grep '^packages/' | awk -F/ '{print $2}' | sort -u)
  else
    RAW_CHANGED=$(git diff --name-only HEAD~1 | grep '^packages/' | awk -F/ '{print $2}' | sort -u)
  fi
fi

CHANGED=""
for DIR in $RAW_CHANGED; do
  PKG_JSON="packages/$DIR/package.json"
  if [[ -f "$PKG_JSON" ]]; then
    PKG_NAME=$(jq -r .name "$PKG_JSON")
    if [[ "$PKG_NAME" != "null" && -n "$PKG_NAME" ]]; then
      CHANGED+="$PKG_NAME"$'\n'
    fi
  fi
done

CHANGED=$(echo "$CHANGED" | sort -u)

if [[ -z "$CHANGED" ]]; then
  echo "No packages changed. Skipping publish."
  exit 0
fi

TOPO_ORDER=$(yarn workspaces foreach --all --topological --no-private exec node -p "require('./package.json').name" 2>/dev/null | grep '^@' | sed 's/\[//;s/\]://')

declare -A PKG_NAME_TO_DIR
for DIR in packages/*; do
  if [[ -f "$DIR/package.json" ]]; then
    NAME=$(jq -r .name "$DIR/package.json")
    if [[ "$NAME" != "null" && -n "$NAME" ]]; then
      DIR_NAME=$(basename "$DIR")
      PKG_NAME_TO_DIR[$NAME]="$DIR_NAME"
    fi
  fi
done

declare -A REVERSE_DEP_MAP
for PKG in $TOPO_ORDER; do
  PKG_DIR="${PKG_NAME_TO_DIR[$PKG]}"
  if [[ -z "$PKG_DIR" ]]; then
    echo "⚠️ Skipping $PKG: Directory not found in PKG_NAME_TO_DIR"
    continue
  fi

  DEPS=$(jq -r '.dependencies // {} | keys[]' "packages/$PKG_DIR/package.json" 2>/dev/null | grep '^@shanmukh0504/' || true)
  for DEP in $DEPS; do
    if [[ -n "${REVERSE_DEP_MAP[$DEP]}" ]]; then
      REVERSE_DEP_MAP[$DEP]="${REVERSE_DEP_MAP[$DEP]} $PKG"
    else
      REVERSE_DEP_MAP[$DEP]="$PKG"
    fi
  done
done

declare -A SHOULD_PUBLISH
queue=()
for CHG in $CHANGED; do
  SHOULD_PUBLISH[$CHG]=1
  queue+=("$CHG")
done

while [ ${#queue[@]} -gt 0 ]; do
  CURRENT=${queue[0]}
  queue=("${queue[@]:1}")
  for DEP in ${REVERSE_DEP_MAP[$CURRENT]}; do
    if [[ -z "${SHOULD_PUBLISH[$DEP]}" ]]; then
      SHOULD_PUBLISH[$DEP]=1
      queue+=("$DEP")
    fi
  done
done

PUBLISH_ORDER=()
for PKG in $TOPO_ORDER; do
  if [[ ${SHOULD_PUBLISH[$PKG]} == 1 ]]; then
    PUBLISH_ORDER+=("$PKG")
  fi
done

if [[ "$IS_PR" == "true" && -n "$PR_BRANCH" ]]; then
  git checkout $PR_BRANCH
else
  git checkout main
fi
yarn workspaces foreach --all --topological --no-private run build

echo "Publishing in order: ${PUBLISH_ORDER[@]}"

for PKG in "${PUBLISH_ORDER[@]}"; do
  echo ""
  echo "📦 Processing $PKG..."
  PKG_DIR="${PKG_NAME_TO_DIR[$PKG]}"
  cd "packages/$PKG_DIR"

  PACKAGE_NAME=$(jq -r .name package.json)
  LATEST_STABLE_VERSION=$(npm view $PACKAGE_NAME version || jq -r .version package.json)

  if [[ "$VERSION_BUMP" == "prerelease" ]]; then
    NEW_VERSION="${LATEST_STABLE_VERSION}-beta.0"
    yarn npm publish --tag beta --access public
  else
    NEW_VERSION=$(increment_version "$LATEST_STABLE_VERSION" "$VERSION_BUMP")
    git add package.json
    git -c user.email="$COMMIT_EMAIL" \
        -c user.name="$COMMIT_NAME" \
        commit -m "V$NEW_VERSION"
    yarn npm publish --access public
    git tag "$PACKAGE_NAME@$NEW_VERSION"
    git push https://x-access-token:${GH_PAT}@github.com/shanmukh0504/garden.js.git HEAD:main --tags
  fi

  cd - > /dev/null
done

yarn config unset yarnPath
jq 'del(.packageManager)' package.json > temp.json && mv temp.json package.json

if [[ "$IS_PR" != "true" && -n $(git status --porcelain) ]]; then
  git add .
  git -c user.email="$COMMIT_EMAIL" \
      -c user.name="$COMMIT_NAME" \
      commit -m "commit release script and config changes"
  git push https://x-access-token:${GH_PAT}@github.com/shanmukh0504/garden.js.git HEAD:main
fi