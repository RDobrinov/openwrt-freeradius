#!/bin/bash

# SPDX-FileCopyrightText: 2025 Rossen Dobrinov
#
# SPDX-License-Identifier: Apache-2.0

# Apple Configuration Profile Generator Script
# Creates a .mobileconfig file for EAP-TLS with WPA2/WPA3 Enterprise Wi-Fi encryption.

show_help() {
    echo "Usage: $0 --ssid <SSID> --p12 <P12_FILE> --ca_cert <CA_CERT_FILE> --p12-password <PASSWORD> --radius-server <HOSTNAME> [--output <OUTPUT_FILE>]"
    echo ""
    echo "Params:"
    echo "  --ssid <string>        WIFI SSID"
    echo "  --p12 <filename>       PKCS#12 Certificate bundle filename"
    echo "  --ca_cert <filename>   Root CA Cerificate file name"
    echo "  --p12-password <pass>  PKCS#12 bundle password"
    echo "  --radius-server <host> Radius server hostname"
    echo "  --output <filename>    Output filename (default <bundle filename>.mobileconfig)"
    echo "  --help                 This help message"
    echo ""
    echo "Example:"
    echo "  $0 --ssid \"MyWiFi\" --p12 client.p12 --ca_cert ca.crt --p12-password \"secret123\" --radius-server \"radius.company.com\""
}

SSID=""
P12_FILE=""
CA_CERT_FILE=""
P12_PASSWORD=""
RADIUS_SERVER=""
OUTPUT_FILE=""

# Arguments parsing
while [[ $# -gt 0 ]]; do
    case $1 in
        --ssid)
            SSID="$2"
            shift 2
            ;;
        --p12)
            P12_FILE="$2"
            if [[ -z "$OUTPUT_FILE" ]]; then
                OUTPUT_FILE="${P12_FILE%.*}.mobileconfig"
            fi
            shift 2
            ;;
        --ca_cert)
            CA_CERT_FILE="$2"
            shift 2
            ;;
        --p12-password)
            P12_PASSWORD="$2"
            shift 2
            ;;
        --radius-server)
            RADIUS_SERVER="$2"
            shift 2
            ;;
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown parameter $1"
            show_help
            exit 1
            ;;
    esac
done

# Check Mandatory Params
if [[ -z "$SSID" || -z "$P12_FILE" || -z "$CA_CERT_FILE" || -z "$P12_PASSWORD" || -z "$RADIUS_SERVER" ]]; then
    echo "Error: Missing params!"
    show_help
    exit 1
fi

# Check filenames
if [[ ! -f "$P12_FILE" ]]; then
    echo "Error: P12 file '$P12_FILE' not found!"
    exit 1
fi

if [[ ! -f "$CA_CERT_FILE" ]]; then
    echo "Error: CA file '$CA_CERT_FILE' not found!"
    exit 1
fi

# Base64 Encoding
P12_BASE64=$(base64 -w 0 "$P12_FILE")
CA_CERT_BASE64=$(base64 -w 0 "$CA_CERT_FILE")

# Gen UUIDs
CLIENT_UUID=$(uuidgen)
CA_UUID=$(uuidgen)
WIFI_UUID=$(uuidgen)
PROFILE_UUID=$(uuidgen)

# Create Apple configuration profile
cat > "$OUTPUT_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>PayloadContent</key>
  <array>
    <!-- PKCS#12 Certificate bundle -->
    <dict>
      <key>PayloadCertificateFileName</key>
      <string>$(basename "$P12_FILE")</string>
      <key>PayloadContent</key>
      <data>${P12_BASE64}</data>
      <key>PayloadDescription</key>
      <string>Client Certificate</string>
      <key>PayloadDisplayName</key>
      <string>Client Certificate</string>
      <key>PayloadIdentifier</key>
      <string>com.example.cert.client</string>
      <key>PayloadType</key>
      <string>com.apple.security.pkcs12</string>
      <key>PayloadUUID</key>
      <string>${CLIENT_UUID}</string>
      <key>PayloadVersion</key>
      <integer>1</integer>
      <key>Password</key>
      <string>${P12_PASSWORD}</string>
    </dict>
    <!-- Root CA -->
    <dict>
      <key>PayloadCertificateFileName</key>
      <string>$(basename "$CA_CERT_FILE")</string>
      <key>PayloadContent</key>
      <data>${CA_CERT_BASE64}</data>
      <key>PayloadDescription</key>
      <string>CA Certificate</string>
      <key>PayloadDisplayName</key>
      <string>CA Certificate</string>
      <key>PayloadIdentifier</key>
      <string>com.example.cert.ca</string>
      <key>PayloadType</key>
      <string>com.apple.security.root</string>
      <key>PayloadUUID</key>
      <string>${CA_UUID}</string>
      <key>PayloadVersion</key>
      <integer>1</integer>
    </dict>
    <!-- WiFi WPA2/WPA3-Enterprise Profile -->
    <dict>
      <key>AutoJoin</key>
      <true/>
      <key>EncryptionType</key>
      <string>WPA</string>
      <key>HIDDEN_NETWORK</key>
      <false/>
      <key>SSID_STR</key>
      <string>${SSID}</string>
      <key>PayloadDisplayName</key>
      <string>Wi-Fi Enterprise</string>
      <key>PayloadIdentifier</key>
      <string>com.example.wifi</string>
      <key>PayloadType</key>
      <string>com.apple.wifi.managed</string>
      <key>PayloadUUID</key>
      <string>${WIFI_UUID}</string>
      <key>PayloadVersion</key>
      <integer>1</integer>
      <key>ProxyType</key>
      <string>None</string>
      <key>SecurityType</key>
      <string>WPA</string>
      <key>EAPClientConfiguration</key>
      <dict>
        <key>AcceptEAPTypes</key>
        <array>
          <integer>13</integer>
        </array>
        <key>PayloadCertificateUUID</key>
        <string>${CLIENT_UUID}</string>
        <key>TrustedServerNames</key>
        <array>
          <string>${RADIUS_SERVER}</string>
        </array>
        <key>TLSAllowTrustExceptions</key>
        <false/>
        <key>TLSCertificateIsRequired</key>
        <true/>
      </dict>
      <key>TLSTrustedServerNames</key>
      <array>
        <string>${RADIUS_SERVER}</string>
      </array>
      <key>TrustedCertificates</key>
      <array>
        <string>${CA_UUID}</string>
      </array>
    </dict>
  </array>
  <!-- Profile information-->
  <key>PayloadDisplayName</key>
  <string>WPA2/3 Enterprise Wi-Fi</string>
  <key>PayloadIdentifier</key>
  <string>com.example.profile.enterprise</string>
  <key>PayloadRemovalDisallowed</key>
  <false/>
  <key>PayloadType</key>
  <string>Configuration</string>
  <key>PayloadUUID</key>
  <string>${PROFILE_UUID}</string>
  <key>PayloadVersion</key>
  <integer>1</integer>
</dict>
</plist>
EOF

echo ""
echo "Apple Configuration Profile Generator ver 1.0.3 (c)"
echo "SSID:                 $SSID"
echo "Certificate bundle:   $P12_FILE"
echo "Root CA:              $CA_CERT_FILE"
echo "RADIUS server:        $RADIUS_SERVER"
echo "Clinet UUID:          $CLIENT_UUID"
echo "CA UUID:              $CA_UUID"
echo "WiFi UUID:            $WIFI_UUID"
echo "Profile UUID          $PROFILE_UUID"
echo "Output file:          $OUTPUT_FILE"
echo ""
echo "Apple configuration profile $OUTPUT_FILE created"
