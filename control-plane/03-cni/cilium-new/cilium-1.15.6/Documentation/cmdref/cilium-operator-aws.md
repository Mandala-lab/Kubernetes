<!-- This file was autogenerated via cilium-operator --cmdref, do not edit manually-->

## cilium-operator-aws

Run cilium-operator-aws

```
cilium-operator-aws [flags]
```

### Options

```
      --auto-create-cilium-pod-ip-pools map                  Automatically create CiliumPodIPPool resources on startup. Specify pools in the form of <pool>=ipv4-cidrs:<cidr>,[<cidr>...];ipv4-mask-size:<size> (multiple pools can also be passed by repeating the CLI flag)
      --aws-enable-prefix-delegation                         Allows operator to allocate prefixes to ENIs instead of individual IP addresses
      --aws-instance-limit-mapping map                       Add or overwrite mappings of AWS instance limit in the form of {"AWS instance type": "Maximum Network Interfaces","IPv4 Addresses per Interface","IPv6 Addresses per Interface"}. cli example: --aws-instance-limit-mapping=a1.medium=2,4,4 --aws-instance-limit-mapping=a2.somecustomflavor=4,5,6 configmap example: {"a1.medium": "2,4,4", "a2.somecustomflavor": "4,5,6"}
      --aws-release-excess-ips                               Enable releasing excess free IP addresses from AWS ENI.
      --aws-use-primary-address                              Allows for using primary address of the ENI for allocations on the node
      --bgp-announce-lb-ip                                   Announces service IPs of type LoadBalancer via BGP
      --bgp-config-path string                               Path to file containing the BGP configuration (default "/var/lib/cilium/bgp/config.yaml")
      --ces-max-ciliumendpoints-per-ces int                  Maximum number of CiliumEndpoints allowed in a CES (default 100)
      --ces-slice-mode string                                Slicing mode define how ceps are grouped into a CES (default "cesSliceModeIdentity")
      --ces-write-qps-burst int                              CES work queue burst rate (default 20)
      --ces-write-qps-limit float                            CES work queue rate limit (default 10)
      --cilium-endpoint-gc-interval duration                 GC interval for cilium endpoints (default 5m0s)
      --cilium-pod-labels string                             Cilium Pod's labels. Used to detect if a Cilium pod is running to remove the node taints where its running and set NetworkUnavailable to false (default "k8s-app=cilium")
      --cilium-pod-namespace string                          Name of the Kubernetes namespace in which Cilium is deployed in. Defaults to the same namespace defined in k8s-namespace
      --cluster-id uint32                                    Unique identifier of the cluster
      --cluster-name string                                  Name of the cluster (default "default")
      --cluster-pool-ipv4-cidr strings                       IPv4 CIDR Range for Pods in cluster. Requires 'ipam=cluster-pool' and 'enable-ipv4=true'
      --cluster-pool-ipv4-mask-size int                      Mask size for each IPv4 podCIDR per node. Requires 'ipam=cluster-pool' and 'enable-ipv4=true' (default 24)
      --cluster-pool-ipv6-cidr strings                       IPv6 CIDR Range for Pods in cluster. Requires 'ipam=cluster-pool' and 'enable-ipv6=true'
      --cluster-pool-ipv6-mask-size int                      Mask size for each IPv6 podCIDR per node. Requires 'ipam=cluster-pool' and 'enable-ipv6=true' (default 112)
      --cnp-status-cleanup-burst int                         Maximum burst of requests to clean up status nodes updates in CNPs (default 20)
      --cnp-status-cleanup-qps float                         Rate used for limiting the clean up of the status nodes updates in CNP, expressed as qps (default 10)
      --config string                                        Configuration file (default "$HOME/ciliumd.yaml")
      --config-dir string                                    Configuration directory that contains a file for each option
      --controller-group-metrics strings                     List of controller group names for which to to enable metrics. Accepts 'all' and 'none'. The set of controller group names available is not guaranteed to be stable between Cilium versions.
  -D, --debug                                                Enable debugging mode
      --ec2-api-endpoint string                              AWS API endpoint for the EC2 service
      --enable-cilium-endpoint-slice                         If set to true, the CiliumEndpointSlice feature is enabled. If any CiliumEndpoints resources are created, updated, or deleted in the cluster, all those changes are broadcast as CiliumEndpointSlice updates to all of the Cilium agents.
      --enable-cilium-operator-server-access strings         List of cilium operator APIs which are administratively enabled. Supports '*'. (default [*])
      --enable-gateway-api-secrets-sync                      Enables fan-in TLS secrets sync from multiple namespaces to singular namespace (specified by gateway-api-secrets-namespace flag) (default true)
      --enable-ingress-controller                            Enables cilium ingress controller. This must be enabled along with enable-envoy-config in cilium agent.
      --enable-ingress-proxy-protocol                        Enable proxy protocol for all Ingress listeners. Note that _only_ Proxy protocol traffic will be accepted once this is enabled.
      --enable-ingress-secrets-sync                          Enables fan-in TLS secrets from multiple namespaces to singular namespace (specified by ingress-secrets-namespace flag) (default true)
      --enable-ipv4                                          Enable IPv4 support (default true)
      --enable-ipv6                                          Enable IPv6 support (default true)
      --enable-k8s                                           Enable the k8s clientset (default true)
      --enable-k8s-api-discovery                             Enable discovery of Kubernetes API groups and resources with the discovery API
      --enable-k8s-endpoint-slice                            Enables k8s EndpointSlice feature in Cilium if the k8s cluster supports it (default true)
      --enable-metrics                                       Enable Prometheus metrics
      --enforce-ingress-https                                Enforces https for host having matching TLS host in Ingress. Incoming traffic to http listener will return 308 http error code with respective location in header. (default true)
      --eni-gc-interval duration                             Interval for garbage collection of unattached ENIs. Set to 0 to disable (default 5m0s)
      --eni-gc-tags map                                      Additional tags attached to ENIs created by Cilium. Dangling ENIs with this tag will be garbage collected
      --eni-tags map                                         ENI tags in the form of k1=v1 (multiple k/v pairs can be passed by repeating the CLI flag)
      --excess-ip-release-delay int                          Number of seconds operator would wait before it releases an IP previously marked as excess (default 180)
      --gateway-api-secrets-namespace string                 Namespace having tls secrets used by CEC for Gateway API (default "cilium-secrets")
      --gops-port uint16                                     Port for gops server to listen on (default 9891)
  -h, --help                                                 help for cilium-operator-aws
      --identity-allocation-mode string                      Method to use for identity allocation (default "kvstore")
      --identity-gc-interval duration                        GC interval for security identities (default 15m0s)
      --identity-gc-rate-interval duration                   Interval used for rate limiting the GC of security identities (default 1m0s)
      --identity-gc-rate-limit int                           Maximum number of security identities that will be deleted within the identity-gc-rate-interval (default 2500)
      --identity-heartbeat-timeout duration                  Timeout after which identity expires on lack of heartbeat (default 30m0s)
      --ingress-default-lb-mode string                       Default loadbalancer mode for Ingress. Applicable values: dedicated, shared (default "dedicated")
      --ingress-default-secret-name string                   Default secret name for Ingress.
      --ingress-default-secret-namespace string              Default secret namespace for Ingress.
      --ingress-default-xff-num-trusted-hops uint32          The number of additional ingress proxy hops from the right side of the HTTP header to trust when determining the origin client's IP address.
      --ingress-lb-annotation-prefixes strings               Annotations and labels which are needed to propagate from Ingress to the Load Balancer. (default [service.beta.kubernetes.io,service.kubernetes.io,cloud.google.com])
      --ingress-secrets-namespace string                     Namespace having tls secrets used by Ingress and CEC. (default "cilium-secrets")
      --ingress-shared-lb-service-name string                Name of shared LB service name for Ingress. (default "cilium-ingress")
      --instance-tags-filter map                             EC2 Instance tags in the form of k1=v1,k2=v2 (multiple k/v pairs can also be passed by repeating the CLI flag
      --ipam string                                          Backend to use for IPAM (default "eni")
      --k8s-api-server string                                Kubernetes API server URL
      --k8s-client-burst int                                 Burst value allowed for the K8s client
      --k8s-client-qps float32                               Queries per second limit for the K8s client
      --k8s-heartbeat-timeout duration                       Configures the timeout for api-server heartbeat, set to 0 to disable (default 30s)
      --k8s-kubeconfig-path string                           Absolute path of the kubernetes kubeconfig file
      --k8s-namespace string                                 Name of the Kubernetes namespace in which Cilium Operator is deployed in
      --k8s-service-proxy-name string                        Value of K8s service-proxy-name label for which Cilium handles the services (empty = all services without service.kubernetes.io/service-proxy-name label)
      --kvstore string                                       Key-value store type
      --kvstore-opt map                                      Key-value store options e.g. etcd.address=127.0.0.1:4001
      --leader-election-lease-duration duration              Duration that non-leader operator candidates will wait before forcing to acquire leadership (default 15s)
      --leader-election-renew-deadline duration              Duration that current acting master will retry refreshing leadership in before giving up the lock (default 10s)
      --leader-election-retry-period duration                Duration that LeaderElector clients should wait between retries of the actions (default 2s)
      --limit-ipam-api-burst int                             Upper burst limit when accessing external APIs (default 20)
      --limit-ipam-api-qps float                             Queries per second limit when accessing external IPAM APIs (default 4)
      --loadbalancer-l7-algorithm string                     Default LB algorithm for services that do not specify related annotation (default "round_robin")
      --loadbalancer-l7-ports strings                        List of service ports that will be automatically redirected to backend.
      --log-driver strings                                   Logging endpoints to use for example syslog
      --log-opt map                                          Log driver options for cilium-operator, configmap example for syslog driver: {"syslog.level":"info","syslog.facility":"local4"}
      --max-connected-clusters uint32                        Maximum number of clusters to be connected in a clustermesh. Increasing this value will reduce the maximum number of identities available. Valid configurations are [255, 511]. (default 255)
      --mesh-auth-mutual-enabled                             The flag to enable mutual authentication for the SPIRE server (beta).
      --mesh-auth-spiffe-trust-domain string                 The trust domain for the SPIFFE identity. (default "spiffe.cilium")
      --mesh-auth-spire-agent-socket string                  The path for the SPIRE admin agent Unix socket. (default "/run/spire/sockets/agent/agent.sock")
      --mesh-auth-spire-server-address string                SPIRE server endpoint. (default "spire-server.spire.svc:8081")
      --mesh-auth-spire-server-connection-timeout duration   SPIRE server connection timeout. (default 10s)
      --nodes-gc-interval duration                           GC interval for CiliumNodes (default 5m0s)
      --operator-api-serve-addr string                       Address to serve API requests (default "localhost:9234")
      --operator-pprof                                       Enable serving pprof debugging API
      --operator-pprof-address string                        Address that pprof listens on (default "localhost")
      --operator-pprof-port uint16                           Port that pprof listens on (default 6061)
      --operator-prometheus-serve-addr string                Address to serve Prometheus metrics (default ":9963")
      --parallel-alloc-workers int                           Maximum number of parallel IPAM workers (default 50)
      --pod-restart-selector string                          cilium-operator will delete/restart any pods with these labels if the pod is not managed by Cilium. If this option is empty, then all pods may be restarted (default "k8s-app=kube-dns")
      --remove-cilium-node-taints                            Remove node taint "node.cilium.io/agent-not-ready" from Kubernetes nodes once Cilium is up and running (default true)
      --set-cilium-is-up-condition                           Set CiliumIsUp Node condition to mark a Kubernetes Node that a Cilium pod is up and running in that node (default true)
      --set-cilium-node-taints                               Set node taint "node.cilium.io/agent-not-ready" from Kubernetes nodes if Cilium is scheduled but not up and running
      --skip-cnp-status-startup-clean                        If set to true, the operator will not clean up CNP node status updates at startup
      --skip-crd-creation                                    When true, Kubernetes Custom Resource Definitions will not be created
      --subnet-ids-filter strings                            Subnets IDs (separated by commas)
      --subnet-tags-filter map                               Subnets tags in the form of k1=v1,k2=v2 (multiple k/v pairs can also be passed by repeating the CLI flag
      --synchronize-k8s-nodes                                Synchronize Kubernetes nodes to kvstore and perform CNP GC (default true)
      --synchronize-k8s-services                             Synchronize Kubernetes services to kvstore (default true)
      --unmanaged-pod-watcher-interval int                   Interval to check for unmanaged kube-dns pods (0 to disable) (default 15)
      --update-ec2-adapter-limit-via-api                     Use the EC2 API to update the instance type to adapter limits (default true)
      --version                                              Print version information
```

### SEE ALSO

* [cilium-operator-aws completion](cilium-operator-aws_completion.md)	 - Generate the autocompletion script for the specified shell
* [cilium-operator-aws hive](cilium-operator-aws_hive.md)	 - Inspect the hive
* [cilium-operator-aws metrics](cilium-operator-aws_metrics.md)	 - Access metric status of the operator
