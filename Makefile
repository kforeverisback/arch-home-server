.PHONY: all delete help create

help :
	@echo "Usage:"
	@echo "   make help          - prints this msg"
	@echo "   make all           - delete and recreate a new k3d cluster"
	@echo "   make delete        - delete k3d cluster"
	@echo "   make create        - creates a k3d cluster"

delete:
	echo 'Delete resources'

create:
	echo 'Create resources'
