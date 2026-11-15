#!/usr/bin/env bash
# Verifies the signed release.
#   Check 1: signature of the release manifest (public key)          -> exit 10 if wrong
#   Check 2: SBOM hash matches the hash inside the manifest          -> exit 11 if wrong
#   Check 3: image digest in manifest = deployed image reference     -> exit 12 if wrong
#            (live Deployment if the cluster is reachable, otherwise the
#             image reference in the Git deployment manifests that Argo CD deployed)
#
# Usage: ./scripts/verify-release.sh [manifest-file] [sbom-file]

MANIFEST="${1:-release/release-manifest.json}"
SBOM="${2:-release/sbom.spdx.json}"
BUNDLE="release/release-manifest.bundle"
PUBKEY="release/cosign.pub"

echo "Check 1: signature"
if cosign verify-blob --key "$PUBKEY" --bundle "$BUNDLE" --insecure-ignore-tlog=true "$MANIFEST" >/dev/null 2>&1; then
  echo "  OK - signature is valid"
else
  echo "  FAIL - signature is NOT valid (manifest was changed)"
  exit 10
fi

echo "Check 2: SBOM hash"
EXPECTED_HASH=$(grep -o '"sbom_sha256": *"[^"]*"' "$MANIFEST" | cut -d'"' -f4)
ACTUAL_HASH=$(sha256sum "$SBOM" | cut -d' ' -f1)
if [ "$EXPECTED_HASH" = "$ACTUAL_HASH" ]; then
  echo "  OK - SBOM hash matches"
else
  echo "  FAIL - SBOM hash does NOT match (SBOM was changed)"
  exit 11
fi

echo "Check 3: deployed image reference"
EXPECTED_DIGEST=$(grep -o '"image_digest": *"[^"]*"' "$MANIFEST" | cut -d'"' -f4)
DEPLOYED=$(kubectl -n devops-app get deployment devops-api \
  -o jsonpath='{.spec.template.spec.containers[0].image}' --request-timeout=5s 2>/dev/null)
if [ -n "$DEPLOYED" ]; then
  SOURCE="live Deployment in EKS"
  DEPLOYED_DIGEST="${DEPLOYED##*@}"
else
  SOURCE="Git deployment manifests (kubernetes/)"
  DEPLOYED_DIGEST=$(grep -rhoE 'sha256:[a-f0-9]{64}' kubernetes/ | head -1)
fi
echo "  source: $SOURCE"
if [ -n "$DEPLOYED_DIGEST" ] && [ "$DEPLOYED_DIGEST" = "$EXPECTED_DIGEST" ]; then
  echo "  OK - deployed digest matches: $DEPLOYED_DIGEST"
else
  echo "  FAIL - deployed digest '${DEPLOYED_DIGEST:-none}' is not '$EXPECTED_DIGEST'"
  exit 12
fi

echo "RESULT: VERIFIED"