#!/bin/bash

[[ "$(whoami)" != "root" ]] && {
  echo
  echo "¡Instale como usuario Root!"
  echo
  rm -rf install.sh
  exit 0
}

ubuntuV=$(lsb_release -r | awk '{print $2}' | cut -d. -f1)

[[ $(($ubuntuV < 20)) = 1 ]] && {
  clear
  echo "La versión de Ubuntu debe ser mínimo 20, la suya es $ubuntuV"
  echo
  rm /root/install.sh
  exit 0
}

[[ -e /etc/DTunnel/src/index.ts ]] && {
  clear
  echo "El Panel ya está instalado, ¿desea eliminarlo? (s/n)"
  read remo
  [[ $remo = @(s|S) ]] && {
    cd /etc/DTunnel
    rm -r painelbackup > /dev/null 2>&1
    mkdir painelbackup > /dev/null 2>&1
    cp prisma/database.db painelbackup 2>/dev/null
    cp .env painelbackup 2>/dev/null
    
    tar -czf painelbackup.tar.gz painelbackup 2>/dev/null
    mv painelbackup.tar.gz /root 2>/dev/null
    
    pm2 delete ecosystem.config.js > /dev/null 2>&1
    
    rm -rf /etc/DTunnel
    rm -rf /root/install.sh
    echo "¡Eliminado con éxito! Respaldo guardado en /root/painelbackup.tar.gz"
    exit 0
  }
  exit 0
}

clear
echo "=========================================="
echo "      CONFIGURACIÓN DEL PANEL DTUNNEL     "
echo "=========================================="
echo
echo "Ingrese el IP o Dominio del servidor (ej. panel.midominio.com o 192.168.1.1):"
read domain
echo
echo "¿En qué puerto desea activar el panel?"
read porta
echo
echo "Instalando dependencias del sistema..."
echo
sleep 2

#========================
apt-get update -y
apt install wget curl zip unzip cron screen git tar -y

# Instalación de Node.js v20
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install nodejs -y

# PM2 Global
npm install -g pm2
#=========================

cd /etc/
git clone https://github.com/omar-campos/DTunnel.git
cd /etc/DTunnel

chmod +x pon poff pmenu backmod
mv pon poff pmenu backmod /bin

cp .env.example .env 2>/dev/null || touch .env

# Guardar Dominio/IP y Puerto en las variables de entorno
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

echo "Configurando base de datos..."
npx prisma generate
npx prisma db push

echo "Compilando proyecto TypeScript..."
npm run build

echo "Iniciando Panel con PM2..."
npm run prod

pm2 startup
pm2 save

#=========================
clear
echo
echo "¡PANEL DTUNNEL INSTALADO CON ÉXITO!"
echo "Dominio/IP configurado: $domain"
echo "El panel se está ejecutando en el puerto: $porta"
echo
echo "Escriba el comando para gestionar: pmenu"
echo
rm -rf /root/install.sh
