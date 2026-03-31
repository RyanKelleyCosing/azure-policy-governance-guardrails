targetScope = 'subscription'

@description('Deployment location used for the managed identity attached to the policy assignment.')
param location string = deployment().location

@description('Locations permitted by the governance initiative.')
param allowedLocations array = [
  'eastus'
  'centralus'
]

@description('Value used by remediation when the ManagedBy tag is missing.')
param managedByTagValue string = 'AzurePolicy'

@description('Name of the initiative assignment that applies the guardrails.')
param initiativeAssignmentName string = 'governance-guardrails'

module definitions 'policy-definitions.bicep' = {
  scope: subscription()
}

module policySet 'policy-set.bicep' = {
  scope: subscription()
  params: {
    allowedLocations: allowedLocations
    managedByTagValue: managedByTagValue
    policyIds: definitions.outputs.policyIds
  }
}

module assignments 'policy-assignments.bicep' = {
  scope: subscription()
  params: {
    assignmentName: initiativeAssignmentName
    initiativeId: policySet.outputs.initiativeId
    location: location
  }
}

output initiativeId string = policySet.outputs.initiativeId
output assignmentId string = assignments.outputs.assignmentId
