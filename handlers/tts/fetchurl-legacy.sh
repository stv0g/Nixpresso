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