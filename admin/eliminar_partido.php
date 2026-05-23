<?php
session_start();
if (!isset($_SESSION['admin_logueado']) || $_SESSION['admin_logueado'] !== true) {
    header('Location: login.php'); exit;
}

require_once __DIR__ . '/../clases/ConexionDB.php';
require_once __DIR__ . '/../clases/LecDB.php';
require_once __DIR__ . '/../includes/csrf.php';

$idPartido = isset($_GET['id']) ? (int)$_GET['id'] : 0;
if (!$idPartido) { header('Location: panel.php'); exit; }

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['confirmar'])) {
    if (!csrf_verify()) {
        $_SESSION['mensaje'] = 'Token de seguridad inválido.';
        $_SESSION['tipo']    = 'error';
        header('Location: panel.php'); exit;
    }
    $forzar    = isset($_POST['forzar']) && $_POST['forzar'] === '1';
    $resultado = LecDB::eliminarPartido($idPartido, $forzar);
    $_SESSION['mensaje'] = $resultado['mensaje'];
    $_SESSION['tipo']    = $resultado['ok'] ? 'exito' : 'error';
    header('Location: panel.php'); exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['cancelar'])) {
    header('Location: panel.php'); exit;
}

$partido = LecDB::obtenerPartidoAdmin($idPartido);

if (!$partido) {
    $_SESSION['mensaje'] = 'El partido indicado no existe.';
    $_SESSION['tipo']    = 'error';
    header('Location: panel.php'); exit;
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Eliminar partido — LEC Admin</title>
<link rel="stylesheet" href="../assets/css/estilo.css">
</head>
<body class="admin">

<header class="admin-header">
    <div class="header-inner">
        <a href="panel.php" class="logo">LEC Admin</a>
        <nav>
            <a href="panel.php">← Panel</a>
            <a href="logout.php" class="btn-logout">Cerrar sesión</a>
        </nav>
    </div>
</header>

<main class="admin-main">
    <section class="seccion-admin">
        <h2>Eliminar partido</h2>

        <div class="alerta alerta-advertencia">
            <p>¿Estás seguro de que quieres eliminar este partido?</p>
            <p style="margin-top:.5rem">
                <strong><?= htmlspecialchars($partido['equipo_1']) ?></strong>
                vs
                <strong><?= htmlspecialchars($partido['equipo_2']) ?></strong>
                — <?= htmlspecialchars($partido['tipo_serie']) ?>
            </p>
            <?php if ($partido['num_mapas'] > 0): ?>
                <p class="advertencia-mapas">
                    ⚠ Este partido tiene <strong><?= htmlspecialchars($partido['num_mapas']) ?></strong>
                    mapa(s) registrado(s). Al eliminarlo se borrarán también los mapas y todas las
                    estadísticas asociadas. Esta acción no se puede deshacer.
                </p>
            <?php endif; ?>
        </div>

        <form method="POST" action="eliminar_partido.php?id=<?= htmlspecialchars($idPartido) ?>" class="formulario">
            <?= csrf_field() ?>
            <input type="hidden" name="forzar" value="<?= $partido['num_mapas'] > 0 ? '1' : '0' ?>">

            <div class="botones">
                <button type="submit" name="confirmar" class="btn-peligro">Sí, eliminar partido</button>
                <button type="submit" name="cancelar" class="btn-secundario">Cancelar</button>
            </div>
        </form>
    </section>
</main>
</body>
</html>
