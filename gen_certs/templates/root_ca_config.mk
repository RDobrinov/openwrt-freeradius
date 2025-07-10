# root_ca_config.mk
define ROOT_CA_CONFIG
[ req ]
prompt = no
distinguished_name = root_ca_dn
string_mask = utf8only

[ root_ca_dn ]
countryName = $(COUNTRY)
organizationName = $(ORG)
commonName = $(ROOT_CN)
#emailAddress = $(EMAIL)

[ v3_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always
basicConstraints = critical, CA:TRUE
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ ca ]
default_ca = CA_default

[ CA_default ]
dir = ./
certs = $$dir
new_certs_dir = $$dir
database = $$dir/index.txt
serial = $$dir/serial
default_md = sha256
default_days = 365
preserve = no
policy = policy_strict

[ policy_strict ]
countryName = match
stateOrProvinceName = optional
organizationName = match
organizationalUnitName = optional
commonName = supplied
emailAddress = optional

[ policy_anything ]
countryName = optional
stateOrProvinceName = optional
organizationName = optional
organizationalUnitName = optional
commonName = optional
emailAddress = optional
endef
