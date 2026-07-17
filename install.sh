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
    
    # Usamos tar para evitar dependencia previa de 'zip'
    tar -czf painelbackup.tar.gz painelbackup 2>/dev/null
    mv painelbackup.tar.gz /root 2>/dev/null
    
    # Detener PM2 si está corriendo antes de borrar
    pm2 delete ecosystem.config.js > /dev/null 2>&1
    
    rm -rf /etc/DTunnel
    rm -rf /root/install.sh
    echo "¡Eliminado con éxito! Respaldo guardado en /root/painelbackup.tar.gz"
    exit 0
  }
  exit 0
}

clear
echo "¿En qué puerto desea activar el panel?"
read porta
echo
echo "Instalando dependencias del sistema..."
echo
sleep 2

#========================
# Update e instalación de herramientas del sistema
apt-get update -y
apt install wget curl zip unzip cron screen git tar -y

# Instalación limpia de Node.js v20
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install nodejs -y

# Instalar PM2 de forma global
npm install -g pm2
#=========================

cd /etc/
# Clonar tu repositorio
git clone https://github.com/omar-campos/DTunnel.git[cite: 1, 2]
cd /etc/DTunnel

# Permisos y mover ejecutables a /bin
chmod +x pon poff pmenu backmod[cite: 2]
mv pon poff pmenu backmod /bin[cite: 2]

# Configurar variables de entorno (.env)
cp .env.example .env 2>/dev/null || touch .env[cite: 2]
echo "PORT=$porta" > .env[cite: 2]
echo "NODE_ENV=\"production\"" >> .env[cite: 2]
echo "DATABASE_URL=\"file:./database.db\"" >> .env[cite: 2]

# Generar tokens de seguridad aleatorios de forma segura
echo "Generando llaves de seguridad..."
token1=$(node -e "console.log(require('crypto').randomBytes(64).toString('hex'));")
token2=$(node -e "console.log(require('crypto').randomBytes(64).toString('hex'));")
token3=$(node -e "console.log(require('crypto').randomBytes(64).toString('hex'));")
echo "CSRF_SECRET=\"$token1\"" >> .env[cite: 2]
echo "JWT_SECRET_KEY=\"$token2\"" >> .env[cite: 2]
echo "JWT_SECRET_REFRESH=\"$token3\"" >> .env[cite: 2]

# Instalar dependencias del proyecto
echo "Instalando módulos de Node.js..."
npm install

# Generar cliente de Prisma y estructurar SQLite
echo "Configurando base de datos..."[cite: 2]
npx prisma generate[cite: 2]
npx prisma db push[cite: 2]

# Compilar TypeScript
echo "Compilando proyecto TypeScript..."
npm run build[cite: 2]

# INICIAR EL PANEL EN PRODUCCIÓN CON PM2
echo "Iniciando Panel con PM2..."
npm run prod

# Guardar lista de PM2 para que inicie tras reinicios del VPS
pm2 startup
pm2 save

#=========================
clear
echo
echo "¡PANEL DTUNNEL INSTALADO CON ÉXITO!"[cite: 2]
echo "El panel se está ejecutando en el puerto: $porta"
echo
echo "Escriba el comando para gestionar: pmenu"[cite: 2]
echo
rm -rf /root/install.sh[cite: 2]
