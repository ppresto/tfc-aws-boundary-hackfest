# OpenTracing with Jaeger and fake-service

## Access fake-service
```
#list ports (default 8080)
kubectl get svc consul-ingress-gateway -o json | jq -r '.spec.ports[].port'

# output URL
echo "http://$(kubectl get svc consul-ingress-gateway -o json | jq -r '.status.loadBalancer.ingress[].hostname'):8080"
```

## Run Jaeger
Its recommended to use the Jaeger operator in K8s, but you can also generate the needed yaml from the jaeger-operator's `simplest` example for a quick dev env.  This example will generate the yaml for the latest all-in-one version so backup existing configs.
```
curl https://raw.githubusercontent.com/jaegertracing/jaeger-operator/main/examples/simplest.yaml | docker run -i --rm jaegertracing/jaeger-operator:master generate > jaeger-all-in-one.yaml
```
Once deployed you will have a few services and the simplest pod runnning.  This is Jaeger.

To view the UI use kubernetes port forwarding.
```
export POD_NAME=$(kubectl get pods -l app.kubernetes.io/instance=simplest -o name)
kubectl port-forward ${POD_NAME} 16686:16686
```

### Review Jaeger Trace examples


### Kubernetes

For proxy global default changes to take affect restart envoy sidecars with rolling deployment.
```
for i in  $(kubectl get deployments -l service=fake-service -o name); do kubectl rollout restart $i; done
```
