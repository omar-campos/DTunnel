# 🚀 DTunnel - Panel de Administración VPS

Este es un panel de gestión para servidores (SSH/V2Ray) desarrollado con un backend moderno en **Fastify (Node.js con TypeScript)**, base de datos **SQLite utilizando Prisma ORM**, y preparado para producción con **PM2**.

---

## 📋 Requisitos Previos

* Un servidor VPS con **Ubuntu 20.04 LTS o superior**.
* Acceso como usuario **root** a través de SSH.

---

## ⚡ Instalación Rápida (Un solo comando)

Conéctate a tu VPS como usuario `root` y ejecuta el siguiente comando para iniciar la instalación automática:

```bash
cd /root && wget [https://raw.githubusercontent.com/omar-campos/DTunnel/main/install.sh](https://raw.githubusercontent.com/omar-campos/DTunnel/main/install.sh) && chmod +x install.sh && ./install.sh
