# LEC Database — League of Legends EMEA Championship

Base de datos y aplicación web completa para gestionar la **League of Legends EMEA Championship (LEC)**, desarrollada como proyecto de base de datos con PHP y MySQL.

---

## Descripción

Aplicación web full-stack que permite consultar y administrar toda la información de la LEC: equipos, jugadores, partidos, estadísticas y clasificaciones desde la temporada 2024 hasta la actualidad.

El proyecto está construido sobre una arquitectura de tres capas con separación estricta entre la lógica de datos (procedimientos almacenados MySQL), la capa de acceso (PHP/PDO) y la presentación (HTML/CSS).

---

## Funcionalidades

### Web pública
- **Inicio** — próximos partidos, últimos resultados y equipos de la temporada actual
- **Clasificación** — tabla de clasificación por año calculada en tiempo real desde resultados reales
- **Equipos** — plantillas completas con fotos, roles, cuerpo técnico y filtros por split
- **Jugadores** — buscador con filtro por rol y nacionalidad
- **Partidos** — detalle de cada partido con mapas y estadísticas individuales
- **Estadísticas** — top KDA, top CS/min, win rate por equipo y jugador, stats por rol, comparador radar
- **Playoffs** — bracket visual de doble eliminación

### Panel de administración
- Sistema de autenticación con tres roles: **superadmin**, **editor** y **auditor**
- **Nuevo partido** — registrar enfrentamientos con fase y equipos
- **Editar resultado** — guardar marcador, duración de mapas y estadísticas de los 10 jugadores
- **Gestionar jugadores** — fichar, cambiar de titular a suplente, cambiar rol, dar de baja
- **Gestionar equipos** — crear y editar equipos, registrarlos en splits
- **Gestionar splits** — crear nuevas temporadas y cerrar splits con validación de partidos pendientes
- **Gestionar usuarios** — crear, activar/desactivar, cambiar rol y eliminar usuarios del panel
- **Auditoría** — registro automático de todos los cambios en la base de datos con filtros y paginación

---

## Tecnologías

| Capa | Tecnología |
|------|-----------|
| Servidor | PHP 8.x |
| Base de datos | MySQL 8.0 / MariaDB |
| Frontend | HTML5 + CSS3 (sin frameworks) |
| Gráficas | Chart.js |
| Entorno local | XAMPP |
| Seguridad credenciales | Archivo `.env` |

---

## Base de datos

- **14 tablas** — equipo, jugador, entrenador, split, fase_split, historial_equipo, jugador_equipo_historial, entrenador_equipo_historial, partido, mapa, estadistica_jugador, clasificacion_anual, auditoria_lec, usuarios_admin
- **45 procedimientos almacenados** — toda la lógica de negocio encapsulada en SPs, sin SQL directo en el código PHP
- **7 funciones** — cálculos auxiliares reutilizables
- **12 triggers** — auditoría automática, validaciones y protección de datos históricos
- **4 usuarios MySQL** con permisos diferenciados (admin, backend, readonly, auditor)

### Datos incluidos
- Temporadas completas 2024–2026 (Spring, Summer, LEC Versus)
- 10 equipos con plantillas reales del Spring 2026
- 83+ jugadores y 10 entrenadores
- Partidos y estadísticas reales obtenidos de gol.gg

---

## Instalación

### Requisitos
- XAMPP (PHP 8.x + MySQL/MariaDB)
- Navegador web

### Pasos

**1. Clonar el repositorio**
```bash
git clone https://github.com/tu-usuario/lec-database.git
cd lec-database
```

**2. Copiar a XAMPP**
```
C:\xampp\htdocs\proyecto\
```

**3. Crear el archivo `.env`** en la raíz del proyecto
```env
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=lec
DB_CHARSET=utf8mb4
DB_USE_ROLES=false
DB_USER=root
DB_PASS=
ADMIN_USER=admin
ADMIN_PASS=password
```

**4. Importar la base de datos**

Abrir phpMyAdmin e importar `lec_script.sql`. El script crea la base de datos, todas las tablas, procedimientos, triggers, datos reales y usuarios del panel automáticamente.

**5. Abrir en el navegador**
```
http://localhost/proyecto/
```

---

## Acceso al panel de administración

```
http://localhost/proyecto/admin/login.php
```

| Email | Contraseña | Rol |
|-------|-----------|-----|
| admin@lec.es | password | Superadmin |
| editor@lec.es | password | Editor |
| auditor@lec.es | password | Auditor |

> Cambiar las contraseñas tras el primer acceso desde **Gestionar usuarios**.

---

## Estructura del proyecto

```
proyecto/
├── .env                          ← configuración (no incluido en git)
├── .gitignore
├── index.php                     ← página de inicio
├── clasificacion.php
├── equipos.php
├── jugadores.php
├── partido.php
├── estadisticas.php
├── playoffs.php
├── resultados.php
├── ImagenHelper.php              ← gestión de rutas de imágenes
├── clases/
│   ├── Config.php                ← lectura del .env
│   ├── ConexionDB.php            ← conexión PDO (patrón Singleton)
│   └── LecDB.php                 ← capa de acceso a datos
├── admin/
│   ├── login.php / logout.php
│   ├── auth.php                  ← sistema de roles
│   ├── helpers.php               ← callSP() y execSP()
│   ├── panel.php
│   ├── nuevo_partido.php
│   ├── editar_resultado.php
│   ├── gestionar_jugadores.php
│   ├── gestionar_equipos.php
│   ├── gestionar_splits.php
│   ├── gestionar_usuarios.php
│   └── auditoria.php
├── assets/
│   ├── css/estilo.css
│   ├── js/estadisticas.js
│   ├── api/jugador_stats.php
│   ├── img/
│   │   ├── equipos/              ← logos y fondos por equipo
│   │   ├── jugadores/            ← fotos por equipo/jugador
│   │   ├── entrenadores/         ← fotos de entrenadores
│   │   └── roles/                ← iconos SVG de roles
│   └── video/lec.mp4
├── includes/
│   ├── header.php
│   ├── footer.php
│   └── csrf.php
└── lec_script.sql                ← script completo de la BD
```

---

##  Seguridad implementada

- **`.env`** — credenciales de base de datos fuera del código fuente
- **Usuarios MySQL por rol** — lec_readonly solo puede hacer SELECT + EXECUTE; lec_backend tiene DML; lec_auditor solo accede a la tabla de auditoría
- **Prepared statements** — toda consulta usa parámetros `?`, imposible inyección SQL
- **BCrypt** — contraseñas hasheadas con cost=12, nunca en texto plano
- **CSRF tokens** — todos los formularios de escritura están protegidos
- **htmlspecialchars** — todos los outputs escapados para prevenir XSS
- **Sistema de roles** — auth() valida permisos en cada página del admin
- **Triggers de protección** — los datos de temporadas pasadas no pueden modificarse (salvo superadmin con bypass)
- **Auditoría automática** — cada INSERT/UPDATE/DELETE queda registrado en auditoria_lec

---

## Arquitectura

```
Navegador
    │
    ▼
PHP (index.php, equipos.php...)
    │  usa
    ▼
LecDB.php  ────────────────────── ConexionDB.php
    │  llama a                           │ conecta usando
    ▼                                    ▼
Stored Procedures (MySQL)           Config.php → .env
    │
    ▼
Tablas de datos
```

Ninguna página PHP contiene SQL directo. Toda operación con la base de datos pasa por un procedimiento almacenado llamado desde `LecDB.php`.

---

## Licencia

Proyecto académico — League of Legends y LEC son marcas registradas de Riot Games.
