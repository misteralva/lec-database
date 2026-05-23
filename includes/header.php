<?php
$_activa = $paginaActiva ?? '';
$_titulo = isset($tituloPagina)
    ? htmlspecialchars($tituloPagina) . ' — LEC'
    : 'LEC — League of Legends EMEA Championship';
?><!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><?= $_titulo ?></title>
<link rel="stylesheet" href="assets/css/estilo.css">
</head>
<body>
<header class="site-header">
    <div class="header-inner">
        <a href="index.php" class="site-logo">
            <img src="assets/img/logos/lec.png" alt="LEC" onerror="this.style.display='none'">
            <span>LEC</span>
        </a>
        <nav class="main-nav">
            <a href="index.php"          class="<?= $_activa === 'inicio'        ? 'activo' : '' ?>">Inicio</a>
            <a href="clasificacion.php"  class="<?= $_activa === 'clasificacion' ? 'activo' : '' ?>">Clasificación</a>
            <a href="resultados.php"     class="<?= $_activa === 'resultados'    ? 'activo' : '' ?>">Resultados</a>
            <a href="equipos.php"        class="<?= $_activa === 'equipos'       ? 'activo' : '' ?>">Equipos</a>
            <a href="jugadores.php"      class="<?= $_activa === 'jugadores'     ? 'activo' : '' ?>">Jugadores</a>
            <a href="estadisticas.php"   class="<?= $_activa === 'estadisticas'  ? 'activo' : '' ?>">Estadísticas</a>
            <a href="admin/login.php"    class="nav-admin <?= $_activa === 'admin' ? 'activo' : '' ?>" title="Panel de administración">⚙ Admin</a>
        </nav>
    </div>
</header>