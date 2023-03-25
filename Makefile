
.PHONY: help
help: HELP_TARGET_WIDTH?=12
help: HELP_TARGET_COLOR?=33
help: HELP_MESSAGE?=Available Targets
help: ## Print this help message
	@printf '\033[$(HELP_TARGET_COLOR)m%s\033[0m\n\n' "Klip Kwop"
	@printf '  * In terminal one, run `make run` to start operator.\n'
	@printf '  * In terminal two, run `make echo`.\n'
	@printf '  * Use `export KUBECONFIG=.kwokconfig` to use local kubectl.\n\n'
	@printf '\033[$(HELP_TARGET_COLOR)m%s\033[0m\n\n' "$(HELP_MESSAGE)"
	@grep --no-filename -E '^[/\.a-z%A-Z_-]+:[^#]*## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":[^#]*## "}; {printf "\033[$(HELP_TARGET_COLOR)m%-$(HELP_TARGET_WIDTH)s\033[0m %s\n", $$1, $$2}'

#########################################################################

export KUBECONFIG=.kwokconfig
export KWOK_KUBE_VERSION=1.25.0
CLUSTER_NAME=operator-example
REPO=operator-example
IN_REPO=cd $(REPO) &&

clone: $(REPO) ## Clone the example repository

$(REPO):
	git clone git@github.com:Pscheidl/rust-kubernetes-operator-example.git $@

config: $(KUBECONFIG) ## Create the kwok cluster and kubeconfig

$(KUBECONFIG):
	kwokctl create cluster --name=$(CLUSTER_NAME)
	kubectl config use-context kwok-$(CLUSTER_NAME)

.PHONY: crd
crd: $(KUBECONFIG) $(REPO) ## Apply the CRD to the kwok cluster
	kubectl apply -f $(REPO)/echoes.example.com.yaml

build: $(REPO) ## Build the example crate
	$(IN_REPO) cargo build

run: build crd ## Run the example crate
	$(IN_REPO) KUBECONFIG=../$(KUBECONFIG) cargo run

echo: ## Apply the echo example resource to the kwok cluster
	kubectl apply -f $(REPO)/echo-example.yaml # Create the echo resource
	kubectl get echoes.example.com # Get the echo resource
	kubectl get deployments # Get the echo deployment
	kubectl get pods # Get the echo pods

clean: ## Delete the kwok cluster and config
	kwokctl delete cluster --name=$(CLUSTER_NAME) || true
	rm -rf $(KUBECONFIG)

clean-repo: ## Delete the example repository
	rm -rf $(REPO)
