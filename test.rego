package test

# opa_windows_amd64 run test.rego repl.input:input.json repl.pocData:..\poc-library\pocData\data.json --watch

import data.repl.pocData

enforce[decision] {
  #title: NetworkPolicy: Allow only externally facing applications to access a perimeter service
  input.request.object.kind == "NetworkPolicy"

  #  App is not external facing
  pocData.appData[appID].isExternalService == "No"

  # It's trying to access a perimeter module
  allModules[perimeterModules[_]]

  decision := {
    "allowed": false,
    "message": "CP-3008 - Resource %v is not authorized for external connectivity."
  }
}

enforce[decision] {
  #title: NetworkPolicy: Allow only production applications to access a perimeter service
  input.request.object.kind == "NetworkPolicy"

  # It's not production
  not prodEnvironments[env]

  # It's trying to access a perimeter module
  allModules[perimeterModules[_]]

  decision := {
    "allowed": false,
    "message": "CP-3009 - Resource %v is not authorized for external connectivity due to not being production."
  }
}

enforce[decision] {
  #title: NetworkPolicy: Prevent connectivity from PCI applications to non-PCI applications
  parameters := {}

  input.request.object.kind == "NetworkPolicy"

  # Get the current list of PCI applications from the groupID
  pciAppsGIds :=  { a | a := pocData.groupID["50001"].memberId[_] }

  # Get the current list of PCI applications from the groupID
  pciAppsAIds :=  { a | 
    pocData.appData[a].applicationRisk.isPaymentCardIndustryReportable == "Yes"
  }

  pciApps := pciAppsGIds | pciAppsAIds
  
  # Source namespace app is PCI
  pciApps[appID]
  
  # Any ingress or egress app is not PCI
  allApps := ingressAppIDs | egressAppIDs
  count( allApps - pciApps ) > 0

  decision := {
    "allowed": false,
    "message": "CP-5005 - Resource %v has violated PCI connectivity rules."
  }
}

#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#
#  Common metadata processing
#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#
# Namespace tuples also available through namespace labels: namespaces[namespace].metadata.labels["xxxxx"]
namespace          = input.request.object.metadata.namespace

# Get the context from the namespace labels
appID              = split( namespace, "-")[0]
deploymentModuleID = split( namespace, "-")[1]
mt                 = split( namespace, "-")[2]
env                = split( namespace, "-")[3]

#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#
#  Common spec processing
#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#
ingressNamespaces = { x | x :=  input.request.object.spec.ingress[_].from[_].namespaceSelector.matchLabels.namespace }
egressNamespaces  = { x | x :=  input.request.object.spec.egress[_].to[_].namespaceSelector.matchLabels.namespace }

ingressAppIDs = { a |  a := split( ingressNamespaces[_], "-" )[0] }
egressAppIDs = { a | a := split( egressNamespaces[_], "-" )[0] }  

ingressModules = { x | x := split( ingressNamespaces[_], "-" )[2] }
egressModules = { x | x := split( egressNamespaces[_], "-" )[2] }
allModules := ingressModules | egressModules

# Perimeter modules
perimeterModules = { "ps", "iip" }

# Production environments
prodEnvironments = { "prod", "dr",  "qa", "uat"}