# Elliptic curve SSL Certificates Makefile

# Default params
ROOT_CN ?= FreeRadius CA
SERVER_CN ?= radius.private.network
DEVICE_CN ?= My Device
COUNTRY ?= BG
ORG ?= Private Network
EMAIL ?= my_device@private.network
DAYS ?= 3650
CURVE ?= prime256v1
PKCS_PASS ?= 1234
DOMAIN = $(shell echo $(SERVER_CN) | sed 's/^[^.]*\.//')

empty :=
space := $(empty) $(empty)

# Root CA files
ROOT = $(subst $(space),_,$(ROOT_CN))
CA_DIR ?= $(ROOT)
ROOT_CA_KEY = $(CA_DIR)/$(ROOT).key
ROOT_CA_CRT = $(CA_DIR)/$(ROOT).crt
ROOT_CA_CNF = $(CA_DIR)/$(ROOT).cnf

# Server files
SERVER_DIR ?= $(CA_DIR)/$(SERVER_CN)
SERVER_KEY = $(SERVER_DIR)/$(SERVER_CN).key
SERVER_CSR = $(SERVER_DIR)/$(SERVER_CN).csr
SERVER_CRT = $(SERVER_DIR)/$(SERVER_CN).crt
SERVER_CNF = $(SERVER_DIR)/$(SERVER_CN).cnf

# Client files
# Дефинирайте space
DEVICE_DNS = $(subst $(space),_,$(DEVICE_CN))
DEVICE_DIR ?= $(CA_DIR)/$(DEVICE_DNS)
DEVICE_KEY = $(DEVICE_DIR)/$(DEVICE_DNS).key
DEVICE_CSR = $(DEVICE_DIR)/$(DEVICE_DNS).csr
DEVICE_CRT = $(DEVICE_DIR)/$(DEVICE_DNS).crt
DEVICE_CNF = $(DEVICE_DIR)/$(DEVICE_DNS).cnf
DEVICE_PKCS = $(DEVICE_DIR)/$(DEVICE_DNS).p12

include templates/root_ca_config.mk
include templates/server_config.mk
include templates/device_config.mk

default: help

root_ca: create-root-ca-config $(ROOT_CA_KEY) $(ROOT_CA_CRT)

$(ROOT_CA_KEY):
	@if [ -f $(ROOT_CA_KEY) ]; then \
		echo "$(ROOT_CA_KEY) already exists. Skipping."; \
	else \
		openssl ecparam -name $(CURVE) -genkey -noout -out $(ROOT_CA_KEY); \
		echo "Root CA private key $(ROOT_CA_KEY) created"; \
	fi
$(ROOT_CA_CRT): $(ROOT_CA_KEY) $(ROOT_CA_CNF)
	@if [ -f $(ROOT_CA_CRT) ]; then \
		echo "$(ROOT_CA_CRT) already exists. Skipping."; \
	else \
		openssl req -x509 -new -nodes -key $(ROOT_CA_KEY) -sha256 -days $(DAYS) -out $(ROOT_CA_CRT) -config $(ROOT_CA_CNF) -extensions v3_ca; \
		echo "Self signed Root CA certificate $(ROOT_CA_CRT) created"; \
	fi

$(ROOT_CA_CNF): create-root-ca-config

server_cert: create-server-config $(SERVER_KEY) $(SERVER_CRT)

$(SERVER_KEY):
	@if [ -f $(SERVER_KEY) ]; then \
		echo "$(SERVER_KEY) already exists. Skipping."; \
	else \
		openssl ecparam -name $(CURVE) -genkey -noout -out $(SERVER_KEY); \
		echo "Server Private key $(SERVER_KEY) created"; \
	fi

$(SERVER_CSR): $(SERVER_KEY) $(SERVER_CNF)
	@if [ -f $(SERVER_CSR) ]; then \
		echo "$(SERVER_CSR) already exists. Skipping."; \
	else \
		openssl req -new -sha256 -key $(SERVER_KEY) -out $(SERVER_CSR) -config $(SERVER_CNF); \
		echo "Certificate Signing Request $(SERVER_CSR) created"; \
	fi

$(SERVER_CRT): $(SERVER_CSR) $(ROOT_CA_CRT) $(ROOT_CA_KEY)
	@if [ -f $(SERVER_CRT) ]; then \
		echo "$(SERVER_CRT) already exists. Skipping."; \
	else \
		openssl x509 -req -in $(SERVER_CSR) -CA $(ROOT_CA_CRT) -CAkey $(ROOT_CA_KEY) -CAcreateserial -out $(SERVER_CRT) -days $(DAYS) -sha256 -extfile $(SERVER_CNF) -extensions v3_server; \
		echo "Server Certificate $(SERVER_CRT) created"; \
		/bin/cp -rf $(SERVER_CRT) $(CA_DIR)/server_certs; \
		/bin/cp -rf $(SERVER_KEY) $(CA_DIR)/server_certs; \
		/bin/cp -rf $(ROOT_CA_CRT) $(CA_DIR)/server_certs; \
		echo "Server certificates package created in $(CA_DIR)/server_certs directory."; \
		echo "Copy this package to freeradius3 certs directory and restart server"; \
	fi

device_cert: create-device-config $(DEVICE_KEY) $(DEVICE_CRT) $(DEVICE_PKCS)

$(DEVICE_KEY):
	@if [ -f $(DEVICE_KEY) ]; then \
		echo "$(DEVICE_KEY) already exists. Skipping."; \
	else \
		openssl ecparam -name $(CURVE) -genkey -noout -out $(DEVICE_KEY); \
		echo "Device Private key $(DEVICE_KEY) created"; \
	fi

$(DEVICE_CSR): $(DEVICE_KEY) $(DEVICE_CNF)
	@if [ -f $(DEVICE_CSR) ]; then \
		echo "$(DEVICE_CSR) already exists. Skipping."; \
	else \
		openssl req -new -sha256 -key $(DEVICE_KEY) -out $(DEVICE_CSR) -config $(DEVICE_CNF); \
		echo "Certificate Signing Request $(DEVICE_CSR) created"; \
	fi

$(DEVICE_CRT): $(DEVICE_CSR) $(ROOT_CA_CRT) $(ROOT_CA_KEY)
	@if [ -f $(DEVICE_CRT) ]; then \
		echo "$(DEVICE_CRT) already exists. Skipping."; \
	else \
		openssl x509 -req -in $(DEVICE_CSR) -CA $(ROOT_CA_CRT) -CAkey $(ROOT_CA_KEY) -CAcreateserial -out $(DEVICE_CRT) -days $(DAYS) -sha256 -extfile $(DEVICE_CNF) -extensions v3_client; \
		echo "Device Certificate $(DEVICE_CRT) created"; \
	fi

$(DEVICE_PKCS): $(DEVICE_CRT) $(ROOT_CA_CRT) $(DEVICE_KEY)
	@if [ -f $(DEVICE_PKCS) ]; then \
		echo "$(DEVICE_PKCS) already exists. Skipping."; \
	else \
		openssl pkcs12 -export -inkey $(DEVICE_KEY) -in $(DEVICE_CRT) -certfile $(ROOT_CA_CRT) -name "$(DEVICE_CN) WiFi Cert" -out $(DEVICE_DIR)/$(DEVICE_DNS).p12 -passout pass:$(PKCS_PASS); \
		echo "Device PKCS#12 bundle $(DEVICE_CRT) created"; \
		/bin/cp -rf $(ROOT_CA_CRT) $(CA_DIR)/device_certs; \
		/bin/cp -rf $(DEVICE_PKCS) $(CA_DIR)/device_certs; \
		echo "Android certificates package created in $(CA_DIR)/device_certs directory"; \
	fi

create-root-ca-config:
	$(shell mkdir -p $(CA_DIR))
	$(file > $(ROOT_CA_CNF),$(ROOT_CA_CONFIG))

create-server-config:
	$(shell mkdir -p $(SERVER_DIR))
	$(shell mkdir -p $(CA_DIR)/server_certs)
	$(file > $(SERVER_DIR)/$(SERVER_CN).cnf,$(SERVER_CONFIG))

create-device-config:
	$(shell mkdir -p $(DEVICE_DIR))
	$(shell mkdir -p $(CA_DIR)/device_certs)
	$(file > $(DEVICE_DIR)/$(DEVICE_DNS).cnf,$(DEVICE_CONFIG))

help:
	@echo "SSL Elliptic Curve Certificates Makefile for WPA2/WPA3 Enterprise EAP-TLS method Authentication"
	@echo ""
	@echo "Usage:"
	@echo "  make [target] [PARAMETER=value]"
	@echo ""
	@echo "Targets:"
	@echo "  root_ca		- Create Root CA"
	@echo "  server_cert		- Create Server Certificate"
	@echo "  device_cert		- Create Device Cetrificate"
	@echo ""
	@echo "Parameters: "
	@echo "  ROOT_CN		- Root CA Common Name"
	@echo "  SERVER_CN		- Radius Server Common Name"
	@echo "  DEVICE_CN		- Device Common name"
	@echo "  COUNTRY		- Country Code"
	@echo "  ORG			- Organzation Name"
	@echo "  EMAIL			- Email address for device ovner"
	@echo "  DAYS			- Validity days (default 3650)"
	@echo "  CURVE			- Elliptic curve (default prime256v1)"
	@echo "  PKCS_PASS		- Password for PKCS#12 Certificates Bundle (default 1234)"
	@echo ""
	@echo "Examples:"
	@echo "  make"
	@echo "  make server_cert"
	@echo "  make device_cert DEVICE_CN=\"One+ Phone\""

.PHONY: root_ca server_cert device_cert create-root-ca-config create-server-config create-device-config help
