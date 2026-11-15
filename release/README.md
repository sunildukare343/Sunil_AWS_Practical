## SBOM and signed artifacts

Tools: Syft v1.57.1, Cosign v3.1.3 (local test key pair).
Image: <REGISTRY>/fbc-consent-api-dev@<digest>, built from commit <commit>.
Note: this exercise was done after the EKS teardown, so the "deployed image reference" is the
digest in the Git deployment manifests (kubernetes/) that Argo CD deployed. <Path B only:> The
image was re-published from commit <commit> and the Git reference updated; a rebuild produces a
new digest because Docker builds are not byte-for-byte reproducible - which is why releases are
deployed and signed by digest, never by tag.

**What is an SBOM?** A list of all software packages inside the image (an inventory).
It is not a vulnerability report - the ECR scan finds vulnerabilities.

**Two components**
| Component | Version | Came from |
|---|---|---|
| openssl | <version> | Base image (python:3.12-slim, Debian package) |
| fastapi | <version> | Our application (app/requirements.txt) |

**How the SBOM helps with a new vulnerability:** when a new CVE is announced (for example in
OpenSSL), we search the SBOM for that package and version. We immediately know if our image
is affected and whether to fix it by rebuilding on a newer base image (OpenSSL) or by updating
requirements.txt (FastAPI).

**Release manifest:** image digest + source commit + SHA-256 hash of the SBOM, signed with Cosign.
The private key (cosign.key) is never committed.

**Verification (scripts/verify-release.sh):**
1. Signature is valid for the public key (else exit 10)
2. SBOM hash equals the hash in the signed manifest (else exit 11)
3. Image digest in the manifest equals the deployed image reference - the live Deployment
   when the cluster exists, otherwise the Git deployment manifest (else exit 12)

Results: original files → VERIFIED (exit 0); changed SBOM copy → exit 11; changed manifest copy → exit 10.

**Where the trusted public key comes from:** the verifier uses cosign.pub from our reviewed Git
repository, not from whoever sends the artifact. If an attacker could replace the public key,
they could sign anything - in production the key would be in AWS KMS, or signing would be
keyless using the CI identity.

**A valid signature does NOT mean the image is safe:**
- It only proves the manifest was signed by our key and not changed afterwards.
- It does not prove the image has no vulnerabilities (new CVEs appear later; scanning is separate).
- It does not prove the build was trustworthy - a compromised build machine or dependency
  would still produce a validly signed image.