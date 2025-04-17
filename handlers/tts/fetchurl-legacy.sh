# SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
# SPDX-License-Identifier: Apache-2.0

curl=(
  curl
  --location
  --max-redirs 20
  --retry 3
)

if ! [ -f "$SSL_CERT_FILE" ]; then
    curl+=(--insecure)
fi

"${curl[@]}" "${url}" --output "${out}"