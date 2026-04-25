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

try {
    Import-Module Az.Accounts -MinimumVersion 2.13.0
    Import-Module Az.Resources -MinimumVersion 6.13.0
} catch [System.IO.FileNotFoundException] {
    Write-Error "Required Az modules not found. Run: Install-Module Az.Accounts, Az.Resources"
    exit 1
}

try {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
} catch [Microsoft.Azure.Commands.Profile.Exceptions.AzPSAuthenticationException] {
    Write-Error "Authentication failed. Run Connect-AzAccount before invoking this script."
    exit 1
}

$assignmentScope = "/subscriptions/$SubscriptionId"
$policyAssignmentId = "$assignmentScope/providers/Microsoft.Authorization/policyAssignments/$AssignmentName"

try {
    $assignment = Get-AzPolicyAssignment -Name $AssignmentName -Scope $assignmentScope
} catch {
    throw "Failed to retrieve policy assignment '$AssignmentName': $_"
}

if (-not $assignment) {
    throw "Policy assignment '$AssignmentName' was not found at scope '$assignmentScope'."
}

Write-Information "Starting remediation '$RemediationName' for assignment '$AssignmentName'." -InformationAction Continue

try {
    $remediation = Start-AzPolicyRemediation `
        -Name $RemediationName `
        -PolicyAssignmentId $policyAssignmentId `
        -PolicyDefinitionReferenceId $PolicyDefinitionReferenceId `
        -ResourceDiscoveryMode $ResourceDiscoveryMode
} catch {
    throw "Failed to start policy remediation '$RemediationName': $_"
}

Write-Information "Remediation started: $($remediation.Name)" -InformationAction Continue
Write-Information '' -InformationAction Continue
Write-Information 'Current non-compliant resources:' -InformationAction Continue

Get-AzPolicyState -Filter "PolicyAssignmentName eq '$AssignmentName' and IsCompliant eq false" |
    Select-Object ResourceId, PolicyDefinitionReferenceId, ComplianceState, Timestamp |
    Format-Table -AutoSize