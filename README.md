
## Node-RED
- Actualizamos la RPI:
```bash
sudo apt-get update
sudo apt-get upgrade
```

- Eliminación de  node-red

```bash
sudo npm remove -g node-red node-red-admin
rm -R ~/.node-red
```

- Actualizamos npm:

```bash 
sudo npm install -g npm@11.13.0
```

## Instalación de Node-RED en local

- Instalación de node-red
```bash

bash <(curl -sL https://github.com/node-red/linux-installers/releases/latest/download/update-nodejs-and-nodered-deb)
```

- Iniciar y probar el nuevo node-red
```bash 
node-red-pi --max-old-space-size=256
```


- Comprobar el servicio de Node-RED:

```bash
sudo systemctl status nodered
```

- Parar el servicio de Node-RED:

```bash
sudo systemctl stop nodered
```




## Instalación de Docker en RPI

Instalar docker
```
curl -fsSL https://get.docker.com -o get-docker.sh  
sudo sh get-docker.sh
sudo usermod -aG docker $USER
sudo reboot
```

## Portainer
Instalar portainer
```bash
docker run -d -p 9000:9000 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce
```

Portainer estará disponible en [https://ip_RPI:9000]()

- **User**: admin
- **Password**: Maiind-Portainer


# Despligue de apps node-RED mediante contenedores Docker


El programa de node-RED implementado en el entorno de desarrollo (PC) se puede desplegar directamente en la RPI de producción mediante un contenedor *Docker*. Sin necesidad de instalar las dependencias, ni node-RED. 

Para desplegar la aplicación de node-RED en un contenedor, debemos crear primero un imagen a partir de la imagen oficial de node-red en Docker Hub.

En esta nueva imagen debe contener:

- El flujo(s) del entorno de desarrollo a desplegar.
- Sus dependencias.
- Certificados OPC-UA.


El flujo lo exportamos con la opción de export directamente desde el programa de node-RED.

Las dependencias las obtenemos del archivo: 

```bash
C:\Users\TU_USUARIO\.node-red\package.json
```
El archivo package.json tiene una estructura como la siguiente:

```json
{
    "name": "node-red-project",
    "description": "A Node-RED Project",
    "version": "0.0.1",
    "private": true,
    "dependencies": {
        "node-red-contrib-buffer-parser": "~3.2.2",
        "node-red-contrib-modbus": "~5.44.1",
        "node-red-contrib-opcua-server": "~1.1.1"
    }
}

```


Estos dos archivos los vamos a mover a la RPI con un cliente SFTP: Filezilla, VSCode (extension Remote-SSH).





### Crear imagen de Docker en RPI

Las imágenes de Docker se crean desde un archivo de Docker. Este archivo indica qué cambios se realizan a la imagen oficial de node-RED.

```Dockerfile
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
    openssl req -x509 -newkey rsa:2048 -nodes \
      -keyout /data/opcua/certificates/server_key_2048.pem \
      -out /data/opcua/certificates/server_selfsigned_cert_2048.pem \
      -days 3650 \
      -sha256 \
      -subj "/C=ES/L=Madrid/O=Universidad/CN=NodeRED-OPCUA" && \
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
```

La imagen se crea con el comando:

```bash
docker build -t opc-nodered-v1 .
```
Una vez creada podemos comprobar su estado en Portainer.
NOTA: Tarda varios minutos.

### Ejecutar el contenedor
Para crear el contenerdor y ejecutarlo es necesario el siguiente comando:

```bash
docker run -d  --name opc-nodered  -p 1880:1880 -p 54840:54840   opc-nodered-v1
```

El estado del contenedor se puede comprobar en portainer. 

Si todo ha ido bien:

- En [http:/ip_RPI:1880]() estará escuchando el editor de node-RED.
- En [tcp.opc:/ip_RPI:54840]() estará escuchando el servidor OPC-UA.



