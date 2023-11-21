#!/bin/bash

CA_FILE_NAME="k3s-public-ca"
ROOT_DOMAIN="k3d.internal"
CA_CN="public-ca.${ROOT_DOMAIN}"

# CA
if [ ! -f "${CA_FILE_NAME}-key.pem" ]
then
  openssl genrsa -out ${CA_FILE_NAME}-key.pem 4096
  openssl req -x509 -new -nodes -key ${CA_FILE_NAME}-key.pem -sha256 -days 1826 -out ${CA_FILE_NAME}.pem -subj "/CN=${CA_CN}/C=PT/ST=Braga/L=Famalicao/O=Casa"
fi

#N_CERTS=3

# # Certificado
# openssl genrsa -out ${DOMAIN}-key.pem 4096
# openssl req -new -key ${DOMAIN}-key.pem -out ${DOMAIN}.csr -subj "/CN=${DOMAIN}/C=PT/ST=Braga/L=Famalicao/O=Casa"

# cat > ${DOMAIN}.ext <<- EOF
# authorityKeyIdentifier=keyid,issuer
# basicConstraints=CA:FALSE
# keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
# subjectAltName = @alt_names
# [alt_names]
# IP.1 = 127.0.0.1
# DNS.1 = localhost
# DNS.2 = ${DOMAIN}
# EOF

# ncert=0
# while [ $ncert -lt $N_CERTS ]
# do
# cat >> ${DOMAIN}.ext <<- EOF
# DNS.$(( $ncert + 3 )) = vault-${ncert}.vault-internal
# EOF
#   ncert=$(( $ncert + 1 ))
# done

# openssl x509 -req -in ${DOMAIN}.csr -CA ${CA_FILE_NAME}.pem -CAkey ${CA_FILE_NAME}-key.pem -CAcreateserial -out ${DOMAIN}.pem -days 825 -sha256 -extfile ${DOMAIN}.ext 
