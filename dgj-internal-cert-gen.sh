# Based on https://docs.oracle.com/javase/8/docs/technotes/tools/windows/keytool.html
# Marcin Woźniak (DGJUST-e-Evidence-ServiceDesk@atos.net)
rootCN="rootca"
rootOU="Atos GDC"
rootO="Atos"
rootL="Wrocław"
rootC="PL"
storepwd="changeit"
#####################################################################
#Todo
#Make sure we have keytool installed

# Dev purpose
rm keystore.jks

# Create jks and generate root
keytool -genkeypair \
	-alias rootca \
	-keyalg RSA \
	-keysize 4096 \
	-keystore keystore.jks \
	-validity 1095 \
	-dname "CN=testca, OU=Atos GDC, O=Atos, L=Wrocław, C=PL" \
	-storetype JKS \
	-storepass password \
	-ext BasicConstraints=ca:true \
	-ext KeyUsage=keyCertSign,cRLSign \
	-keypass password

# Create and sign intermediate
keytool -genkeypair \
	-alias IntermediateCA \
	-keyalg RSA \
	-keysize 4096 \
	-keystore keystore.jks \
	-validity 1095 \
	-dname "CN=testca, OU=Atos GDC, O=Atos, L=Wrocław, C=PL" \
	-storetype JKS \
	-storepass password \
	-ext BasicConstraints=ca:true \
	-ext KeyUsage=keyCertSign,cRLSign \
	-keypass password | 
keytool -gencert \
	-alias rootca \
	-keystore keystore.jks \
	-storepass password \
	-ext BC=0 \
	-rfc > ca.pem
keytool -importcert \
	-keystore ca.jks \
	-alias ca \
	-file ca.pem



#keytool -certreq \
#	-alias IntermediateCA \
#	-keystore keystore.jks \
#	-storepass password \
#	-file intermediate.csr

#keytool -gencert \
#	-keystore keystore.jks \
#	-storepass password \
#	-alias rootca \
#	-infile intermediate.csr \
#	-outfile intermediate.cer















#Intellisense ;)
#keytool
# -certreq            Generates a certificate request
# -changealias        Changes an entry's alias
# -delete             Deletes an entry
# -exportcert         Exports certificate
# -genkeypair         Generates a key pair
# -genseckey          Generates a secret key
# -gencert            Generates certificate from a certificate request
# -importcert         Imports a certificate or a certificate chain
# -importpass         Imports a password
# -importkeystore     Imports one or all entries from another keystore
# -keypasswd          Changes the key password of an entry
# -list               Lists entries in a keystore
# -printcert          Prints the content of a certificate
# -printcertreq       Prints the content of a certificate request
# -printcrl           Prints the content of a CRL file
# -storepasswd        Changes the store password of a keystore


#keytool -genkeypair [OPTION]...
#Generates a key pair
#Options:
#
# -alias <alias>                  alias name of the entry to process
# -keyalg <keyalg>                key algorithm name
# -keysize <keysize>              key bit size
# -sigalg <sigalg>                signature algorithm name
# -destalias <destalias>          destination alias
# -dname <dname>                  distinguished name
# -startdate <startdate>          certificate validity start date/time
# -ext <value>                    X.509 extension
# -validity <valDays>             validity number of days
# -keypass <arg>                  key password
# -keystore <keystore>            keystore name
# -storepass <arg>                keystore password
# -storetype <storetype>          keystore type
# -providername <providername>    provider name
# -providerclass <providerclass>  provider class name
# -providerarg <arg>              provider argument
# -providerpath <pathlist>        provider classpath
# -v                              verbose output
# -protected                      password through protected mechanism