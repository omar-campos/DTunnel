#!/bin/bash

# 1. Validar permisos de Root de forma segura
if [[ "$EUID" -ne 0 ]]; then
  echo
  echo "¡Instale como usuario Root!"
  echo
  rm -f "$0"
  exit 1
fi

# 2. Validar versión de Ubuntu
ubuntuV=$(lsb_release -rs 2>/dev/null | cut -d. -f1)

if [[ -z "$ubuntuV" || "$ubuntuV" -lt 20 ]]; then
  clear
  echo "La versión de Ubuntu debe ser mínimo 20, la suya es: ${ubuntuV:-Desconocida}"
  echo
  rm -f "$0"
  exit 1
fi

# 3. Comprobar instalación previa y desinstalación/respaldo
if [[ -e /etc/DTunnel/src/index.ts ]]; then
  clear
  echo "El Panel ya está instalado, ¿desea eliminarlo? (s/n)"
  read -r remo
  if [[ "$remo" =~ ^[sS]$ ]]; then
    cd /etc/DTunnel || exit 1
    rm -rf painelbackup > /dev/null 2>&1
    mkdir -p painelbackup > /dev/null 2>&1
    cp prisma/database.db painelbackup/ 2>/dev/null
    cp .env painelbackup/ 2>/dev/null
    
    tar -czf painelbackup.tar.gz painelbackup 2>/dev/null
    mv painelbackup.tar.gz /root/ 2>/dev/null
    
    pm2 delete ecosystem.config.js > /dev/null 2>&1
    
    rm -rf /etc/DTunnel
    rm -f "$0"
    echo "¡Eliminado con éxito! Respaldo guardado en /root/painelbackup.tar.gz"
    exit 0
  fi
  exit 0
fi

clear
echo "=========================================="
echo "      CONFIGURACIÓN DEL PANEL DTUNNEL     "
echo "=========================================="
echo
echo "Ingrese el IP o Dominio del servidor (ej. panel.midominio.com o 192.168.1.1):"
read -r domain
echo

ip_regex="^([0-9]{1,3}\.){3}[0-9]{1,3}$"

if [[ $domain =~ $ip_regex ]]; then
  echo "Se detectó una dirección IP."
  echo "¿En qué puerto desea activar el panel?"
  read -r porta
  echo
else
  echo "Se detectó un Dominio. Se asignará automáticamente el puerto 80."
  porta=80
  echo
fi

echo "Instalando dependencias del sistema y herramientas de compilación..."
echo
sleep 2

# Actualizar paquetes e instalar dependencias nativas
apt-get update -y
apt-get install wget curl zip unzip cron screen git tar build-essential make gcc g++ python3 -y

# Instalación de Node.js v20 (LTS)
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install nodejs -y

# Herramientas globales de Node.js
npm install -g pm2 typescript ts-node

# Clonar Repositorio
cd /etc/ || exit 1
git clone https://github.com/omar-campos/DTunnel.git
cd /etc/DTunnel || exit 1

chmod +x pon poff pmenu backmod 2>/dev/null
mv pon poff pmenu backmod /bin/ 2>/dev/null

cp .env.example .env 2>/dev/null || touch .env

# Guardar variables de entorno
echo "DOMAIN=$domain" > .env
echo "PORT=$porta" >> .env
echo "NODE_ENV=\"production\"" >> .env
echo "DATABASE_URL=\"file:./database.db\"" >> .env

echo "Generando llaves de seguridad..."
token1=$(node -e "console.log(require('crypto').randomBytes(64).toString('hex'));")
token2=$(node -e "console.log(require('crypto').randomBytes(64).toString('hex'));")
token3=$(node -e "console.log(require('crypto').randomBytes(64).toString('hex'));")
echo "CSRF_SECRET=\"$token1\"" >> .env
echo "JWT_SECRET_KEY=\"$token2\"" >> .env
echo "JWT_SECRET_REFRESH=\"$token3\"" >> .env

echo "Instalando módulos de Node.js..."
npm install

echo "Garantizando dependencias necesarias..."
npm install dotenv bcrypt --build-from-source

echo "Configurando base de datos (Prisma)..."
npx prisma generate
npx prisma db push

echo "Compilando proyecto TypeScript..."
npx tsc

echo "Iniciando Panel con PM2..."
pm2 start ecosystem.config.js
pm2 startup
pm2 save

clear
echo
echo "¡PANEL DTUNNEL INSTALADO CON ÉXITO!"
echo "Dominio/IP configurado: $domain"
echo "El panel se está ejecutando en el puerto: $porta"
echo
echo "Escriba el comando para gestionar: pmenu"
echo
rm -f "$0"
