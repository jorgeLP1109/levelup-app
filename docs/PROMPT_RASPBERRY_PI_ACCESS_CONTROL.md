# PROMPT DE CONTEXTO — Sistema de Control de Acceso con Raspberry Pi
## Level Up Gimnasio — Lector QR de Entrada

---

## Contexto General

Se ha desarrollado un ecosistema completo para el gimnasio de gimnasia **Level Up** compuesto por:

1. **Backend API** (Node.js/Express + MongoDB) corriendo en puerto 5000
2. **Panel de Administración** (React + Vite + Tailwind)
3. **App Móvil** (Flutter — Android/iOS)

Los alumnos del gimnasio tienen una mensualidad que deben mantener al día. La app móvil genera un **código QR dinámico** con un token temporal que valida su solvencia. Este token se regenera cada 60 segundos.

Ahora necesitamos desarrollar el **software del lector de acceso** que correrá en una **Raspberry Pi** ubicada en la entrada del gimnasio.

---

## Arquitectura del Sistema de Acceso

```
[App Móvil Flutter] → genera QR con token
         ↓
[Raspberry Pi + Cámara/Lector QR] → lee el QR
         ↓
[GET /api/access/validate/:token] → consulta al backend
         ↓
[Respuesta] → GRANTED / DENIED → Acción física (LED, buzzer, relay)
```

---

## API Disponible (Backend ya implementado)

### Base URL: `http://[IP_SERVIDOR]:5000/api`

### Endpoints de Control de Acceso:

#### 1. Validar Token QR
```
GET /api/access/validate/:token
```
**No requiere autenticación** (diseñado para uso de la Raspberry Pi)

**Respuesta exitosa (200):**
```json
{
  "access": "GRANTED",
  "usuario": {
    "id": "6a2467d2281abd898f2fc9c5",
    "nombre": "Celine Sanchez",
    "cedula": "V-35123456",
    "email": "celine1@gmail.com",
    "fotoUrl": "data:image/jpeg;base64,...",
    "estadoPlan": "ACTIVO",
    "fechaVencimiento": "2026-07-15T00:00:00.000Z"
  },
  "usedAt": "2026-06-12T14:30:00.000Z"
}
```

**Respuestas de error:**
```json
// 404 - Token inválido
{ "access": "DENIED", "reason": "Token inválido" }

// 403 - Token ya usado
{ "access": "DENIED", "reason": "Token ya utilizado" }

// 403 - Token expirado
{ "access": "DENIED", "reason": "Token expirado" }
```

#### 2. Generar Token (solo para referencia — lo usa la app móvil)
```
POST /api/access/generate
Headers: Authorization: Bearer <jwt_token>
```
Genera un token único de 64 caracteres hexadecimales, válido por 60 segundos.

---

## Modelo de Datos: AccessToken (MongoDB)

```javascript
{
  user: ObjectId (ref: 'User'),
  token: String (64 hex chars, único),
  status: 'VALID' | 'USED' | 'EXPIRED',
  expiresAt: Date (60 segundos después de creación),
  usedAt: Date (cuando fue escaneado),
  createdAt: Date,
  updatedAt: Date
}
```

---

## Requerimientos del Software para Raspberry Pi

### Hardware sugerido:
- Raspberry Pi 4 (o 3B+)
- Cámara USB o módulo cámara Pi (para leer QR)
- LED verde (acceso concedido)
- LED rojo (acceso denegado)
- Buzzer (feedback sonoro)
- Relay o cerradura magnética (opcional — para abrir puerta/torniquete)
- Pantalla LCD/OLED pequeña (opcional — mostrar nombre del alumno)

### Funcionalidades:
1. **Lectura continua de QR** usando la cámara
2. **Decodificar** el contenido del QR (es un string hexadecimal de 64 caracteres)
3. **Consultar el backend** via HTTP GET a `/api/access/validate/:token`
4. **Interpretar respuesta:**
   - `access: "GRANTED"` → LED verde + buzzer corto + activar relay (abrir puerta) + mostrar nombre en pantalla
   - `access: "DENIED"` → LED rojo + buzzer largo + mostrar razón del rechazo
5. **Logging local** de accesos (fecha, nombre, resultado) en un archivo o SQLite local
6. **Modo offline** básico: si no hay conexión al backend, denegar acceso y alertar

### Stack sugerido:
- **Python 3** (ideal para Raspberry Pi)
- **OpenCV** o **pyzbar** para decodificar QR desde la cámara
- **requests** para las llamadas HTTP al backend
- **RPi.GPIO** para controlar LEDs, buzzer y relay
- **Opcional:** Flask mini-server local para dashboard de logs

### Flujo del programa:
```
1. Iniciar cámara
2. Loop infinito:
   a. Capturar frame
   b. Detectar QR en el frame
   c. Si se detecta QR:
      - Extraer texto (token)
      - GET /api/access/validate/{token}
      - Si GRANTED: abrir puerta, log éxito
      - Si DENIED: mostrar error, log fallo
      - Cooldown de 3 segundos (evitar lecturas duplicadas)
   d. Si no se detecta: seguir escaneando
```

---

## Configuración de Red

- El backend debe ser accesible desde la red local del gimnasio
- La Raspberry Pi debe poder alcanzar la IP del servidor en puerto 5000
- Variable de entorno: `API_BASE_URL=http://192.168.x.x:5000/api`

---

## Seguridad

- Los tokens son de un solo uso (una vez validados, se marcan como USED)
- Los tokens expiran a los 60 segundos (si no se usan, se auto-eliminan via TTL de MongoDB)
- No se requiere autenticación para el endpoint de validación (la Raspberry opera sin JWT)
- El token es un hash criptográfico de 32 bytes (64 hex chars) generado con crypto.randomBytes

---

## Formato del QR

El código QR contiene únicamente el **token** como texto plano:
```
a3f8b2c1d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1
```
(64 caracteres hexadecimales)

---

## Ejemplo de implementación básica en Python:

```python
import cv2
from pyzbar.pyzbar import decode
import requests
import RPi.GPIO as GPIO
import time

API_URL = "http://192.168.1.100:5000/api/access/validate"
LED_GREEN = 17
LED_RED = 27
BUZZER = 22

# Setup GPIO...

cap = cv2.VideoCapture(0)

while True:
    ret, frame = cap.read()
    codes = decode(frame)
    
    for code in codes:
        token = code.data.decode('utf-8')
        response = requests.get(f"{API_URL}/{token}")
        data = response.json()
        
        if data.get('access') == 'GRANTED':
            # Abrir puerta
            print(f"Acceso: {data['usuario']['nombre']}")
        else:
            # Denegar
            print(f"Denegado: {data.get('reason')}")
        
        time.sleep(3)  # Cooldown
```

---

## Notas adicionales

- El alumno abre la app → va al cuadro "Acceso" → se genera automáticamente un QR
- El QR se regenera cada 60 segundos (el alumno no necesita hacer nada, es automático)
- Si el alumno no está solvente (mensualidad vencida), la app NO genera QR y muestra un mensaje de "Acceso Denegado"
- La validación es instantánea: un GET simple retorna en ~50ms

---

**Desarrollado por:** Equipo Level Up
**Fecha:** Junio 2026
**Versión:** 1.0
