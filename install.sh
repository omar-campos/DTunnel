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
  cp prisma/database.db painelbackup
  cp .env painelbackup
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
apt update -y
apt-get update -y
apt-get upgrade -y
apt install wget -y
apt install curl -y
apt install zip -y
apt install cron -y
apt install unzip -y
apt install screen -y
apt install git -y
curl -fsSL https://deb.nodesource.com/setup_20.x | bash
apt-get install nodejs -y
#=========================
cd /etc/
# Corregido para que clone TU repositorio de omar-campos
git clone https://github.com/omar-campos/DTunnel.git
cd /etc/DTunnel
chmod 777 pon poff pmenu backmod
mv pon poff pmenu backmod /bin
cp .env.example .env
echo "PORT=$porta" > .env
echo "NODE_ENV=\"production\"" >> .env
echo "DATABASE_URL=\"file:./database.db\"" >> .env
token1=$(node -e "console.log(require('crypto').randomBytes(256).toString('base64'));")
token2=$(node -e "console.log(require('crypto').randomBytes(256).toString('base64'));")
token3=$(node -e "console.log(require('crypto').randomBytes(256).toString('base64'));")
echo "CSRF_SECRET=\"$token1\"" >> .env
echo "JWT_SECRET_KEY=\"$token2\"" >> .env
echo "JWT_SECRET_REFRESH=\"$token3\"" >> .env
npm install
npm run build
npx prisma generate
npx prisma migrate deploy
npx prisma migrate resolve --applied 20251018193643_database
npx prisma migrate deploy
npx prisma db pull
#=========================
clear
echo
echo
echo "¡PANEL DTUNNEL INSTALADO!"
echo
echo "Escriba el comando: pmenu"
echo
rm -rf /root/install.sh
