package test1

enforce[decision] {
  #title: NetworkPolicy: Prevent excessive ports
  input.request.object.kind == "NetworkPolicy"

  # Check for excessive ports in ingress or egress
  excessive_ports

  decision := {
    "allowed": false,
    "message": "CP-3006 - Resource %v has an allow all ports."
  }
}

ingress_ports_exist {
  walk(input.request.object.spec.ingress[_].ports, [[], value])
}
egress_ports_exist {
  walk(input.request.object.spec.ingress[_].ports, [[], value])
}
excessive_ports {
  not ingress_ports_exist
}
excessive_ports {
  not egress_ports_exist
}
excessive_ports {
  input.request.object.spec.ingress[_].ports == []
}
excessive_ports {
  input.request.object.spec.egress[_].ports == []
}