
# FreeRADIUS Setup for OpenWRT Router

This guide explains how to configure FreeRADIUS for WPA2/WPA3 EAP WiFi encryption. It includes everything needed to generate the required certificates and a minimal configuration to start EAP-TLS authentication.

---

## Installation

Download the folders `minimum_conf` and `gen_certs` to your computer, or clone the repository.

### On the OpenWRT Router

1. Install `hostapd-wolfssl` or `hostapd-openssl`. These are required for WPA2/WPA3 Enterprise WiFi encryption.
2. Install the following packages:
   - `freeradius3`
   - `freeradius3-common`
   - `freeradius3-mod-eap`
   - `freeradius3-mod-eap-tls`

---

## Disable and Stop the Radius Service

```sh
/etc/init.d/radiusd disable
/etc/init.d/radiusd stop
```

---

## Clean the Default Configuration

You may remove everything from `/etc/freeradius3` **except**:

- `certs`
- `clients.conf`
- `mods-available`
- `mods-enabled`
- `policy.d`
- `radiusd.conf`
- `sites-available`
- `sites-enabled`

Delete the contents of these folders:

- `mods-available`
- `mods-enabled`
- `policy.d`
- `sites-available`
- `sites-enabled`

Copy the contents of the `minimum_conf` folder into the corresponding folders in `/etc/freeradius3`.

Also copy `radiusd.conf` and `clients.conf`.

---

## Configure Clients

Edit `clients.conf` and add your RADIUS clients with their shared secrets. The sample file includes an example for the router and an additional WiFi access point. Use them as a template.

> No need to modify `radiusd.conf`.

Create a symbolic link:

```sh
cd /etc/freeradius3
ln -s ../sites-available/tiny-eap-tls sites-enabled/tiny-eap-tls
```

Expected output:

```sh
root@mt6000:/etc/freeradius3# ls -la sites-enabled/
drwxr-xr-x    2 root     root          3488 Jul  9 16:45 .
drwxr-xr-x    8 root     root          3488 Jul  9 17:12 ..
lrwxrwxrwx    1 root     root            31 Jul  9 16:45 tiny-eap-tls -> ../sites-available/tiny-eap-tls
```

---

## Generate Certificates

### On Your Computer

Edit the `Makefile` to set default values or run `make` with parameters.

Default values in `Makefile`:

```makefile
ROOT_CN ?= FreeRadius CA
SERVER_CN ?= radius.private.network
DEVICE_CN ?= My Device
COUNTRY ?= BG
ORG ?= Private Network
EMAIL ?= my_device@private.network
DAYS ?= 3650
CURVE ?= prime256v1
PKCS_PASS ?= 1234
```

> The email is used only in device certificates.  
> `SERVER_CN` must be in `name.domain` format for Android compatibility.  
> When setting up Android, use `private.network` as the domain name.

Generate server certificates:

```sh
make server_cert
```

This generates the CA and server certificates in `<ROOT_CN>/server_certs`.  
Copy those to `/etc/freeradius3/certs` on the router.

---

## Configure EAP Module

Edit `mods-available/eap`:

```conf
# Server private key
private_key_file = /etc/freeradius3/certs/radius.private.network.key

# Server certificate
certificate_file = /etc/freeradius3/certs/radius.private.network.crt

# Root CA certificate
ca_file = /etc/freeradius3/certs/FreeRadius_CA.crt
```

Ensure the private key is not encrypted with a password.

---

## Test the Configuration

```sh
radiusd -X
```

---

## Generate Device Certificate

To generate a certificate for a device (example: "My Phone"):

```sh
make device_cert DEVICE_CN="My Phone"
```

The needed files will be located in the `DEVICE_CN` folder and a copy in `device_certs`.  
Copy the `.p12` file and the Root CA certificate to the Android device.

> For iOS devices (iPhone/iPad), use certificates valid for **1 year or less**, and use script `gen_mobileconfig.sh` to create Mobile Configuration File
> Use the 

More info:

```sh
gen_mobileconfig.sh --help
```

> All parameters to `gen_mobileconfig.sh` are mandatory except `--output`.

---

## Notes for Mobile Devices

- On Android, install both the Root CA and the `.p12` file as **WiFi Certificates**.
- Do not use EC curves other than NIST-approved ones.
- Do not include `emailAddress` in the subject of certificates — may be unsupported.
- Always set the domain name to match `SERVER_CN` domain.

---

## Compatibility

This configuration was tested with OpenWRT 24.10.2 on GL.iNet GL-MT6000.
