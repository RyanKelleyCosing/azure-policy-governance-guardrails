targetScope = 'subscription'

type PolicyIds = {
  addManagedByTag: string
  allowedLocations: string
  denyPublicIp: string
  requireTag: string
}

@description('Locations permitted by the initiative.')
param allowedLocations array

@description('ManagedBy tag value applied by the remediation policy.')
param managedByTagValue string

@description('Resource IDs for the policy definitions included in the initiative.')
param policyIds PolicyIds

resource initiative 'Microsoft.Authorization/policySetDefinitions@2025-03-01' = {
  name: 'governance-guardrails'
  properties: {
    description: 'Baseline guardrails for tagging, regional placement, public exposure, and ownership hygiene.'
    displayName: 'Azure Policy & Governance Guardrails'
    metadata: {
      category: 'Governance'
      version: '1.0.0'
    }
    policyDefinitionGroups: [
      {
        category: 'Governance'
        description: 'Tagging requirements and auto-remediation controls.'
        displayName: 'Tag Governance'
        name: 'tagging'
      }
      {
        category: 'Security'
        description: 'Guardrails for direct internet exposure.'
        displayName: 'Networking Guardrails'
        name: 'networking'
      }
      {
        category: 'Operations'
        description: 'Regional placement controls.'
        displayName: 'Platform Standards'
        name: 'platform'
      }
    ]
    policyDefinitions: [
      {
        groupNames: [
          'tagging'
        ]
        parameters: {
          effect: {
            value: 'Deny'
          }
          tagName: {
            value: 'Environment'
          }
        }
        policyDefinitionId: policyIds.requireTag
        policyDefinitionReferenceId: 'requireEnvironmentTag'
      }
      {
        groupNames: [
          'tagging'
        ]
        parameters: {
          effect: {
            value: 'Deny'
          }
          tagName: {
            value: 'CostCenter'
          }
        }
        policyDefinitionId: policyIds.requireTag
        policyDefinitionReferenceId: 'requireCostCenterTag'
      }
      {
        groupNames: [
          'platform'
        ]
        parameters: {
          allowedLocations: {
            value: allowedLocations
          }
          effect: {
            value: 'Deny'
          }
        }
        policyDefinitionId: policyIds.allowedLocations
        policyDefinitionReferenceId: 'allowedLocationsOnly'
      }
      {
        groupNames: [
          'networking'
        ]
        parameters: {
          effect: {
            value: 'Deny'
          }
        }
        policyDefinitionId: policyIds.denyPublicIp
        policyDefinitionReferenceId: 'denyPublicIpCreation'
      }
      {
        groupNames: [
          'tagging'
        ]
        parameters: {
          effect: {
            value: 'modify'
          }
          tagValue: {
            value: managedByTagValue
          }
        }
        policyDefinitionId: policyIds.addManagedByTag
        policyDefinitionReferenceId: 'addManagedByTag'
      }
    ]
    policyType: 'Custom'
    version: '1.0.0'
  }
}

output initiativeId string = initiative.id
