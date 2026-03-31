# Azure Policy & Governance Guardrails

[![Azure Policy](https://img.shields.io/badge/Azure%20Policy-Guardrails-blue?logo=microsoft-azure)](.)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Bicep](https://img.shields.io/badge/Bicep-Policy%20as%20Code-blue?logo=microsoft-azure)](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)

A subscription-scope governance baseline for Azure that deploys custom policy definitions, assembles them into a reusable initiative, assigns them with managed identity, and includes a remediation path for non-compliant resources.

## What This Project Demonstrates

- Governance as code with Azure Policy and Bicep
- Subscription guardrails for tags, regions, and public exposure
- Remediation-ready assignments with managed identity and role binding
- Repo-friendly validation for standalone CI pipelines

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                 Azure Policy & Governance Guardrails                    │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                Custom Policy Definitions (Subscription)                │
│   Require Tags   Allowed Locations   Deny Public IP   Add ManagedBy    │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                Initiative: Governance Guardrails Baseline              │
│    Tag Governance      Networking Guardrails      Platform Standards   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│               Policy Assignment + Managed Identity + RBAC              │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    Remediation Task for Missing Tags                   │
└─────────────────────────────────────────────────────────────────────────┘
```

## Guardrails Included

| Guardrail | Effect | Outcome |
|-----------|--------|---------|
| Required `Environment` tag | Deny | Blocks untagged resources |
| Required `CostCenter` tag | Deny | Improves chargeback readiness |
| Allowed regions only | Deny | Restricts sprawl outside approved geography |
| Public IP creation blocked | Deny | Reduces direct internet exposure |
| Missing `ManagedBy` tag | Modify | Enables remediation at scale |

## Quick Start

### Prerequisites

- Azure subscription with `Owner` or `User Access Administrator`
- Azure CLI with Bicep support
- PowerShell 7 for remediation script execution

### Deploy the Initiative

```bash
az login

az deployment sub create \
  --name governance-guardrails \
  --location eastus \
  --template-file infra/main.bicep \
  --parameters allowedLocations="['eastus','centralus']" managedByTagValue='PlatformTeam'
```

### Start Remediation

```powershell
pwsh ./scripts/remediate-noncompliant-resources.ps1 \
  -SubscriptionId "<subscription-id>" \
  -AssignmentName "governance-guardrails"
```

## Project Structure

```
├── .github/
│   └── workflows/
│       └── validate.yml                 # CI validation for Bicep
├── infra/
│   ├── main.bicep                       # Subscription-scope orchestration
│   ├── policy-definitions.bicep         # Custom policy definitions
│   ├── policy-set.bicep                 # Initiative definition
│   └── policy-assignments.bicep         # Assignment + RBAC
├── scripts/
│   └── remediate-noncompliant-resources.ps1
├── tests/
│   └── validate-guardrails.ps1          # Offline validation script
├── .gitignore
├── LICENSE
└── README.md
```

## Validation

```powershell
pwsh ./tests/validate-guardrails.ps1
```

The validation script compiles each Bicep file locally. Subscription `what-if` is intentionally left as an operator-driven step because it depends on your active tenant, deployment location, and access model.

## Publishing

```bash
git clone https://github.com/RyanKelleyCosing/azure-policy-governance-guardrails.git
```

## License

MIT License - see [LICENSE](LICENSE) for details.