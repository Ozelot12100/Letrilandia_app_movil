# letrilandia

A new Flutter project.

## Configuración de credenciales Supabase

Este proyecto utiliza Supabase como backend. Por seguridad, **las credenciales no están incluidas en el repositorio**.

### ¿Cómo configurar tus credenciales?

1. Crea un archivo llamado `.env` dentro de la carpeta `assets/` de tu proyecto.
2. Copia el contenido del archivo `.env.example` y reemplaza los valores con tus propias credenciales de Supabase:

    ```env
    SUPABASE_URL=TU_SUPABASE_URL
    SUPABASE_ANON_KEY=TU_SUPABASE_ANON_KEY
    ```

3. Guarda el archivo.

> **Nota:**  
> El archivo `.env` está en `.gitignore` y **no se sube al repositorio** por seguridad.  
> Si quieres ejecutar la app, necesitas tus propias credenciales de Supabase.

### ¿Dónde obtengo mis credenciales?

Puedes obtener tu `SUPABASE_URL` y `SUPABASE_ANON_KEY` desde el panel de tu proyecto en [Supabase](https://supabase.com/).

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
