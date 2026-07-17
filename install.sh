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
    rm -r painelbackup > /dev/null
    mkdir painelbackup > /dev/null
    cp prisma/database.db painelbackup 2>/dev/null
    cp .env painelbackup 2>/dev/null
    zip -r painelbackup.zip painelbackup
    mv painelbackup.zip /root
    rm -rf /etc/DTunnel
    rm -rf /root/install.sh
    echo "¡Eliminado con éxito!"
    exit 0
  }
  exit 0
}

clear
echo "¿En qué puerto desea activar el panel?"
read porta
echo
echo "Instalando Panel..."
echo
sleep 3

#========================
# Solo Update (Evitamos Upgrade para prevenir bloqueos de pantalla/interacción)
apt-get update -y
apt install wget curl zip unzip cron screen git -y

# Instalación limpia de Node.js v20
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install nodejs -y

# Instalar PM2 de forma global para evitar fallos de daemonización
npm install -g pm2
#=========================

cd /etc/
# Clonar tu repositorio
git clone https://github.com/omar-campos/DTunnel.git
cd /etc/DTunnel

# Permisos y mover ejecutables a /bin
chmod +x pon poff pmenu backmod
mv pon poff pmenu backmod /bin

# Configurar variables de entorno (.env)
cp .env.example .env 2>/dev/null || touch .env
echo "PORT=$porta" > .env
echo "NODE_ENV=\"production\"" >> .env
echo "DATABASE_URL=\"file:./database.db\"" >> .env

# Generar tokens de seguridad aleatorios
token1=$(node -e "console.log(require('crypto').randomBytes(256).toString('base64'));")
token2=$(node -e "console.log(require('crypto').randomBytes(256).toString('base64'));")
token3=$(node -e "console.log(require('crypto').randomBytes(256).toString('base64'));")
echo "CSRF_SECRET=\"$token1\"" >> .env
echo "JWT_SECRET_KEY=\"$token2\"" >> .env
echo "JWT_SECRET_REFRESH=\"$token3\"" >> .env

# Instalar dependencias del proyecto y compilar TypeScript
npm install
npm run build

# Configurar Base de Datos SQLite con Prisma de manera segura
npx prisma generate
npx prisma db push   # Usa db push para asegurar que la base de datos SQLite se cree exactamente como define el schema.prisma sin conflictos de historial

#=========================
clear
echo
echo
echo "¡PANEL DTUNNEL INSTALADO!"
echo
echo "Escriba el comando: pmenu"
echo
rm -rf /root/install.sh
