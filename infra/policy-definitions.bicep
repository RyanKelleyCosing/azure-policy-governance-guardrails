targetScope = 'subscription'

type PolicyIds = {
  addManagedByTag: string
  allowedLocations: string
  denyPublicIp: string
  requireTag: string
}

var contributorRoleDefinitionId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'b24988ac-6180-42a0-ab88-20f7382dd24c'
)

resource requireTagPolicy 'Microsoft.Authorization/policyDefinitions@2023-04-01' = {
  name: 'require-standard-tag'
  properties: {
    description: 'Denies resources that do not contain the configured tag.'
    displayName: 'Require a standard tag on resources'
    metadata: {
      category: 'Governance'
      version: '1.0.0'
    }
    mode: 'Indexed'
    parameters: {
      effect: {
        allowedValues: [
          'Audit'
          'Deny'
        ]
        defaultValue: 'Deny'
        metadata: {
          description: 'Effect applied when the required tag is missing.'
          displayName: 'Effect'
        }
        type: 'String'
      }
      tagName: {
        metadata: {
          description: 'Tag that must exist on the resource.'
          displayName: 'Required tag name'
        }
        type: 'String'
      }
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            notEquals: 'Microsoft.Resources/subscriptions/resourceGroups'
          }
          {
            field: "[concat('tags[', parameters('tagName'), ']')]"
            exists: 'false'
          }
        ]
      }
      then: {
        effect: "[parameters('effect')]"
      }
    }
    policyType: 'Custom'
    version: '1.0.0'
  }
}

resource allowedLocationsPolicy 'Microsoft.Authorization/policyDefinitions@2023-04-01' = {
  name: 'allowed-deployment-locations-custom'
  properties: {
    description: 'Restricts deployments to the allowed Azure regions.'
    displayName: 'Allow deployments only in approved locations'
    metadata: {
      category: 'Governance'
      version: '1.0.0'
    }
    mode: 'Indexed'
    parameters: {
      allowedLocations: {
        metadata: {
          description: 'Azure regions permitted for resource deployment.'
          displayName: 'Allowed locations'
        }
        type: 'Array'
      }
      effect: {
        allowedValues: [
          'Audit'
          'Deny'
        ]
        defaultValue: 'Deny'
        metadata: {
          description: 'Effect applied when a resource is deployed to a non-approved location.'
          displayName: 'Effect'
        }
        type: 'String'
      }
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: 'location'
            notIn: "[parameters('allowedLocations')]"
          }
          {
            field: 'location'
            notEquals: 'global'
          }
          {
            field: 'type'
            notEquals: 'Microsoft.Resources/subscriptions/resourceGroups'
          }
        ]
      }
      then: {
        effect: "[parameters('effect')]"
      }
    }
    policyType: 'Custom'
    version: '1.0.0'
  }
}

resource denyPublicIpPolicy 'Microsoft.Authorization/policyDefinitions@2023-04-01' = {
  name: 'deny-public-ip-addresses-custom'
  properties: {
    description: 'Blocks direct creation of Azure Public IP resources.'
    displayName: 'Deny creation of public IP addresses'
    metadata: {
      category: 'Security'
      version: '1.0.0'
    }
    mode: 'All'
    parameters: {
      effect: {
        allowedValues: [
          'Audit'
          'Deny'
        ]
        defaultValue: 'Deny'
        metadata: {
          description: 'Effect applied when a public IP is created.'
          displayName: 'Effect'
        }
        type: 'String'
      }
    }
    policyRule: {
      if: {
        field: 'type'
        equals: 'Microsoft.Network/publicIPAddresses'
      }
      then: {
        effect: "[parameters('effect')]"
      }
    }
    policyType: 'Custom'
    version: '1.0.0'
  }
}

resource addManagedByTagPolicy 'Microsoft.Authorization/policyDefinitions@2023-04-01' = {
  name: 'add-managedby-tag-custom'
  properties: {
    description: 'Adds a ManagedBy tag when it is missing so governance ownership remains visible.'
    displayName: 'Add ManagedBy tag when missing'
    metadata: {
      category: 'Governance'
      version: '1.0.0'
    }
    mode: 'Indexed'
    parameters: {
      effect: {
        allowedValues: [
          'disabled'
          'modify'
        ]
        defaultValue: 'modify'
        metadata: {
          description: 'Effect applied when the ManagedBy tag is missing.'
          displayName: 'Effect'
        }
        type: 'String'
      }
      tagValue: {
        defaultValue: 'AzurePolicy'
        metadata: {
          description: 'Value written to the ManagedBy tag during remediation.'
          displayName: 'ManagedBy tag value'
        }
        type: 'String'
      }
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            notEquals: 'Microsoft.Resources/subscriptions/resourceGroups'
          }
          {
            field: "tags['ManagedBy']"
            exists: 'false'
          }
        ]
      }
      then: {
        details: {
          operations: [
            {
              field: "tags['ManagedBy']"
              operation: 'addOrReplace'
              value: "[parameters('tagValue')]"
            }
          ]
          roleDefinitionIds: [
            contributorRoleDefinitionId
          ]
        }
        effect: "[parameters('effect')]"
      }
    }
    policyType: 'Custom'
    version: '1.0.0'
  }
}

output policyIds PolicyIds = {
  addManagedByTag: addManagedByTagPolicy.id
  allowedLocations: allowedLocationsPolicy.id
  denyPublicIp: denyPublicIpPolicy.id
  requireTag: requireTagPolicy.id
}
