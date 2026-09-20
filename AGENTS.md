# AGENTS.md — pulpe-app

Instrucciones para cualquier agente de código que trabaje en este repo.
Si algo acá contradice lo que creés que es la convención "normal" de Flutter, gana este archivo.

## Qué es esto

App de catálogo e inventario para pulperías y minisúper. Flutter 3.5+, Riverpod, `http`.
Consume la API del repo `pulpe-api`.

## Comandos

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000
flutter analyze
flutter test
```

En el emulador de Android usá `http://10.0.2.2:3000` en vez de `localhost`.

Antes de dar por terminado cualquier cambio: `flutter analyze && flutter test`.

## Contrato de la API

**El backend habla snake_case. Dart habla camelCase. La traducción ocurre en un solo lugar.**

- **Query params:** se arman únicamente en `lib/features/*/\*_repository.dart`, con las llaves en snake_case (`por_pagina`, no `porPagina`).
- **Respuestas:** el mapeo snake_case → camelCase va únicamente en los `fromJson` de `lib/models/`.
- Fuera de esos dos lugares, el resto de la app usa camelCase normal de Dart.

Si mandás `sortBy` donde la API espera `sort_by`, el backend responde **422** y la pantalla queda vacía.
No lo agarra el compilador, ni acá ni allá. La tabla de parámetros vigente está en el `AGENTS.md` de `pulpe-api`.

Formato de error que devuelve la API:

```json
{ "error": { "codigo": "parametros_invalidos", "mensaje": "…", "detalles": {} } }
```

`ApiClient` ya lo traduce a `ApiException`; los errores de red salen como `RedException`.

## Convenciones de código

- **Idioma:** el dominio se nombra en español (`producto`, `precio`, `existencias`). Los símbolos de Flutter quedan en inglés (`build`, `initState`, `ListView`).
- **Precios:** llegan como enteros en céntimos de colón. Formatear SIEMPRE con `Formato.precio()`, nunca dividir entre 100 dentro de un widget.
- **Estado:** Riverpod. Un provider por recurso, en el archivo del repositorio de su feature. Nada de `setState` para datos que vengan de la API.
- **Estructura:** una carpeta por feature en `lib/features/`, con su `_repository.dart` y sus pantallas. Lo compartido va en `lib/core/`.
- **Red:** todas las llamadas pasan por `ApiClient`. No usar `http` directo en un widget ni en una pantalla.
- **Widgets:** los privados van en el mismo archivo con prefijo `_`. Constructores `const` donde se pueda.
- **Configuración:** la URL base se lee con `String.fromEnvironment`. Nunca hardcodear un host en el código.

## Estados de pantalla

Toda pantalla que cargue datos tiene que manejar los cuatro casos: **cargando**, **con datos**, **vacío** y **error con botón de reintentar**.
`ProductosListaScreen` es la referencia; copiá ese patrón.

## Qué NO hacer

- No agregar dependencias de servicios externos (Firebase, proveedores de push, analítica, storage en la nube). El proyecto corre entero en local, a propósito.
- No cambiar los `fromJson` para que acepten camelCase: el problema estaría en el contrato, no en el parseo.
- No borrar ni saltar un test para que pase la suite.
