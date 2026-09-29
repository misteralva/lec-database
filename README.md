# LEC Database — League of Legends EMEA Championship

Complete database and web application to manage the **League of Legends EMEA Championship (LEC)**, developed as a database project with PHP and MySQL.

---

## Description

Full-stack web application to browse and manage all the information of the LEC: teams, players, matches, statistics and standings from the 2024 season to the present.

The project is built on a three-layer architecture with a strict separation between the data logic (MySQL stored procedures), the access layer (PHP/PDO) and the presentation (HTML/CSS).

---

## Features

### Public website
- **Home** — upcoming matches, latest results and teams of the current season
- **Standings** — yearly standings table calculated in real time from actual results
- **Teams** — full rosters with photos, roles, coaching staff and filters by split
- **Players** — search with filters by role and nationality
- **Matches** — details of each match with maps and individual statistics
- **Statistics** — top KDA, top CS/min, win rate by team and player, stats by role, radar comparison tool
- **Playoffs** — visual double-elimination bracket

### Admin panel
- Authentication system with three roles: **superadmin**, **editor** and **auditor**
- **New match** — register matchups with phase and teams
- **Edit result** — save the score, map durations and the statistics of all 10 players
- **Manage players** — sign players, move them between starter and substitute, change role, release
- **Manage teams** — create and edit teams, register them in splits
- **Manage splits** — create new seasons and close splits with validation of pending matches
- **Manage users** — create, activate/deactivate, change role and delete panel users
- **Audit** — automatic log of every change in the database, with filters and pagination

---

## Technologies

| Layer | Technology |
|-------|-----------|
| Server | PHP 8.x |
| Database | MySQL 8.0 / MariaDB |
| Frontend | HTML5 + CSS3 (no frameworks) |
| Charts | Chart.js |
| Local environment | XAMPP |
| Credential security | `.env` file |

---

## Database

- **14 tables** — equipo, jugador, entrenador, split, fase_split, historial_equipo, jugador_equipo_historial, entrenador_equipo_historial, partido, mapa, estadistica_jugador, clasificacion_anual, auditoria_lec, usuarios_admin
- **45 stored procedures** — all business logic encapsulated in stored procedures, with no direct SQL in the PHP code
- **7 functions** — reusable helper calculations
- **12 triggers** — automatic auditing, validations and protection of historical data
- **4 MySQL users** with different permissions (admin, backend, readonly, auditor)

> Table names are kept in Spanish, exactly as they appear in the database.

### Included data
- Complete seasons 2024–2026 (Spring, Summer, LEC Versus)
- 10 teams with the real Spring 2026 rosters
- 83+ players and 10 coaches
- Real matches and statistics obtained from gol.gg

---

## Installation

### Requirements
- XAMPP (PHP 8.x + MySQL/MariaDB)
- Web browser

### Steps

**1. Clone the repository**
```bash
git clone https://github.com/misteralva/lec-database.git
cd lec-database
```

**2. Copy it to XAMPP**
```
C:\xampp\htdocs\proyecto\
```

**3. Create the `.env` file** in the project root
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

**4. Import the database**

Open phpMyAdmin and import `lec_script.sql`. The script automatically creates the database, all the tables, procedures, triggers, real data and the panel users.

**5. Open it in the browser**
```
http://localhost/proyecto/
```

---

## Accessing the admin panel

```
http://localhost/proyecto/admin/login.php
```

| Email | Password | Role |
|-------|----------|------|
| admin@lec.es | password | Superadmin |
| editor@lec.es | password | Editor |
| auditor@lec.es | password | Auditor |

> Change the passwords after the first login from **Manage users**. These are demo credentials for local use only.

---

## Project structure

```
proyecto/
├── .env                          ← configuration (not included in git)
├── .gitignore
├── index.php                     ← home page
├── clasificacion.php
├── equipos.php
├── jugadores.php
├── partido.php
├── estadisticas.php
├── playoffs.php
├── resultados.php
├── ImagenHelper.php              ← image path handling
├── clases/
│   ├── Config.php                ← reads the .env
│   ├── ConexionDB.php            ← PDO connection (Singleton pattern)
│   └── LecDB.php                 ← data access layer
├── admin/
│   ├── login.php / logout.php
│   ├── auth.php                  ← role system
│   ├── helpers.php               ← callSP() and execSP()
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
│   │   ├── equipos/              ← logos and backgrounds per team
│   │   ├── jugadores/            ← photos per team/player
│   │   ├── entrenadores/         ← coach photos
│   │   └── roles/                ← SVG role icons
│   └── video/lec.mp4
├── includes/
│   ├── header.php
│   ├── footer.php
│   └── csrf.php
└── lec_script.sql                ← full database script
```

---

## Implemented security

- **`.env`** — database credentials kept out of the source code
- **MySQL users per role** — lec_readonly can only SELECT + EXECUTE; lec_backend has DML; lec_auditor only accesses the audit table
- **Prepared statements** — every query uses `?` parameters, preventing SQL injection
- **BCrypt** — passwords hashed with cost=12, never stored in plain text
- **CSRF tokens** — all write forms are protected
- **htmlspecialchars** — all output is escaped to prevent XSS
- **Role system** — auth() validates permissions on every admin page
- **Protection triggers** — data from past seasons cannot be modified (except by the superadmin with bypass)
- **Automatic auditing** — every INSERT/UPDATE/DELETE is logged in auditoria_lec

---

## Architecture

```
Browser
    │
    ▼
PHP (index.php, equipos.php...)
    │  uses
    ▼
LecDB.php  ────────────────────── ConexionDB.php
    │  calls                             │ connects using
    ▼                                    ▼
Stored Procedures (MySQL)           Config.php → .env
    │
    ▼
Data tables
```

No PHP page contains direct SQL. Every database operation goes through a stored procedure called from `LecDB.php`.

---

## License

Academic project — League of Legends and LEC are registered trademarks of Riot Games.
