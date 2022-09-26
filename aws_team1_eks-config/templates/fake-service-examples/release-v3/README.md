# Notes

## Deploy services into K8s namespaces
Before deploying consul deploy services into a normal K8s namespaced environment.  This will deploy web, and its upstream api-v1.  The additional svc payments and currency are deployed as well so we have the full environment with K8s namespaces layed out.  These wont be used until api-v2 is deployed.
```
cd aws_eks_apps/templates/fs-ns-tp
kubectl apply -f .
```

Review services web/api using local browser
```
kubectl port-forward svc/web 9090:9090
```
http://localhost:9090/ui


Login to TFCB and run workspace: aws_eks_apps.  This will deploy consul with Helm, and redepoy any changes from the services we manually deployed with kubectl earlier.  Review the Env.
* TFCB Workspaces (HCP, VPC, TG, EKS, and finally the current aws_eks_apps)
* 
```
cd ./api-release-v2
kubectl apply -f api-traffic-mgmt.yaml
kubectl apply -f api-v2.yaml
```

Test API version from CLI in While Loop
```
HOST=$(kubectl get svc -o json | jq -r '.items[].status.loadBalancer.ingress | select( . != null) | .[].hostname')

while true; do curl -s http://${HOST}:8080/ | jq -r '.upstream_calls."http://api:9091".name'; sleep 1; done
```

