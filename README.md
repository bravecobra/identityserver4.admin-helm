# Helm chart for IdentityServer4.Admin

## Description

This helm chart will deploy [IdentityServer4.Admin](https://github.com/skoruba/IdentityServer4.Admin) onto your k8s cluster in the `default` namerspace.

Deployed components:

- Admin
- STS.Identity
- MSSQL instance

> Note: Currently there is no support for TLS, external database services or namespaces. The API service is also missing at the moment.

## Installation

Add the helm repo

```bash
helm repo add identityserver4admin https://bravecobra.github.io/identityserver4.admin-helm/charts/
helm repo update
```

Create a `identityserver-values.yaml` file to override any default values, specific to your installation. The default values can be found in [values.yaml](./src/identity4admin/values.yaml)

Then install the `helm` chart

```powerhshell
helm upgrade --install identityserver4 identityserver4admin/identityserver4admin --values .\identityserver-values.yaml
```

## Configuration

Apart from specifying overrides of the `values.yml`, there are 2 more things that need to be addressed.

### Traefik routes

First you want your ingress controller to have the domains you specified for the services to be forwarded to those services that were created.

In `Traefik` that would be something like the following.

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: "login-admin-ingressroute"
  namespace: default
spec:
  entryPoints:
    - web
  routes:
    - match: Host(`admin.login.k8s.local`) && PathPrefix(`/`)
      kind: Rule
      namespace: default
      services:
      - name: identityserver4-admin
        port: 80
        path: /
        passHostHeader: true
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: "login-ingressroute"
  namespace: default
spec:
  entryPoints:
    - web
  routes:
    - match: Host(`login.k8s.local`) && PathPrefix(`/`)
      kind: Rule
      namespace: default
      services:
      - name: identityserver4-identity
        port: 80
        path: /
        passHostHeader: true
```

### Patching CoreDNS

Next, the client applications need to be able to verify the certificate, with which token are signed. To do that, they contact the Issuer url. That url is in the example `http://login.k8s.local`, which a pod will not be able to resolve correctly.

To do so, we patch the CoreDNS config file and point that hostname to the service that needs to respond.

```yaml
.:53 {
    errors
    health {
       lameduck 5s
    }
    rewrite name login.k8s.local identityserver4-identity.default.svc.cluster.local
    rewrite name admin.login.k8s.local identityserver4-admin.default.svc.cluster.local
    ready
    kubernetes cluster.local in-addr.arpa ip6.arpa {
       pods insecure
       fallthrough in-addr.arpa ip6.arpa
       ttl 30
    }
    prometheus :9153
    forward . /etc/resolv.conf {
       max_concurrent 1000
    }
    cache 30
    loop
    reload
    loadbalance
}
```
