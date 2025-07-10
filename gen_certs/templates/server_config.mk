# root_ca_config.mk
define SERVER_CONFIG
#server.cnf
[ req ]
prompt = no
distinguished_name = server

[ server ]
countryName = $(COUNTRY)
organizationName = $(ORG)
commonName = $(SERVER_CN)
#emailAddress = $(EMAIL)

[ v3_server ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always,issuer:always

[alt_names]
DNS.1 = $(SERVER_CN)

# NAIRealm from RFC 7585
otherName.0 = 1.3.6.1.5.5.7.8.8;FORMAT:UTF8,UTF8:*.$(DOMAIN)
endef
