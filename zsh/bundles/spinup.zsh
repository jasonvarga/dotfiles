#!/usr/bin/env zsh

function spinup-statamic() {
  local usage="Usage: spinup-statamic <site-name> [package-path]"
  if [[ -z "$1" ]]; then
    echo "$usage" >&2
    return 1
  fi
  local site_name="$1"
  local package_path="${2:-$PWD}"
  local herd_dir="$HOME/Sites/Sandboxes"
  local site_path="$herd_dir/$site_name"

  # Resolve workspace to absolute path
  package_path="$(cd "$package_path" && pwd)"

  # Guard against detached HEAD
  local branch
  branch=$(git -C "$package_path" rev-parse --abbrev-ref HEAD)
  if [[ "$branch" == "HEAD" ]]; then
    echo "✗ Workspace is in a detached HEAD state. Check out a branch first."
    return 1
  fi

  # Detect nearest tag reachable from HEAD
  local tag
  tag=$(git -C "$package_path" describe --tags --abbrev=0 2>/dev/null) || {
    echo "✗ No tags found in workspace. Cannot determine version constraint."
    return 1
  }
  tag="${tag#v}"

  local constraint=$(_composer_constraint "$branch" "$tag")

  echo "→ Workspace : $package_path"
  echo "→ Branch    : $branch"
  echo "→ Constraint: $constraint"
  echo "→ Site path : $site_path"
  echo ""

  # Guard against overwriting an existing site
  if [[ -d "$site_path" ]]; then
    echo "✗ Directory already exists: $site_path"
    return 1
  fi

  echo "→ Running: statamic new $site_name (inside $herd_dir)"
  (cd "$herd_dir" && statamic new "$site_name" --no-interaction --quiet)

  # Patch composer.json — add path repo + branch alias constraint
  echo "→ Patching composer.json"
  _patch_composer_json "$site_path/composer.json" "statamic/cms" "$constraint" "$package_path"

  echo "→ Requiring spatie/laravel-ray"
  (cd "$site_path" && composer require spatie/laravel-ray --no-update)

  echo "→ Running composer update"
  (cd "$site_path" && composer update statamic/cms --no-interaction)

  echo "→ Symlinking assets"
  rm "$site_path/public/vendor/statamic/cp"
  mkdir -p "$site_path/public/vendor/statamic"
  ln -s "$package_path/resources/dist" "$site_path/public/vendor/statamic/cp"

  echo "→ Creating user"
  cp "$DOTFILES/statamic/jason@statamic.com.yaml" "$site_path/users/jason@statamic.com.yaml"

  echo ""
  echo "✓ Ready at http://$site_name.test"
}