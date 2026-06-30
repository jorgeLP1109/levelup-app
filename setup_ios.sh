#!/bin/bash

# En caso de error, el script se detiene
set -e

echo "🍏 === INICIANDO CONFIGURACIÓN PREMIUM PARA iOS ==="

# 1. Limpieza profunda e instalación de dependencias de Flutter
echo "📦 Limpiando caché y descargando paquetes de Flutter..."
flutter clean
flutter pub get

# 2. Configurar permisos de Cámara y Galería en el Info.plist de iOS automáticamente
INFO_PLIST="ios/Runner/Info.plist"
if [ -f "$INFO_PLIST" ]; then
    echo "📸 Configurando permisos de cámara en Info.plist..."
    # Verifica si ya existen las llaves para no duplicarlas
    if ! grep -q "NSCameraUsageDescription" "$INFO_PLIST"; then
        # Inserta las llaves de permisos justo antes de la penúltima línea (antes de </dict>)
        sed -i '' '/<\/dict>/i\
\    <key>NSCameraUsageDescription<\/key>\
\    <string>Necesitamos acceso a la cámara para tomar tu foto de perfil.<\/string>\
\    <key>NSPhotoLibraryUsageDescription<\/key>\
\    <string>Necesitamos acceso a la galería para seleccionar tu foto de perfil.<\/string>\
' "$INFO_PLIST"
    fi
fi

# 3. Instalación de Pods nativos para arquitectura moderna (Apple Silicon M1/M2/M3)
echo "🧬 Instalando dependencias nativas de iOS (CocoaPods)..."
cd ios
pod repo update
pod install
cd ..

# 4. Encender el Simulador de iPhone de Apple
echo "📱 Abriendo el simulador oficial de iOS..."
open -a Simulator

# Esperar unos segundos a que el simulador responda
echo "⏳ Esperando a que el simulador esté listo..."
sleep 5

# 5. Lanzar la aplicación en el simulador en modo desarrollo con Hot Reload
echo "🚀 ¡Todo listo! Compilando y ejecutando Level Up en iOS..."
flutter run