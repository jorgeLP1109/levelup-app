# Level Up - App Móvil

Aplicación móvil para el gimnasio de gimnasia **Level Up**, desarrollada en Flutter compatible con Android e iOS.

## Funcionalidades

- **Autenticación:** Login y registro con JWT (soporte para menores de edad con datos del representante)
- **Clases:** Ver clases disponibles, horarios, precios e inscribirse/desinscribirse
- **Progreso:** Visualizar avances registrados por el profesor
- **Mensajes:** Tablón de anuncios del gimnasio filtrado por rol
- **Rutas:** Ver rutas de transporte, afiliarse con confirmación de costo, tracking GPS del conductor

## Stack

- Flutter 3.35 / Dart
- Dio (HTTP client)
- Provider (gestión de estado)
- flutter_secure_storage (JWT)
- google_maps_flutter
- flutter_local_notifications

## Estructura

```
lib/
├── core/         → Constantes, colores, tema
├── models/       → User, GymClass, Progress, GymRoute
├── providers/    → AuthProvider, ClassProvider
├── screens/      → Login, Register, Dashboard, Profile
├── services/     → ApiService (Dio + JWT interceptor)
└── main.dart     → Entry point con MultiProvider
```

## Requisitos

- Flutter SDK >= 3.0.0
- Backend corriendo en puerto 5000 (repo: level2026-backend)

## Instalación

```bash
flutter pub get
flutter run
```

## API Base URL

- Android emulador: `http://10.0.2.2:5000/api`
- iOS/Desktop: `http://localhost:5000/api`
