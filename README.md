# Kubernetes the Hard Way notes

## VM Setup

To follow the tutorial, we need four Linux VMs.
For VM setup instructions check out [Machine Setup.md](Machine%20Setup.md).

## Notes

### Tools Used

The tutorial guides us through setting up a working Kubernetes cluster from scratch (vanilla Linux machines).
We use a number of tools for this.

The tutorial has a `downloads` directory with a number of tools:
- `kubectl` - official Kubernetes client CLI tool. This is used to interact with the Kubernetes control plane

### SSH access

In step 3 - Provisioning Compute Resources we deal with setting up networking, hostname resolution and SSH access.

Part of this we did via cloud-init.

However, since our `jumpbox` machine is the place from where we do everything, we need to setup SSH access (root) from the `jumpbox` machine to the actual Kubernetes machines - server and the two nodes.

If hostname resolution has not been set up - we can set it up using `/etc/hosts`.

### Certificates

This is a brief summary of step 4 - Provisioning a CA and Generating TLS Certificates.

We have a provided openssl configuration file `ca.conf` which defines all the details to generate certificates for each Kubernetes component.

One thing to note is that our setup slightly differs from the official one in that our hostnames are `node0` (vs their `node-0`) and our FQDNs are `host.local` (vs their `host.kubernetes.local`).
Pay attention to this as the generated certificates might not be correct.

We now generate the CA configuration file, certificate and private key (`ca.crt` and `ca.key`).

Next, we create a certificate and a key for the following Kubernetes components, and for the admin user:
- `admin`
- `node0`
- `node1`
- `kube-proxy`
- `kube-scheduler`
- `kube-controller-manager`
- `kube-api-server`
- `service-accounts`

CA certificate goes to both worker nodes.
Node certificates, of course, go to each of the worker nodes.

CA certificate, CA key, API server, Service accounts go to the control plane.

## Kubernetes config files

Kubernetes client configuration files - kubeconfigs - configure clients to connect and authenticate to Kubernetes API servers.

Kubeconfig files - [link to docs](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/).

Kubeconfig setup is described [here](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/05-kubernetes-configuration-files.md).

TODO: Kubeconfig files in more detail

## TODOs

- etcd
- control plane configuration
- worker nodes configuration
- network routes
- test (nginx)
- further experiments
