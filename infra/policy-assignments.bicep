targetScope = 'subscription'

var contributorRoleDefinitionId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'b24988ac-6180-42a0-ab88-20f7382dd24c'
)

@description('Name of the initiative assignment.')
param assignmentName string = 'governance-guardrails'

@description('Resource ID of the initiative being assigned.')
param initiativeId string

@description('Deployment location used for the system-assigned identity.')
param location string

resource initiativeAssignment 'Microsoft.Authorization/policyAssignments@2024-05-01' = {
  name: assignmentName
  identity: {
    type: 'SystemAssigned'
  }
  location: location
  properties: {
    description: 'Applies baseline governance guardrails for tags, locations, and network exposure.'
    displayName: 'Azure Policy & Governance Guardrails'
    enforcementMode: 'Default'
    metadata: {
      assignedBy: 'bicep'
      deploymentModel: 'mvp'
    }
    nonComplianceMessages: [
      {
        message: 'Resources must include the required tags, stay within approved regions, and avoid direct public IP exposure.'
      }
      {
        message: 'Missing ManagedBy tags can be fixed with the included remediation workflow.'
        policyDefinitionReferenceId: 'addManagedByTag'
      }
    ]
    policyDefinitionId: initiativeId
  }
}

resource assignmentContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, initiativeAssignment.name, contributorRoleDefinitionId)
  properties: {
    principalId: initiativeAssignment.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: contributorRoleDefinitionId
  }
}

output assignmentId string = initiativeAssignment.id
output assignmentPrincipalId string = initiativeAssignment.identity.principalId
output contributorRoleAssignmentId string = assignmentContributorRole.id
