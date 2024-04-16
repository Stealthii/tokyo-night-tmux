#!/usr/bin/env bash

declare -gA GIT_ICONS
# Main providers
GIT_ICONS[github.com]="\ue708"       # nf-dev-github_alt
GIT_ICONS[gitlab.com]="\uf296"       # nf-fa-gitlab
GIT_ICONS[visualstudio.com]="\uebd8" # nf-cod-azure
GIT_ICONS[codeberg.org]="\uf330"     # nf-linux-codeberg
GIT_ICONS[sr.ht]="\Uf0902"           # nf-md-power_off
GIT_ICONS[git.kernel.org]="\ue712"   # nf-dev-linux
GIT_ICONS[gnu.org]="\ue779"          # nf-dev-gnu
GIT_ICONS[debian.org]="\ue77d"       # nf-dev-debian
GIT_ICONS[archlinux.org]="\uf303"    # nf-linux-archlinux
GIT_ICONS[freebsd.org]="\uf30c"      # nf-linux-freebsd
GIT_ICONS[freedesktop.org]="\uf360"  # nf-linux-freedesktop
GIT_ICONS[gnome.org]="\uf361"        # nf-linux-gnome
GIT_ICONS[kde.org]="\uf373"          # nf-linux-kde
# Fuzzy / self-hosted
GIT_ICONS[bitbucket]="\ue703" # nf-dev-bitbucket
GIT_ICONS[stash]="\ue703"     # nf-dev-bitbucket
GIT_ICONS[gitea]="\uf339"     # nf-linux-gitea
# Default
GIT_ICONS[git]="\ue702" # nf-dev-git

function get_provider() {
  echo "$(git remote get-url origin 2>/dev/null | sed -E 's|^(https?://)?([^@]+@)?([^:/]+).*$|\3|')"
}

function get_provider_icon() {
  local provider="$1"
  # Return first matching icon if icon key is in provider
  for key in "${!GIT_ICONS[@]}"; do
    if [[ $provider == *"$key"* ]]; then
      echo -e "${GIT_ICONS[$key]}"
      return
    fi
    # Return default icon if no match
    echo -e "${GIT_ICONS[git]}"
  done
}

export GIT_ICONS
