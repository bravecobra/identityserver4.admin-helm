# Helm chart for IdentityServer4.Admin

## Installation

```powerhshell
helm upgrade --install identityserver4 .\identityserver4admin\ --values .\identityserver-values.yaml
```

## Configuration

### Traefik routes

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
        # tls:
        #   - secretName: traefik-cert
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
        # tls:
        #   - secretName: traefik-cert
```

### Patching CoreDNS

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
