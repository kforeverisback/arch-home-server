.PHONY: all delete help create

help :
	@echo "Usage:"
	@echo "   make help          - prints this msg"
	@echo "   make all           - delete and recreate a new k3d cluster"
	@echo "   make delete        - delete k3d cluster"
	@echo "   make create        - creates a k3d cluster"

delete:
	@echo 'Delete resources'
	-k3d cluster delete ivy-k3d-cluster

create: delete
	@echo 'Create resources'
	# build k3d cluster
	@k3d cluster create ivy-k3d-cluster --config k3d.yaml --port "31100-31120:31100-31120@server:*"
