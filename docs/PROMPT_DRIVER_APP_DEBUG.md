# PROMPT DE CONTEXTO — App de Conductores Level Up (Flutter)

## Problema Actual
La app de conductores (`D:\proyectos\conductores_level`) falla al escanear el QR del panel de administración. Muestra "QR inválido o expirado" y se cierra.

## Causa Raíz Identificada
Se cambió el `JWT_SECRET` del backend durante un hardening de seguridad. Los tokens anteriores ya no son válidos. Sin embargo, el endpoint `POST /api/auth/driver-qr` funciona correctamente cuando se prueba desde PowerShell con el `driverToken` correcto.

El problema está en la comunicación entre la app Flutter del conductor y el backend.

---

## Arquitectura del Sistema

### Backend (Node.js/Express)
- **URL:** `http://[IP_LOCAL]:5000/api`
- **Endpoint de login conductor:** `POST /api/auth/driver-qr`
  - Body: `{ "driverToken": "uuid-string-del-qr" }`
  - Response exitosa:
    ```json
    {
      "token": "jwt...",
      "routeId": "mongoId",
      "conductor": { "nombre": "Roberto", "telefono": "555..." },
      "vehiculo": { "placa": "XXX-555", "modelo": "mitsubishi" },
      "dias": ["lunes", "miercoles"],
      "horarios": { "horaSalida": "16:03", "horaRetorno": "19:00" }
    }
    ```
  - Response error: `{ "message": "Token QR inválido o ruta inactiva" }` (401)

- **Endpoint de tracking:** `PATCH /api/routes/:routeId/coordinates`
  - Headers: `Authorization: Bearer <jwt_token>`
  - Body: `{ "lat": 10.43, "lng": -75.53 }`
  - Solo acepta role `driver`

### Rutas activas en BD con driverToken:
- Roberto: `56b83b32-8f27-4314-9ad9-91ca2031cd4a` (routeId: `6a24a7657385be57dcaf4167`)
- Rodolfo: `80785179-51cf-4b50-99fe-c2b944000e10`

---

## App de Conductores (Flutter)

### Ubicación: `D:\proyectos\conductores_level`

### Estructura:
```
lib/
├── core/constants.dart        → URL del API (192.168.10.10:5000)
├── screens/
│   ├── login_screen.dart      → Escáner QR + auto-login
│   └── driver_dashboard.dart  → Control de ruta + GPS
├── services/
│   ├── api_service.dart       → Dio + flutter_secure_storage
│   └── gps_service.dart       → Geolocator + envío cada 5s
└── main.dart                  → Entry point
```

### Flujo de Login:
1. App abre → intenta auto-login (lee token/session del secure_storage)
2. Si no hay sesión → muestra pantalla con botón "ESCANEAR QR"
3. Conductor escanea QR del panel admin (contiene el `driverToken` UUID)
4. App envía `POST /api/auth/driver-qr` con `{ driverToken: "uuid..." }`
5. Backend retorna JWT + datos de la ruta
6. App guarda token y session en secure_storage
7. Navega al dashboard

### Flujo de GPS:
1. Conductor toca "INICIAR RUTA"
2. `GpsService.startTracking(routeId, token)` → pide permisos GPS
3. Cada 5 segundos: `PATCH /api/routes/:routeId/coordinates` con lat/lng
4. Los alumnos afiliados ven la ubicación en tiempo real en su app

---

## Configuración actual de la app

### `lib/core/constants.dart`:
```dart
static const String _devUrl = 'http://192.168.10.10:5000/api';
```

### `lib/services/api_service.dart`:
- Usa Dio con `flutter_secure_storage`
- Interceptor que agrega `Authorization: Bearer` si hay token

### `lib/screens/login_screen.dart`:
- Usa `mobile_scanner` para leer QR
- Al detectar QR → `_onQrDetected(driverToken)`
- Envía al backend → guarda token → navega al dashboard

---

## Qué se debe verificar/corregir:

1. **URL del API**: Verificar que `192.168.10.10` sea la IP correcta actual del servidor. Si cambió, actualizar `constants.dart`.

2. **Rate Limiting**: El backend tiene un límite de 10 requests/15min en `/api/auth`. Si se hicieron muchas pruebas, puede estar bloqueado. Reiniciar el backend limpia los contadores.

3. **Auto-login con token expirado**: La app intenta auto-login con un token viejo (generado con el JWT_SECRET anterior). El fix ya fue aplicado (validar con backend antes de navegar), pero puede necesitar limpiar datos de la app:
   - Android: Settings → Apps → conductores_level → Clear Data
   - O desinstalar y reinstalar la app

4. **QR del panel admin**: Verificar que el QR generado en el panel contiene exactamente el UUID (`56b83b32-8f27-4314-9ad9-91ca2031cd4a`), no una URL ni otro formato.

5. **Emulador vs Dispositivo físico**: Si se prueba en emulador Android, la IP `192.168.10.10` no es accesible. Usar `10.0.2.2` para emulador o la IP real de la máquina en la red local.

---

## Prueba manual del endpoint (funciona):
```powershell
Invoke-RestMethod -Uri "http://localhost:5000/api/auth/driver-qr" -Method POST -ContentType "application/json" -Body '{"driverToken":"56b83b32-8f27-4314-9ad9-91ca2031cd4a"}'
```
Retorna token válido + datos de ruta correctamente.

---

## Seguridad aplicada al backend:
- JWT_SECRET: `k8Xp2vM9nQ4wR7jL1cY6bA3fH0dT5gZ8uE2iO9sW4mK7nP1xV6qJ3rB0yN5tU`
- JWT expiración conductores: 30 días
- Rate limit login: 10 intentos / 15 min
- CORS permite requests sin origin (apps móviles)
- Sanitización NoSQL activa

---

## Acción requerida:
Diagnosticar por qué la app Flutter del conductor no puede comunicarse con el backend al escanear el QR, considerando:
- La IP puede haber cambiado
- El rate limiter puede estar bloqueando
- El secure_storage puede tener datos corruptos del token anterior
- El QR puede no contener el formato esperado
