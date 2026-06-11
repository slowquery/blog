#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

parse_version() {
  local v="$1"
  echo "$v" | awk -F. '{print $1,$2,$3}'
}

bump_version() {
  local current="$1"
  local level="$2"
  read -r major minor patch <<< "$(parse_version "$current")"
  case "$level" in
    major)
      major=$((major + 1))
      minor=0
      patch=0
      ;;
    minor)
      minor=$((minor + 1))
      patch=0
      ;;
    patch|*)
      patch=$((patch + 1))
      ;;
  esac
  echo "${major}.${minor}.${patch}"
}

read -r pkg_major pkg_minor pkg_patch <<< "$(parse_version "$(node -p "require('./package.json').version")")"
CURRENT="${pkg_major}.${pkg_minor}.${pkg_patch}"

LAST_TAG=""
if LAST_TAG="$(git describe --tags --abbrev=0 --match 'v*' 2>/dev/null)"; then
  TAG_VERSION="${LAST_TAG#v}"
  read -r tag_major tag_minor tag_patch <<< "$(parse_version "$TAG_VERSION")"
  TAG_NUM=$((tag_major * 1000000 + tag_minor * 1000 + tag_patch))
  PKG_NUM=$((pkg_major * 1000000 + pkg_minor * 1000 + pkg_patch))
  if [[ "$TAG_NUM" -gt "$PKG_NUM" ]]; then
    CURRENT="$TAG_VERSION"
  fi
  LOG_RANGE="${LAST_TAG}..HEAD"
else
  LOG_RANGE="HEAD"
fi

BUMP="patch"
if [[ -n "${LOG_RANGE}" ]]; then
  while IFS= read -r subject; do
    [[ -z "$subject" ]] && continue
    if [[ "$subject" =~ BREAKING[[:space:]]CHANGE|^break(\(|:) ]] || [[ "$subject" =~ ^[a-zA-Z]+!(\(|:) ]]; then
      BUMP="major"
      break
    fi
    if [[ "$subject" =~ ^feat(\(|:) ]]; then
      if [[ "$BUMP" != "major" ]]; then
        BUMP="minor"
      fi
    fi
  done < <(git log ${LOG_RANGE} --pretty=format:%s 2>/dev/null || true)
fi

if [[ -n "${LAST_TAG}" ]] && [[ -z "$(git log ${LOG_RANGE} --pretty=format:%s 2>/dev/null || true)" ]]; then
  echo "$CURRENT"
  exit 0
fi

echo "$(bump_version "$CURRENT" "$BUMP")"
