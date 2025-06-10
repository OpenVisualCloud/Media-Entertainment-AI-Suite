#!/bin/bash

REPO_DIR="$(readlink -f "$(dirname -- "${BASH_SOURCE[0]}")/..")"
. "${REPO_DIR}/scripts/common.sh"

function git_pass_pre_required()
{
    apt update && \
    apt install --no-install-recommends -y \
        curl \
        gnupg

    mkdir -p "/etc/apt/sources.list.d"
    echo 'deb https://gitsecret.jfrog.io/artifactory/git-secret-deb git-secret main' > "/etc/apt/sources.list.d/git-secret-deb"
    curl https://gitsecret.jfrog.io/artifactory/api/gpg/key/public | apt-key add -

    apt-get update --fix-missing && \
    apt-get install --no-install-recommends -y \
        apt-transport-https \
        ca-certificates \
        software-properties-common \
        git-secret

    grep --silent GPG_TTY "${HOME}/.profile" || echo 'export GPG_TTY=$(tty)' >> "${HOME}/.profile"

    GPG_TTY="$(tty)"
    export GPG_TTY
}


USER_EMAIL="${USER_EMAIL:-$(git -C "${REPO_DIR}" config --global user.email)}"
USER_NAME="$(cut -d'@' -f1 <<< "${USER_EMAIL}")"
USER_NAME="${USER_NAME/./_}"
PASS_PHRASE="${PASS_PHRASE}"

if [[ -z "${PASS_PHRASE}" ]]; then
  gpg --batch --quick-gen-key "${USER_EMAIL}" default default
else
  gpg --batch --passphrase "${PASS_PHRASE}" --quick-gen-key "${USER_EMAIL}" default default
fi

