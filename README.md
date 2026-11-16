# Deploy an Application on Amazon EKS

**DevOps Practical Assessment**

GitHub repository: https://github.com/sunildukare343/Sunil_AWS_Practical

## 1. Project overview

This project demonstrates how to build and deploy a Python FastAPI application with a PostgreSQL database on Amazon Elastic Kubernetes Service (EKS).

The project uses:

- Terraform to provision AWS infrastructure.
- Docker to package the FastAPI application.
- Amazon Elastic Container Registry (ECR) to store the container image.
- Amazon EKS and Kubernetes to run the application and database.
- Argo CD to deploy Kubernetes manifests from Git.
- GitHub Actions to run CI and publish the image.
- GitHub Actions OpenID Connect (OIDC) to obtain temporary AWS credentials.
- Syft and Cosign for the SBOM and signed-artifact learning exercise.
- Trivy for container image vulnerability scanning.

The infrastructure was deployed and tested as part of the practical assessment. The EKS infrastructure was subsequently destroyed to avoid ongoing AWS charges. The ECR repository was intended to be retained; check that the repository and image still exist before running the image-based exercises.

## 2. Project status and important notes

| Area | Recorded status |
|---|---|
| Terraform infrastructure | Provisioned and tested; later destroyed for cost control |
| FastAPI application and Docker image | Built and tested |
| Amazon ECR | Repository created; verify that the image is still available |
| EKS application deployment | Deployed and tested before cleanup |
| PostgreSQL persistence | Tested using an EBS-backed PVC |
| Argo CD GitOps | Configured and tested before cleanup |
| GitHub Actions CI | Successful pipeline run recorded |
| AWS authentication for CI | GitHub OIDC role configured |
| Security fundamentals | Documented and tested as described in the assessment |
| Container vulnerability scan | Trivy scan procedure included in the assessment |
| Database backup and restore | Backup restored into a local PostgreSQL Docker container |
| SBOM and Cosign signing | Learning exercise instructions are included; record completion only after running and verifying the commands |

**Cost note:** EKS is not an always-free service. The EKS cluster and related infrastructure were deleted after testing to avoid ongoing charges. Do not assume the cluster currently exists. The commands that require a live cluster are for reference and must only be run after intentionally recreating the infrastructure.

## 3. Technology stack

| Area | Technology |
|---|---|
| Cloud | AWS |
| Infrastructure as Code | Terraform |
| Containerization | Docker |
| Container registry | Amazon ECR |
| Kubernetes | Amazon EKS |
| Application | Python, FastAPI |
| Database | PostgreSQL |
| CI | GitHub Actions |
| CD / GitOps | Argo CD |
| Source control | Git, GitHub |
| CI authentication | GitHub Actions OIDC |
| Persistent storage | Amazon EBS, gp3 |
| Image scanning | Trivy |
| SBOM generation | Syft |
| Artifact signing | Cosign |

## 4. Repository layout

The repository contains the application, infrastructure, Kubernetes configuration, CI workflow, and supporting scripts. The exact contents can be checked with `tree -a -I '.git|.terraform|__pycache__'`.

A typical layout is:

```text
Sunil_AWS_Practical/
├── app/                       # FastAPI application source
├── terraform/                 # Terraform infrastructure configuration
├── kubernetes/                # Kubernetes manifests
├── .github/
│   └── workflows/
│       └── ci.yml             # GitHub Actions CI workflow
├── scripts/                   # Operational and verification scripts
├── database-backups/          # Local database backup (do not commit)
├── release/                   # SBOM and signed release artifacts
├── Dockerfile
├── .dockerignore
├── .gitignore
└── README.md
```

This is an illustrative layout. Keep the paths in this README aligned with the actual repository files.

## 5. Prerequisites

Install or configure the following tools on the workstation:

- Git
- AWS CLI v2
- Terraform
- Docker Engine
- kubectl
- Syft
- Cosign
- Trivy (for image vulnerability scanning)

Python and the project dependencies are also required to run application tests.

On AlmaLinux, common utilities can be installed with:

```bash
sudo dnf install -y curl wget git tar gzip unzip
```

Docker, AWS CLI, Syft, Terraform, kubectl, Trivy, and Cosign can be installed using their official installation instructions. Verify each installation:

```bash
git --version
aws --version
terraform version
docker --version
kubectl version --client
syft version
cosign version
trivy --version
```

Not every command is required for every section. For example, a local SBOM can be generated with Syft without Terraform or kubectl.

## 6. AWS configuration

The assessment used:

```bash
export AWS_REGION="us-east-1"
export AWS_ACCOUNT_ID="057241186497"
export ECR_REPOSITORY="fbc-consent-api-dev"
export ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
```

Check the active AWS identity before running AWS commands:

```bash
aws sts get-caller-identity
```

The returned account should be the account you intend to use. Do not put AWS access keys in this repository.

### Check the ECR repository

```bash
aws ecr describe-repositories \
  --region "$AWS_REGION" \
  --repository-names "$ECR_REPOSITORY"
```

List images:

```bash
aws ecr describe-images \
  --region "$AWS_REGION" \
  --repository-name "$ECR_REPOSITORY" \
  --query 'imageDetails[*].[imageTags,imageDigest,imagePushedAt]' \
  --output table
```

If the repository or image is missing, stop and confirm the correct account, region, repository name, and image retention status before continuing.

## 7. Infrastructure provisioning with Terraform

The AWS infrastructure for the assessment was provisioned using Terraform. The configuration included:

- EKS cluster and managed node group.
- IAM roles and permissions.
- VPC networking, subnets, routing, and security groups.
- ECR repository.
- EBS CSI driver and persistent storage support.

From the Terraform directory, use the commands appropriate to the repository:

```bash
terraform fmt -recursive
terraform init
terraform validate
terraform plan
```

Review the plan carefully before applying:

```bash
terraform apply
```

After testing, remove resources only when the assessment evidence and required backups have been saved:

```bash
terraform destroy
```

**Important:** The EKS infrastructure was already destroyed after the original assessment run to control costs. Do not run `terraform apply` unless you intentionally want to recreate billable AWS resources and have checked the account's budget and permissions.

## 8. Build and publish the application image

Build the application image from the repository root. Replace the tag with the tag or commit identifier used by your workflow:

```bash
docker build -t fbc-consent-api-dev:local .
```

Run the local image only after confirming the application's required environment variables and database settings:

```bash
docker images
```

Authenticate to ECR:

```bash
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "$ECR_REGISTRY"
```

Tag and push an image when a new publish is required:

```bash
export IMAGE_TAG="$(git rev-parse --short HEAD)"

docker tag fbc-consent-api-dev:local \
  "$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG"

docker push "$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG"
```

Retrieve the immutable digest after the push:

```bash
aws ecr describe-images \
  --region "$AWS_REGION" \
  --repository-name "$ECR_REPOSITORY" \
  --image-ids imageTag="$IMAGE_TAG" \
  --query 'imageDetails[0].imageDigest' \
  --output text
```

Use the digest, rather than a mutable tag such as `latest`, when recording and deploying a release.

### Previously recorded image

The assessment records this image digest:

```text
sha256:308a61e7839a533d899a8e7ac124e743658281289443913ad616ab0ae0a8845b
```

The associated source commit recorded during the CI exercise was:

```text
ed5e3df7a47a3b99ddb54d28bf8aa754155966b2
```

Verify that this digest still exists in ECR before using it:

```bash
export IMAGE_DIGEST="sha256:308a61e7839a533d899a8e7ac124e743658281289443913ad616ab0ae0a8845b"
export IMAGE="$ECR_REGISTRY/$ECR_REPOSITORY@$IMAGE_DIGEST"

aws ecr describe-images \
  --region "$AWS_REGION" \
  --repository-name "$ECR_REPOSITORY" \
  --image-ids imageDigest="$IMAGE_DIGEST"
```

## 9. Deploy to Amazon EKS

This section describes the deployment procedure used during the assessment. It requires a running EKS cluster and valid AWS permissions. The original cluster has since been deleted.

Set the cluster name and update kubeconfig:

```bash
export EKS_CLUSTER_NAME="fbc-eks-dev-use1"

aws eks update-kubeconfig \
  --region "$AWS_REGION" \
  --name "$EKS_CLUSTER_NAME"
```

Check the cluster connection:

```bash
kubectl get nodes
```

Create the application namespace:

```bash
kubectl apply -f kubernetes/namespace.yaml
```

Create the PostgreSQL credentials as a Kubernetes Secret. Use your own secure values; do not copy real passwords into documentation or Git:

```bash
kubectl create secret generic postgres-secret \
  --namespace devops-app \
  --from-literal=username='YOUR_DB_USER' \
  --from-literal=password='YOUR_DB_PASSWORD'
```

Apply the Kubernetes resources:

```bash
kubectl apply -f kubernetes/
```

Check the resources:

```bash
kubectl get deployments,statefulsets,services,pods,pvc -n devops-app
```

The assessment deployed PostgreSQL as a single-replica StatefulSet with an EBS-backed persistent volume claim.

### API endpoints

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/` | Basic application response |
| GET | `/health` | Application health check |
| GET | `/ready` | Application and database readiness |
| POST | `/records` | Create a database record |
| GET | `/records` | Retrieve database records |

For local access through port-forwarding:

```bash
kubectl port-forward -n devops-app \
  service/devops-api 8000:8000
```

In another terminal:

```bash
curl -i http://localhost:8000/
curl -i http://localhost:8000/health
curl -i http://localhost:8000/ready
```

The Service name and port must match the manifests in the repository.

## 10. Argo CD and GitOps

Argo CD was installed in its own namespace and configured to monitor this GitHub repository:

- Repository: `https://github.com/sunildukare343/Sunil_AWS_Practical`
- Branch: `main`
- Manifest path: `kubernetes`
- Destination namespace: `devops-app`

The intended workflow is:

1. Make a Kubernetes configuration change in Git.
2. Commit and push the change.
3. Argo CD detects the updated Git revision.
4. Argo CD synchronizes the desired state to the cluster.
5. Check the application sync and health status.

To inspect Argo CD when the cluster is running:

```bash
kubectl get pods -n argocd
kubectl get applications -n argocd
```

For local dashboard access:

```bash
kubectl port-forward svc/argocd-server \
  -n argocd 8080:443
```

Then open `https://localhost:8080`.

Do not expose the Argo CD administration interface publicly for this lab. Do not commit Argo CD passwords or repository credentials.

## 11. GitHub Actions CI and AWS OIDC

The GitHub Actions workflow is located at:

```text
.github/workflows/ci.yml
```

The workflow was configured to:

1. Run application tests.
2. Check Terraform formatting and configuration.
3. Build and validate Kubernetes manifests.
4. Build the Docker image.
5. Authenticate to AWS using GitHub Actions OIDC.
6. Push the image to ECR.
7. Record image release information, including its digest.

The configured IAM role was:

```text
GitHubActionsECRPushRole
```

OIDC allows GitHub Actions to assume an AWS IAM role and receive temporary credentials. This avoids storing long-lived AWS access keys in GitHub repository secrets.

Check the Actions tab in the GitHub repository for workflow run results.

## 12. Security practices

The project covers the following security practices:

- Keep AWS credentials, database passwords, private keys, Terraform state, and kubeconfig files out of Git.
- Use Kubernetes Secrets for runtime database credentials.
- Use GitHub Actions OIDC instead of long-lived AWS access keys.
- Restrict EKS API access to approved administration networks.
- Keep PostgreSQL on an internal Kubernetes Service.
- Use Kubernetes RBAC to grant only required permissions.
- Scan container images for known vulnerabilities with Trivy.

Example RBAC checks (these require a reachable cluster and an identity with permission to impersonate the service account):

```bash
kubectl auth can-i get pods \
  -n devops-app \
  --as=system:serviceaccount:devops-app:devops-readonly

kubectl auth can-i delete pods \
  -n devops-app \
  --as=system:serviceaccount:devops-app:devops-readonly
```

Expected results for the read-only role are `yes` for listing/reading permitted resources and `no` for deleting Pods.

### Trivy image scan

After confirming that the image exists and authenticating to ECR:

```bash
trivy image "$IMAGE"
trivy image --severity HIGH,CRITICAL "$IMAGE"
```

Save reports:

```bash
mkdir -p security-artifacts

trivy image --format table "$IMAGE" \
  > security-artifacts/trivy-report.txt

trivy image --format json \
  --output security-artifacts/trivy-report.json \
  "$IMAGE"
```

Review affected package names, installed versions, severity, and fixed versions. An SBOM is a component inventory; it is not a vulnerability report.

## 13. SBOM and signed artifacts

This learning exercise uses Syft to generate an SPDX JSON SBOM and Cosign to sign a release manifest. It uses the exact ECR image digest recorded for the release.

### 13.1 Set the image reference

```bash
export AWS_REGION="us-east-1"
export AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
export ECR_REPOSITORY="fbc-consent-api-dev"
export ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
export IMAGE_DIGEST="sha256:308a61e7839a533d899a8e7ac124e743658281289443913ad616ab0ae0a8845b"
export IMAGE="$ECR_REGISTRY/$ECR_REPOSITORY@$IMAGE_DIGEST"
export SOURCE_COMMIT="ed5e3df7a47a3b99ddb54d28bf8aa754155966b2"
```

Confirm the image exists:

```bash
aws ecr describe-images \
  --region "$AWS_REGION" \
  --repository-name "$ECR_REPOSITORY" \
  --image-ids imageDigest="$IMAGE_DIGEST"
```

Authenticate Docker to ECR:

```bash
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "$ECR_REGISTRY"
```

### 13.2 Generate the SBOM

Create the output directory and generate an SPDX JSON SBOM:

```bash
mkdir -p release scripts

syft scan "registry:$IMAGE" \
  -o spdx-json=release/sbom.spdx.json
```

Review the generated file:

```bash
ls -lh release/sbom.spdx.json
syft scan "registry:$IMAGE" -o table \
  > release/sbom-table.txt
```

Review the actual component names and versions:

```bash
cat release/sbom-table.txt
```

Choose at least two components from the real output. Record their exact versions and determine whether each comes from the base image or the application dependencies. Do not copy example versions without checking the generated SBOM.

An SBOM is an inventory of software components and their versions. If a new vulnerability is announced, the SBOM can help identify whether the affected component is present in the image.

### 13.3 Create the release manifest

Calculate the SBOM SHA-256 hash:

```bash
SBOM_HASH="$(sha256sum release/sbom.spdx.json | awk '{print $1}')"
```

Create the manifest:

```bash
python3 - <<'PY'
import json
import os

manifest = {
    "image": os.environ["IMAGE"],
    "image_digest": os.environ["IMAGE_DIGEST"],
    "source_commit": os.environ["SOURCE_COMMIT"],
    "sbom_file": "sbom.spdx.json",
    "sbom_sha256": os.environ["SBOM_HASH"],
}

with open("release/release-manifest.json", "w", encoding="utf-8") as f:
    json.dump(manifest, f, indent=2)
    f.write("\n")
PY
```

The manifest links the image digest, source commit, and SBOM hash.

### 13.4 Generate a Cosign key pair

Keep the private key outside the Git repository:

```bash
mkdir -p "$HOME/.cosign-devops-practical"
chmod 700 "$HOME/.cosign-devops-practical"
```

Generate the key pair in that directory:

```bash
cd "$HOME/.cosign-devops-practical"
cosign generate-key-pair
cd -
```

Cosign asks for a password. Keep it secure.

Copy only the public key into the release directory:

```bash
cp "$HOME/.cosign-devops-practical/cosign.pub" release/cosign.pub
```

The private key is:

```text
$HOME/.cosign-devops-practical/cosign.key
```

**Never commit or upload the private key.**

### 13.5 Sign the release manifest

Cosign versions may differ in their supported flags. Check the installed command first:

```bash
cosign sign-blob --help
```

For Cosign versions supporting bundle output and local signing without transparency-log upload:

```bash
cosign sign-blob \
  --yes \
  --key "$HOME/.cosign-devops-practical/cosign.key" \
  --tlog-upload=false \
  --bundle release/release-manifest.bundle \
  release/release-manifest.json
```

If the installed version does not recognize `--tlog-upload`, consult its `sign-blob --help` output and use the supported local-signing options. Do not assume a signing operation succeeded until the bundle exists and verification passes.

### 13.6 Verify the signature and SBOM hash

Verify the signature:

```bash
cosign verify-blob \
  --key release/cosign.pub \
  --bundle release/release-manifest.bundle \
  --insecure-ignore-tlog=true \
  release/release-manifest.json
```

The `--insecure-ignore-tlog=true` option is appropriate only for this local test-key exercise, where no transparency-log entry is being used. The public key must be obtained from a trusted source in a real release process.

Verify the SBOM hash:

```bash
python3 - <<'PY'
import hashlib
import json
from pathlib import Path

manifest = json.loads(Path("release/release-manifest.json").read_text())
sbom_path = Path("release") / manifest["sbom_file"]
actual = hashlib.sha256(sbom_path.read_bytes()).hexdigest()
expected = manifest["sbom_sha256"]

if actual != expected:
    raise SystemExit("FAIL: SBOM hash does not match")

print("PASS: SBOM hash matches")
PY
```

Compare the manifest digest with the expected image digest:

```bash
python3 - <<'PY'
import json
import os

with open("release/release-manifest.json", encoding="utf-8") as f:
    manifest = json.load(f)

if manifest["image_digest"] != os.environ["IMAGE_DIGEST"]:
    raise SystemExit("FAIL: image digest does not match")

print("PASS: image digest matches the expected ECR image")
PY
```

Because the EKS cluster has been deleted, a live Deployment cannot currently be queried. The digest comparison above verifies the manifest against the recorded ECR image digest, not against a currently running Kubernetes Deployment. If the cluster is recreated, compare the manifest digest with the live Deployment image as an additional check.

### 13.7 Tamper test: modify a copy of the SBOM

Keep the original SBOM unchanged:

```bash
cp release/sbom.spdx.json /tmp/sbom-tampered.json
printf '\nTampered copy\n' >> /tmp/sbom-tampered.json
```

Run the hash comparison against the modified copy:

```bash
python3 - <<'PY'
import hashlib
import json
from pathlib import Path

manifest = json.loads(Path("release/release-manifest.json").read_text())
expected = manifest["sbom_sha256"]
actual = hashlib.sha256(Path("/tmp/sbom-tampered.json").read_bytes()).hexdigest()

if actual == expected:
    raise SystemExit("ERROR: tampering was not detected")

print("PASS: modified SBOM detected; hash does not match")
PY
```

### 13.8 Tamper test: modify a copy of the signed manifest

```bash
python3 - <<'PY'
import json
from pathlib import Path

path = Path("/tmp/manifest-tampered.json")
manifest = json.loads(Path("release/release-manifest.json").read_text())
manifest["source_commit"] = "tampered"
path.write_text(json.dumps(manifest, indent=2) + "\n")
PY
```

Verify the altered copy using the original signature bundle:

```bash
cosign verify-blob \
  --key release/cosign.pub \
  --bundle release/release-manifest.bundle \
  --insecure-ignore-tlog=true \
  /tmp/manifest-tampered.json
```

The verification should fail because the manifest content no longer matches the signed content.

A valid signature proves that the signed content has not changed since it was signed by the holder of the corresponding private key. It does not prove that the image is vulnerability-free or that the build process itself was trustworthy.

### 13.9 Protect signing keys and review Git changes

Add these patterns to `.gitignore`:

```gitignore
# Private signing keys and credentials
*.key
*.pem
cosign.key

# Terraform and local environment
.terraform/
*.tfstate
*.tfstate.*
.terraform.lock.hcl.backup
kubeconfig
.aws/
.env
```

Do not ignore `.terraform.lock.hcl`; the Terraform provider lock file should normally be committed.

Review the files before committing:

```bash
git status --short
```

Only add the public key and release artifacts after confirming that no private key, password, credential, Terraform state, kubeconfig, or database dump is staged.

For example:

```bash
git add .gitignore README.md scripts/ release/sbom.spdx.json \
  release/sbom-table.txt release/release-manifest.json \
  release/release-manifest.bundle release/cosign.pub

git status
```

Commit and push only after reviewing the staged files:

```bash
git commit -m "Add SBOM and signed release artifacts"
git push origin main
```

**Completion evidence:** Keep the actual Syft output, component/version details, release manifest, Cosign verification output, and both tamper-test results. Mark this exercise complete only after the original signature and hash checks succeed and both tamper tests fail as expected.

## 14. Health checks and troubleshooting

The application provides `/health` and `/ready` endpoints. `/health` checks application health; `/ready` checks readiness including database connectivity.

When the EKS cluster is available, useful diagnostic commands include:

```bash
kubectl get nodes
kubectl get pods -n devops-app -o wide
kubectl get deployments,statefulsets,services,pvc -n devops-app
kubectl get events -n devops-app --sort-by='.lastTimestamp'
kubectl logs deployment/devops-api -n devops-app --tail=100
kubectl logs statefulset/postgres -n devops-app --tail=100
```

These commands require a reachable cluster. They will not work while the EKS cluster is deleted.

## 15. PostgreSQL backup and restore

The assessment used `pg_dump` to create a PostgreSQL custom-format backup and `pg_restore` to restore it into a local PostgreSQL Docker container.

Example backup command when the PostgreSQL pod is running:

```bash
mkdir -p database-backups

kubectl exec -n devops-app postgres-0 -- \
  pg_dump -U postgres -d devopsdb -Fc \
  > database-backups/postgres-backup.dump
```

Inspect the backup:

```bash
pg_restore --list database-backups/postgres-backup.dump
```

The restore exercise used a local PostgreSQL container. Example commands:

```bash
docker run -d \
  --name devops-postgres \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD='CHANGE_ME' \
  -e POSTGRES_DB=devopsdb \
  -p 5432:5432 \
  postgres:16
```

Copy and restore the backup:

```bash
docker cp database-backups/postgres-backup.dump \
  devops-postgres:/tmp/postgres-backup.dump

docker exec devops-postgres \
  pg_restore -U postgres \
  -d devopsdb \
  --no-owner \
  --no-privileges \
  --exit-on-error \
  /tmp/postgres-backup.dump
```

Verify restored records:

```bash
docker exec -it devops-postgres \
  psql -U postgres -d devopsdb
```

Then, in the PostgreSQL prompt:

```sql
\dt
SELECT * FROM records;
```

Use a secure password in your actual environment. Do not commit database backups or real credentials to Git.

## 16. Cleanup and cost control

After completing the practical assessment:

- Save required screenshots, logs, SBOMs, signed manifests, and backup files.
- Confirm which AWS resources should be retained.
- Delete EKS resources and supporting infrastructure when they are no longer required.
- Check EBS volumes, load balancers, NAT gateways, Elastic IPs, and other billable resources.
- Verify the ECR repository and images separately if they are being retained.
- Review AWS billing and Cost Explorer after cleanup.

The original EKS infrastructure was destroyed to avoid ongoing costs. Recreating it will incur charges.

## 17. Production improvements

The lab is intentionally small and is not a production high-availability design. Possible production improvements include:

- Private worker-node networking and controlled administrative access.
- Multiple worker nodes across Availability Zones.
- Managed TLS certificates and HTTPS.
- More restrictive Kubernetes NetworkPolicies.
- Centralized logs, metrics, alerts, and dashboards.
- External and tested database backup storage.
- Protected Terraform remote state and locking.
- Stronger release provenance and trusted key management.
- Automated policy enforcement for signed images and artifacts.

## 18. Useful links

- GitHub repository: https://github.com/sunildukare343/Sunil_AWS_Practical
- Amazon EKS documentation: https://docs.aws.amazon.com/eks/
- Amazon ECR documentation: https://docs.aws.amazon.com/ecr/
- Terraform documentation: https://developer.hashicorp.com/terraform/docs
- Kubernetes documentation: https://kubernetes.io/docs/
- Argo CD documentation: https://argo-cd.readthedocs.io/
- Syft documentation: https://github.com/anchore/syft
- Cosign documentation: https://docs.sigstore.dev/cosign/
- Trivy documentation: https://trivy.dev/

---

## Assessment summary

This repository documents a practical DevOps exercise covering Terraform-based AWS infrastructure, Docker image creation, Amazon ECR, EKS, Kubernetes, Argo CD GitOps, GitHub Actions CI, AWS OIDC, security controls, vulnerability scanning, database backup and restore, and an SBOM/signing learning exercise.

The EKS environment was used for the assessment and later destroyed to control costs. The SBOM and signing section should be marked completed only after the commands have been executed successfully and the verification evidence has been saved.
