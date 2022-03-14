#!/bin/bash
# Creates set of keystores for use in e-Evidence Digital Exchange System
# Documentation https://docs.oracle.com/en/java/javase/12/tools/keytool.html
# Marcin Woźniak (DGJUST-e-Evidence-ServiceDesk@atos.net)

# Java 15 is required to use wildcards in SubjectAlternativeName DNS
# https://bugs.openjdk.java.net/browse/JDK-8186143
# https://stackoverflow.com/questions/33827789/self-signed-certificate-dnsname-components-must-begin-with-a-letter

#Todo
#check keytool compatibility acreoss jdk versions
#offer adding root and ca to cacerts?

#####################################################################

# Only OU is required, you can leave the rest empty
OU="Atos GDC"
O="atos"
L="Wrocław"
C="PL"

#Password for keystores. You can change it later
secret1="password"
#Password for keypairs. You can change it later
secret2="password"

gatewayDNS="gateway.domain.com"
connectorDNS="connector.domain.com"
ricaseDNS="ri-case.domain.com"
nginxDNS="nginx.domain.com"

#####################################################################


#Make sure we have keytool installed
if ! command -v keytool >/dev/null 2>&1
then
    echo "Keytool could not be found."
    echo "Install with sudo apt install openjdk-8-jre-headless"
    exit
else

# Clean before each run for dev purpose
#rm *.jks
#rm *.pem

echo Create jks and generate root keypair
keytool -genkeypair \
    -alias rootca \
    -keyalg RSA \
    -keysize 4096 \
    -keystore keystore.jks \
    -validity 1095 \
    -dname "CN=RootCA, OU=$OU, O=$O, L=$L, C=$C" \
    -storetype JKS \
    -storepass $secret1 \
    -ext BasicConstraints:critical=ca:true \
    -ext KeyUsage:critical=keyCertSign,cRLSign \
    -keypass $secret2 2>/dev/null

echo Create intermediate keypair
keytool -genkeypair \
    -alias IntermediateCA \
    -keyalg RSA \
    -keysize 4096 \
    -keystore keystore.jks \
    -dname "CN=IntermediateCA, OU=$OU, O=$O, L=$L, C=$C" \
    -storetype JKS \
    -storepass $secret1 \
    -keypass $secret2 2>/dev/null

echo Create gateway keypair
keytool -genkeypair \
    -alias gateway \
    -keyalg RSA \
    -keysize 2048 \
    -keystore keystore.jks \
    -dname "CN=gateway, OU=$OU, O=$O, L=$L, C=$C" \
    -storetype JKS \
    -storepass $secret1 \
    -keypass $secret2 2>/dev/null

echo Create connector keypair
keytool -genkeypair \
    -alias connector \
    -keyalg RSA \
    -keysize 2048 \
    -keystore keystore.jks \
    -dname "CN=connector, OU=$OU, O=$O, L=$L, C=$C" \
    -storetype JKS \
    -storepass $secret1 \
    -keypass $secret2 2>/dev/null

echo Create ri-case keypair
keytool -genkeypair \
    -alias ri-case \
    -keyalg RSA \
    -keysize 2048 \
    -keystore keystore.jks \
    -dname "CN=ri-case, OU=$OU, O=$O, L=$L, C=$C" \
    -storetype JKS \
    -storepass $secret1 \
    -keypass $secret2 2>/dev/null

echo Create Nginx keypair
keytool -genkeypair \
    -alias 'nginx' \
    -keyalg RSA \
    -keysize 2048 \
    -keystore keystore.jks \
    -dname "CN=$nginxDNS, OU=$OU, O=$O, L=$L, C=$C" \
    -storetype JKS \
    -storepass $secret1 \
    -keypass $secret2 2>/dev/null

echo Export root cert
keytool -exportcert \
    -keystore keystore.jks \
    -storepass $secret1 \
    -alias rootca -rfc > root.pem 2>/dev/null

echo Sign CA 
keytool -certreq \
        -keystore keystore.jks \
        -storepass $secret1 \
        -alias IntermediateCA 2>/dev/null | 
        keytool -gencert \
                -storepass $secret1 \
                -keystore keystore.jks \
                -alias rootca \
                -validity 1095 \
                -ext BC=0 \
                -ext BasicConstraints:critical=ca:true \
                -ext KeyUsage:critical=keyCertSign,cRLSign \
                -rfc > ca.pem 2>/dev/null

cat root.pem ca.pem > cachain.pem 

keytool -importcert \
    -noprompt \
    -keystore keystore.jks \
    -storepass $secret1 \
    -alias intermediateca \
    -file cachain.pem 2>/dev/null


echo Sign gateway
keytool -certreq \
        -storepass $secret1 \
        -keystore keystore.jks \
        -alias gateway 2>/dev/null | 
        keytool -gencert \
                -storepass $secret1 \
                -keystore keystore.jks \
                -validity 1095 \
                -alias intermediateca \
                -ext BasicConstraints=ca:false \
                -ext KeyUsage:critical=digitalSignature,keyEncipherment \
                -ext ExtendedKeyUsage=clientAuth,serverAuth,emailProtection \
                -ext SubjectAlternativeName=DNS:$gatewayDNS,DNS:gateway \
                -rfc > gateway.pem 2>/dev/null

cat root.pem ca.pem gateway.pem > gatewaychain.pem

keytool -importcert \
        -noprompt \
        -keystore keystore.jks \
        -storepass $secret1 \
        -alias gateway \
        -file gatewaychain.pem 2>/dev/null

echo Sign connector
keytool -certreq \
        -storepass $secret1 \
        -keystore keystore.jks \
        -alias connector 2>/dev/null | 
        keytool -gencert \
                -storepass $secret1 \
                -keystore keystore.jks \
                -validity 1095 \
                -alias intermediateca \
                -ext BasicConstraints=ca:false \
                -ext KeyUsage:critical=digitalSignature,keyEncipherment \
                -ext ExtendedKeyUsage=clientAuth,serverAuth,emailProtection \
                -ext SubjectAlternativeName=DNS:$connectorDNS,DNS:connector \
                -rfc > connector.pem 2>/dev/null

cat root.pem ca.pem connector.pem > connectorchain.pem

keytool -importcert \
        -noprompt \
        -keystore keystore.jks \
        -storepass $secret1 \
        -alias connector \
        -file connectorchain.pem 2>/dev/null

echo Sign ri-case
keytool -certreq \
        -storepass $secret1 \
        -keystore keystore.jks \
        -alias ri-case 2>/dev/null | 
        keytool -gencert \
                -storepass $secret1 \
                -keystore keystore.jks \
                -validity 1095 \
                -alias intermediateca \
                -ext BasicConstraints=ca:false \
                -ext KeyUsage:critical=digitalSignature,keyEncipherment \
                -ext ExtendedKeyUsage=clientAuth,serverAuth,emailProtection \
                -ext SubjectAlternativeName=DNS:$ricaseDNS,DNS:ri-case \
                -rfc > ri-case.pem 2>/dev/null

cat root.pem ca.pem ri-case.pem > ri-casechain.pem

keytool -importcert \
        -noprompt \
        -keystore keystore.jks \
        -storepass $secret1 \
        -alias ri-case \
        -file ri-casechain.pem 2>/dev/null

echo Sign nginx
keytool -certreq \
        -storepass $secret1 \
        -keystore keystore.jks \
        -alias nginx 2>/dev/null | 
        keytool -gencert \
                -storepass $secret1 \
                -keystore keystore.jks \
                -validity 1095 \
                -alias intermediateca \
                -ext BasicConstraints=ca:false \
                -ext KeyUsage:critical=digitalSignature,keyEncipherment \
                -ext ExtendedKeyUsage=clientAuth,serverAuth,emailProtection \
                -ext SubjectAlternativeName=DNS:$nginxDNS,DNS:nginx \
                -rfc > nginx.pem 2>/dev/null

cat root.pem ca.pem nginx.pem > nginxchain.pem

keytool -importcert \
        -noprompt \
        -keystore keystore.jks \
        -storepass $secret1 \
        -alias nginx \
        -file nginxchain.pem 2>/dev/null


echo 01-ri_keystore.jks
keytool -importkeystore -srckeystore keystore.jks -srcstorepass $secret1 -destkeystore "01-ri_keystore.jks" -deststorepass $secret1 -srcalias ri-case -srckeypass $secret2  -destalias ri-case  -destkeypass $secret2 2>/dev/null
keytool -exportcert -keystore keystore.jks -storepass $secret1 -alias connector -rfc -file conexp.pem 2>/dev/null
keytool -importcert -noprompt -keystore "01-ri_keystore.jks" -storepass $secret1 -alias connector -file conexp.pem 2>/dev/null

echo 02-connector_backend_keystore.jks
keytool -importkeystore -srckeystore keystore.jks -srcstorepass $secret1 -destkeystore "02-connector_backend_keystore.jks" -deststorepass $secret1 -srcalias connector -srckeypass $secret2  -destalias connector -destkeypass $secret2 2>/dev/null

echo 02-connector_backend_truststore.jks
keytool -exportcert -keystore keystore.jks -storepass $secret1 -alias ri-case -rfc -file ri-caseexp.pem 2>/dev/null
keytool -importcert -noprompt -keystore 02-connector_backend_truststore.jks -storepass $secret1 -alias ri-case -file ri-caseexp.pem 2>/dev/null

echo 03-connector_evidence_keystore.jks
keytool -importkeystore -srckeystore keystore.jks -srcstorepass $secret1 -destkeystore "03-connector_evidence_keystore.jks" -deststorepass $secret1 -srcalias connector -srckeypass $secret2  -destalias connector -destkeypass $secret2 2>/dev/null

echo 04-connector_security_keystore.jks
keytool -importkeystore -srckeystore keystore.jks -srcstorepass $secret1 -destkeystore "04-connector_security_keystore.jks" -deststorepass $secret1 -srcalias connector -srckeypass $secret2  -destalias connector -destkeypass $secret2 2>/dev/null

echo 04-connector_security_truststore.jks
keytool -importcert -noprompt -keystore "04-connector_security_truststore.jks" -storepass $secret1 -alias connector -file conexp.pem 2>/dev/null

echo 05-connector_gatewaylink_keystore.jks
keytool -importkeystore -srckeystore keystore.jks -srcstorepass $secret1 -destkeystore "05-connector_gatewaylink_keystore.jks" -deststorepass $secret1 -srcalias connector -srckeypass $secret2  -destalias connector -destkeypass $secret2 2>/dev/null

echo 05-connector_gatewaylink_truststore.jks
keytool -exportcert -keystore keystore.jks -storepass $secret1 -alias gateway -rfc -file gwexp.pem 2>/dev/null
keytool -importcert -noprompt -keystore "05-connector_gatewaylink_truststore.jks" -storepass $secret1 -alias gateway -file gwexp.pem 2>/dev/null

echo 06-gateway_connectorlink_keystore.jks
keytool -importkeystore -srckeystore keystore.jks -srcstorepass $secret1 -destkeystore "06-gateway_connectorlink_keystore.jks" -deststorepass $secret1 -srcalias gateway -srckeypass $secret2  -destalias gateway -destkeypass $secret2 2>/dev/null

echo 06-gateway_connectorlink_truststore.jks
keytool -importcert -noprompt -keystore "06-gateway_connectorlink_truststore.jks" -storepass $secret1 -alias connector -file conexp.pem 2>/dev/null

echo 07-gateway_keystore.jks
keytool -importkeystore -srckeystore keystore.jks -srcstorepass $secret1 -destkeystore "07-gateway_keystore.jks" -deststorepass $secret1 -srcalias gateway -srckeypass $secret2  -destalias gateway -destkeypass $secret2 2>/dev/null

echo 07-gateway_truststore.jks
keytool -importcert -noprompt -keystore 07-gateway_truststore.jks -storepass $secret1 -alias gateway -file gwexp.pem 2>/dev/null

directory=dgj.`date +%Y%m%d_%H%M%S`
mkdir $directory
mv *.pem $directory
mv *.jks $directory

echo Done!
fi
exit 1


