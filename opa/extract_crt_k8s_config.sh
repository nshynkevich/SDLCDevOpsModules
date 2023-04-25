#!/bin/bash

echo "Extract the Cluster Certificate Authority .. "
kubectl config view --minify --raw --output 'jsonpath={..cluster.certificate-authority-data}' | base64 -d | openssl x509 -text -out - 
kubectl config view --minify --raw --output 'jsonpath={..cluster.certificate-authority-data}' | base64 -d | openssl x509 > cluster-ca.pem

echo "Extract the Client Certificate .. "
kubectl config view --minify --raw --output 'jsonpath={..user.client-certificate-data}' | base64 -d | openssl x509 -text -out -
kubectl config view --minify --raw --output 'jsonpath={..user.client-certificate-data}' | base64 -d | openssl x509 > user.crt

echo "Extract the Client Private Key .. "
kubectl config view --minify --raw --output 'jsonpath={..user.client-key-data}' | base64 -d > user.pem
