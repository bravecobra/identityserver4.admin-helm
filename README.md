# Helm chart for IdentityServer4.Admin

## Description

This helm chart will deploy [IdentityServer4.Admin](https://github.com/skoruba/IdentityServer4.Admin) onto your k8s cluster.

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

Create a `identityserver-values.yaml` file to override any default values, specific to your installation. The default values can be found in [values.yaml](./src/identityserver4admin/values.yaml)

Then install the `helm` chart in the namespace you want. Here we choose to install the release `identityserver4` in the `infrastructure` namespace.

```powershell
helm upgrade --install identityserver4 identityserver4admin/identityserver4admin --namespace infrastructure --values .\identityserver-values.yaml
```

## Configuration

Apart from specifying overrides of the `values.yml`, there are 2 more things that need to be addressed.

1. You need to adapt make sure that the admin pod can resolve the identity pod by it's external name. We'll do that by patching the ConfigMap of CoreDNS
1. You need to route traffic through an ingress controller. An example of Traefik is being given here

### Patching CoreDNS

Next, the client applications need to be able to verify the certificate, with which token are signed. To do that, they contact the Issuer url. That url is in the example `http://login.k8s.local`, which a pod will not be able to resolve correctly.

To do so, we patch the CoreDNS config file and point that hostname to the service that needs to respond. Note the 2 extra rewrite lines. Here they point to the services deployed in the `infrastructure` namespace.

```yaml
.:53 {
    errors
    health {
       lameduck 5s
    }
    rewrite name login.k8s.local identityserver4-identity.infrastructure.svc.cluster.local
    rewrite name admin.login.k8s.local identityserver4-admin.infrastructure.svc.cluster.local
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

### Traefik routes

First you want your ingress controller to have the domains you specified for the services to be forwarded to those services that were created.

In `Traefik` that would be something like the following.

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: "login-admin-ingressroute"
  namespace: infrastructure #the namespace you installed in
spec:
  entryPoints:
    - web
  routes:
    - match: Host(`admin.login.k8s.local`) && PathPrefix(`/`)
      kind: Rule
      namespace: infrastructure #the namespace you installed in
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
  namespace: infrastructure #the namespace you installed in
spec:
  entryPoints:
    - web
  routes:
    - match: Host(`login.k8s.local`) && PathPrefix(`/`)
      kind: Rule
      namespace: infrastructure #the namespace you installed in
      services:
      - name: identityserver4-identity
        port: 80
        path: /
        passHostHeader: true
```

### Runnign with TLS Support

#### Using Cert-manager

If you have `cert-manager` already install on your cluster, we can easily let this Chart autogenerate the certificates, provided there is an CA Root to sign them. You can use any method `cert-manager` provides. In this example we'll use the Self-Signed Issuer.

To install cert-manager on your cluster with helm, here's the quick start. For more info, look at [their site](https://cert-manager.io/docs/installation/)

```powershell
kubectl create namespace cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.3.1 --set installCRDs=true
```

First let's use [mkcert](https://github.com/FiloSottile/mkcert) to generate a CA Root on our dev machine. This CA root is only valid for local development.

```powershell
# execute under elevated Administrator privileges
choco install mkcert
mkcert --install
```

Create a kubernetes secret from the CA Root.

```powershell
copy $env:LOCALAPPDATA\mkcert\rootCA.pem ./src/examples/cacerts.crt
copy $env:LOCALAPPDATA\mkcert\rootCA-key.pem ./src/examples/cacerts.key
```

Next we turn this certificate into a Issuer for `cert-manager` to use. Any certificate requests it receives for it, will use this CA Root to sign the requested certificates and since our local dev manchine knows the CA Root as well, it'll be valid for both your cluster and for your local dev machine.

```powershell
# Create a k8s secret manifest containing the CA Root certificate of mkcert to a cacerts.yaml file
kubectl create secret tls ca-key-pair --namespace=cert-manager --cert=./src/examples/cacerts.crt --key=./src/examples/cacerts.key  --dry-run=client -o yaml > ./src/examples/cacerts.yaml
kubectl apply -f ./src/examples/cacerts.yaml
```

Now add that new secret as an Issuer to `cert-manager` by applying the `./src/examples/cluster-issuer.yaml`:

```powershell
kubectl apply -f ./src/examples/cluster-issuer.yaml
```

Next make sure you add the following to your `values.yaml` file and the helm chart will generate the certificates for each service if they have `ssl: true`.

```yaml
certificates:
  certManager:
    enabled: true
    issuerRef:
      name: selfsigned-ca-issuer
      kind: ClusterIssuer
```

#### Provide your own certificates

You can also provide your own certificates if you want, by enabling ssl for the services and specifying the kubernetes secret name that contains the certificate. Make sure to add the CA root public key.

```yaml
kind: Secret
apiVersion: v1
metadata:
  name: identityserver4-cert-admin
  namespace: infrastructure #the namespace you installed in
type: kubernetes.io/tls
data:
  ca.crt: >-
    LS0tLS1CRUdJTiBDRVJ....tLS0tCg==
  tls.crt: >-
    LS0tLS1CRUdJTiBDRVJUSUZ...0tLS0K
  tls.key: >-
    LS0tLS1CRUdJTiBSU0EgUFJ...LS0tLQo=
```
