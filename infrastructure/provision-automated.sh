#!/usr/bin/env bash
set -euo pipefail

TRIVY_VERSION="0.76.0"

if ! command -v trivy >/dev/null 2>&1 \
  || ! trivy --version | grep -q "Version: ${TRIVY_VERSION}$"; then
  download_dir="$(mktemp -d)"
  (
    cd "${download_dir}"
    base="https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}"
    archive="trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz"
    checksums="trivy_${TRIVY_VERSION}_checksums.txt"
    curl -fsSLO "${base}/${archive}"
    curl -fsSLO "${base}/${checksums}"
    sha256sum --ignore-missing -c "${checksums}"
    tar -xzf "${archive}" trivy
    install -m 0755 trivy /usr/local/bin/trivy
  )
fi

trivy --version
docker volume create registry-data >/dev/null

if docker container inspect registry >/dev/null 2>&1; then
  docker start registry >/dev/null
else
  docker run -d --name registry --restart=always \
    -p 5000:5000 -v registry-data:/var/lib/registry registry:3
fi

venv="/home/vagrant/.venvs/devsecops-lab"
install -d -o vagrant -g vagrant /home/vagrant/.venvs
sudo -u vagrant python3 -m venv "${venv}"
sudo -u vagrant "${venv}/bin/python" -m pip install \
  -r /home/vagrant/devsecops-lab/app/requirements.txt pytest

