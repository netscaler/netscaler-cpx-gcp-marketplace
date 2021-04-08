include ./app.Makefile
include ./crd.Makefile
include ./gcloud.Makefile
include ./var.Makefile


TAG ?= 1.13.20
GCP_TAG ?= 1.13
CPX_TAG ?= 13.0-76.29
EXPORTER_TAG ?= 1.4.7
$(info ---- TAG = $(TAG))

APP_DEPLOYER_IMAGE ?= $(REGISTRY)/citrix-adc-cpx/deployer:$(TAG)
NAME ?= citrix-adc-cpx-with-cic

ifdef IMAGE_CITRIX_CPX
  IMAGE_CITRIX_CPX_FIELD = , "image": "$(IMAGE_CITRIX_CPX)" endif
endif

ifdef IMAGE_CITRIX_CONTROLLER
  IMAGE_CITRIX_CONTROLLER_FIELD = , "cic.image": "$(IMAGE_CITRIX_CONTROLLER)" endif
endif

ifdef IMAGE_EXPORTER
  IMAGE_EXPORTER_FIELD = , "exporter.image": "$(IMAGE_EXPORTER)" endif
endif

ifdef CITRIX_SERVICE_ACCOUNT
  CITRIX_SERVICE_ACCOUNT = , "serviceAccount": "$(CITRIX_SERVICE_ACCOUNT)"
endif

APP_PARAMETERS ?= { \
  "name": "$(NAME)", \
  "namespace": "$(NAMESPACE)" \
  $(IMAGE_CITRIX_CONTROLLER_FIELD) \
  $(IMAGE_CITRIX_CPX_FIELD) \
  $(IMAGE_EXPORTER_FIELD) \
  $(CITRIX_SERVICE_ACCOUNT) \
}

TESTER_IMAGE ?= $(REGISTRY)/citrix-adc-cpx/tester:$(TAG)


app/build:: .build/citrix-adc-cpx/debian9  \
            .build/citrix-adc-cpx/deployer \
            .build/citrix-adc-cpx/citrix-adc-cpx \
	    .build/citrix-adc-cpx/citrix-k8s-ingress-controller \
            .build/citrix-adc-cpx/exporter \
            .build/citrix-adc-cpx/tester


.build/citrix-adc-cpx: | .build
	mkdir -p "$@"


.build/citrix-adc-cpx/debian9: .build/var/REGISTRY \
                      .build/var/TAG \
                      | .build/citrix-adc-cpx
	docker pull marketplace.gcr.io/google/debian9
	docker tag marketplace.gcr.io/google/debian9 "$(REGISTRY)/citrix-adc-cpx/debian9:$(TAG)"
	docker push "$(REGISTRY)/citrix-adc-cpx/debian9:$(TAG)"
	@touch "$@"


.build/citrix-adc-cpx/deployer: deployer/* \
                       chart/citrix-cpx-with-ingress-controller/* \
                       chart/citrix-cpx-with-ingress-controller/templates/* \
                       schema.yaml \
                       .build/var/APP_DEPLOYER_IMAGE \
                       .build/var/MARKETPLACE_TOOLS_TAG \
                       .build/var/REGISTRY \
                       .build/var/TAG \
                       | .build/citrix-adc-cpx
	docker build \
	    --build-arg REGISTRY="$(REGISTRY)/citrix-adc-cpx" \
	    --build-arg TAG="$(TAG)" \
	    --build-arg MARKETPLACE_TOOLS_TAG="$(MARKETPLACE_TOOLS_TAG)" \
	    --tag "$(APP_DEPLOYER_IMAGE)" \
	    -f deployer/Dockerfile \
	    .
	docker push "$(APP_DEPLOYER_IMAGE)"
	docker pull "$(APP_DEPLOYER_IMAGE)"
	docker tag "$(APP_DEPLOYER_IMAGE)" \
            "$(REGISTRY)/citrix-adc-cpx/deployer:$(GCP_TAG)"
	docker push "$(REGISTRY)/citrix-adc-cpx/deployer:$(GCP_TAG)"
	@touch "$@"


.build/citrix-adc-cpx/citrix-adc-cpx: .build/var/REGISTRY \
                    .build/var/TAG \
                    | .build/citrix-adc-cpx
	docker pull quay.io/citrix/citrix-k8s-cpx-ingress:$(CPX_TAG)
	docker tag quay.io/citrix/citrix-k8s-cpx-ingress:$(CPX_TAG) \
	    "$(REGISTRY)/citrix-adc-cpx:$(TAG)"
	docker tag quay.io/citrix/citrix-k8s-cpx-ingress:$(CPX_TAG) \
            "$(REGISTRY)/citrix-adc-cpx:$(GCP_TAG)"
	docker push "$(REGISTRY)/citrix-adc-cpx:$(TAG)"
	docker push "$(REGISTRY)/citrix-adc-cpx:$(GCP_TAG)"
	@touch "$@"


.build/citrix-adc-cpx/citrix-k8s-ingress-controller: .build/var/REGISTRY \
                    .build/var/TAG \
                    | .build/citrix-adc-cpx
	docker pull quay.io/citrix/citrix-k8s-ingress-controller:$(TAG)
	docker tag quay.io/citrix/citrix-k8s-ingress-controller:$(TAG) \
	    "$(REGISTRY)/citrix-adc-cpx/citrix-k8s-ingress-controller:$(TAG)"
	docker push "$(REGISTRY)/citrix-adc-cpx/citrix-k8s-ingress-controller:$(TAG)"
	@touch "$@"


.build/citrix-adc-cpx/exporter: .build/var/REGISTRY \
                    .build/var/TAG \
                    | .build/citrix-adc-cpx
	docker pull quay.io/citrix/citrix-adc-metrics-exporter:$(EXPORTER_TAG)
	docker tag quay.io/citrix/citrix-adc-metrics-exporter:$(EXPORTER_TAG) \
	    "$(REGISTRY)/citrix-adc-cpx/citrix-adc-metrics-exporter:$(TAG)"
	docker push "$(REGISTRY)/citrix-adc-cpx/citrix-adc-metrics-exporter:$(TAG)"
	@touch "$@"


.build/citrix-adc-cpx/tester: .build/var/TESTER_IMAGE \
                     $(shell find apptest -type f) \
                     | .build/citrix-adc-cpx
	$(call print_target,$@)
	cd apptest/tester \
	    && docker build --tag "$(TESTER_IMAGE)" .
	docker push "$(TESTER_IMAGE)"
	@touch "$@"
