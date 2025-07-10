# root_ca_config.mk
define DEVICE_CONFIG
[ req ]
prompt = no
distinguished_name = client_cert_dn

[ client_cert_dn ]
countryName = $(COUNTRY)
organizationName = $(ORG)
#emailAddress = $(EMAIL)
commonName = $(DEVICE_CN)

[ v3_client ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
subjectAltName = DNS:$(DEVICE_DNS).$(DOMAIN), email:$(EMAIL)
endef
