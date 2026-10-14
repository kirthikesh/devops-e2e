CLUSTER   ?= devops-e2e
NS        ?= todo-dev
TAG       ?= local
CHART     := charts/devops-e2e

.PHONY: help test compose-up compose-down kind-up images deploy monitoring argocd port-grafana port-argocd kind-down tf-plan tf-apply tf-destroy

help: ## Show targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  %-14s %s\n",$$1,$$2}'

# ---------- Week 1: local ----------
test: ## Lint + unit tests for the API
	cd app/api && pip install -q -r requirements-dev.txt && ruff check . && pytest -q

compose-up: ## Run whole app with Docker Compose -> http://localhost:8080
	docker compose up --build -d

compose-down: ## Stop Compose stack
	docker compose down -v

# ---------- Week 2: local Kubernetes ----------
kind-up: ## Create kind cluster + NGINX ingress
	kind create cluster --config k8s/kind-config.yaml
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	kubectl label node $(CLUSTER)-control-plane ingress-ready=true --overwrite
	kubectl -n ingress-nginx patch deploy ingress-nginx-controller --type merge -p '{"spec":{"template":{"spec":{"nodeSelector":{"ingress-ready":"true","kubernetes.io/os":"linux"},"tolerations":[{"key":"node-role.kubernetes.io/control-plane","operator":"Exists","effect":"NoSchedule"}]}}}}'
	kubectl -n ingress-nginx rollout status deploy/ingress-nginx-controller --timeout=180s

images: ## Build images and load them into kind
	docker build -t devops-e2e-api:$(TAG) app/api
	docker build -t devops-e2e-frontend:$(TAG) app/frontend
	kind load docker-image devops-e2e-api:$(TAG) devops-e2e-frontend:$(TAG) --name $(CLUSTER)

deploy: images ## Helm install to kind -> http://todo.localtest.me
	helm upgrade --install todo $(CHART) -n $(NS) --create-namespace \
	  -f gitops/envs/dev/values.yaml \
	  --set api.image.repository=devops-e2e-api,api.image.tag=$(TAG),api.image.pullPolicy=Never \
	  --set frontend.image.repository=devops-e2e-frontend,frontend.image.tag=$(TAG),frontend.image.pullPolicy=Never \
	  --set serviceMonitor.enabled=$$(kubectl get crd servicemonitors.monitoring.coreos.com >/dev/null 2>&1 && echo true || echo false)
	kubectl -n $(NS) rollout status deploy/api --timeout=120s

# ---------- Week 5-6: GitOps + observability ----------
monitoring: ## Install Prometheus/Grafana/Alertmanager + Loki
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo add grafana https://grafana.github.io/helm-charts
	helm repo update
	helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
	  -n monitoring --create-namespace -f monitoring/kube-prometheus-stack-values.yaml
	helm upgrade --install loki-stack grafana/loki-stack -n monitoring \
	  --set grafana.enabled=false,promtail.enabled=true,loki.isDefault=false
	kubectl apply -n monitoring -f monitoring/dashboards/api-dashboard.yaml

argocd: ## Install ArgoCD and bootstrap app-of-apps
	kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	kubectl -n argocd patch configmap argocd-cmd-params-cm --type merge -p '{"data":{"server.insecure":"true"}}'
	kubectl -n argocd rollout restart deploy/argocd-server
	kubectl -n argocd rollout status deploy/argocd-server --timeout=300s
	kubectl apply -f k8s/argocd-ingress.yaml
	kubectl apply -f gitops/argocd/root-app.yaml
	@echo "ArgoCD UI: http://argocd.localtest.me  (user: admin)"
	@echo "ArgoCD admin password:"; kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo

port-grafana: ## Grafana on http://localhost:3000 (admin/admin)
	kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80

port-argocd: ## ArgoCD UI on https://localhost:8443
	kubectl -n argocd port-forward svc/argocd-server 8443:443

kind-down: ## Delete kind cluster
	kind delete cluster --name $(CLUSTER)

# ---------- Week 4: AWS (costs money!) ----------
tf-plan: ## terraform plan
	cd infra && terraform init && terraform plan

tf-apply: ## terraform apply (creates EKS, RDS, ECR)
	cd infra && terraform apply

tf-destroy: ## ALWAYS run after a session
	cd infra && terraform destroy
