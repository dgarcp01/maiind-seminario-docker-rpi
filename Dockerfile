# Se parte de la imagen oficial
FROM nodered/node-red

# Cambio a usuario a root
USER root

# Instalación ependencias del sistema
RUN apk add --no-cache \
    openssl \
    ca-certificates \
    python3 \
    make \
    g++

# Nuevo certificado en 
RUN mkdir -p /data/opcua/certificates && \
    printf "[req]\nprompt=no\ndistinguished_name=dn\nx509_extensions=v3\n\n[dn]\nCN=NodeRED-OPCUA\n\n[v3]\nsubjectAltName=URI:urn:NodeRED-OPCUA\n" > /tmp/opcua.cnf && \
    openssl req -x509 -newkey rsa:2048 -nodes \
      -keyout /data/opcua/certificates/server_key_2048.pem \
      -out /data/opcua/certificates/server_selfsigned_cert_2048.pem \
      -days 3650 \
      -config /tmp/opcua.cnf \
      -extensions v3 && \
    chown -R node-red:node-red /data/opcua

# Cambio usuario node-red
USER node-red

# Se establece el directorio en data
WORKDIR /data

# Se copian la lista de dependencias
COPY package.json /data

# Instalación de las dependencias
RUN npm install --no-update-notifier --no-fund --only=production


# Se establece el directorio de trabajo a node-red (inicio del programa)
WORKDIR /usr/src/node-red

# Se copian los flows y configuraciones.
COPY flows.json /data/flows.json
COPY settings.js /data/settings.js