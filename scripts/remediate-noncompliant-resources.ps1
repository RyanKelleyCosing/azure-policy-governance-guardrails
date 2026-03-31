[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [string]$AssignmentName = 'governance-guardrails',

    [string]$PolicyDefinitionReferenceId = 'addManagedByTag',

    [string]$RemediationName = 'managedby-tag-remediation',

    [ValidateSet('ExistingNonCompliant', 'ReEvaluateCompliance')]
    [string]$ResourceDiscoveryMode = 'ExistingNonCompliant'
)

$ErrorActionPreference = 'Stop'

Import-Module Az.Accounts -MinimumVersion 2.13.0
Import-Module Az.Resources -MinimumVersion 6.13.0

Set-AzContext -SubscriptionId $SubscriptionId | Out-Null

$assignmentScope = "/subscriptions/$SubscriptionId"
$policyAssignmentId = "$assignmentScope/providers/Microsoft.Authorization/policyAssignments/$AssignmentName"

$assignment = Get-AzPolicyAssignment -Name $AssignmentName -Scope $assignmentScope
if (-not $assignment) {
    throw "Policy assignment '$AssignmentName' was not found at scope '$assignmentScope'."
}

Write-Host "Starting remediation '$RemediationName' for assignment '$AssignmentName'."

$remediation = Start-AzPolicyRemediation `
    -Name $RemediationName `
    -PolicyAssignmentId $policyAssignmentId `
    -PolicyDefinitionReferenceId $PolicyDefinitionReferenceId `
    -ResourceDiscoveryMode $ResourceDiscoveryMode

Write-Host "Remediation started: $($remediation.Name)"
Write-Host ''
Write-Host 'Current non-compliant resources:'

Get-AzPolicyState -Filter "PolicyAssignmentName eq '$AssignmentName' and IsCompliant eq false" |
    Select-Object ResourceId, PolicyDefinitionReferenceId, ComplianceState, Timestamp |
    Format-Table -AutoSize