<?php
session_start();
if (!isset($_SESSION['admin_logueado']) || $_SESSION['admin_logueado'] !== true) {
    header('Location: login.php'); exit;
}
require_once __DIR__ . '/../clases/ConexionDB.php';
require_once __DIR__ . '/../clases/LecDB.php';
require_once __DIR__ . '/../includes/csrf.php';

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!csrf_verify()) {
        $error = 'Token de seguridad inválido. Recarga la página.';
    } else {
        $nombre    = trim($_POST['nombre']       ?? '');
        $pais      = trim($_POST['pais']         ?? '');
        $fundacion = $_POST['fundacion']         ?? null;
        $año       = !empty($_POST['año'])       ? (int)$_POST['año'] : null;
        $splitN    = !empty($_POST['split_nombre']) ? $_POST['split_nombre'] : null;

        if (!$nombre) {
            $error = 'El nombre del equipo es obligatorio.';
        } else {
            $res = LecDB::insertarEquipo($nombre, $pais, $fundacion ?: null, $año, $splitN);
            if ($res['ok']) {
                $_SESSION['mensaje'] = $res['mensaje'];
                $_SESSION['tipo']    = 'exito';
                header('Location: panel.php'); exit;
            } else {
                $error = $res['mensaje'];
            }
        }
    }
}

$splits = LecDB::listarSplits(true);
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Nuevo equipo — LEC Admin</title>
    <link rel="stylesheet" href="../assets/css/estilo.css">
</head>
<body class="admin">
<header class="admin-header">
    <div class="header-inner">
        <a href="panel.php" class="logo">LEC Admin</a>
        <nav><a href="panel.php">← Panel</a><a href="logout.php" class="btn-logout">Cerrar sesión</a></nav>
    </div>
</header>
<main class="admin-main">
    <section class="seccion-admin">
        <h2>Nuevo equipo</h2>

        <?php if ($error): ?>
            <div class="alerta alerta-error"><?= htmlspecialchars($error) ?></div>
        <?php endif; ?>

        <form method="POST" action="nuevo_equipo.php" class="formulario">
            <?= csrf_field() ?>
            <div class="campo">
                <label>Nombre del equipo <span style="color:red">*</span></label>
                <input type="text" name="nombre" value="<?= htmlspecialchars($_POST['nombre'] ?? '') ?>" required>
            </div>
            <div class="campo">
                <label>País</label>
                <input type="text" name="pais" value="<?= htmlspecialchars($_POST['pais'] ?? '') ?>">
            </div>
            <div class="campo">
                <label>Fecha de fundación</label>
                <input type="date" name="fundacion" value="<?= htmlspecialchars($_POST['fundacion'] ?? '') ?>">
            </div>
            <div class="campo">
                <label>Registrar en split (opcional)</label>
                <select name="año">
                    <option value="">No registrar en ningún split</option>
                    <?php foreach ($splits as $s): ?>
                        <option value="<?= htmlspecialchars($s['año']) ?>"
                            data-nombre="<?= htmlspecialchars($s['nombre']) ?>"
                            <?= ($_POST['año'] ?? '') == $s['año'] ? 'selected' : '' ?>>
                            <?= htmlspecialchars($s['nombre_completo']) ?>
                        </option>
                    <?php endforeach; ?>
                </select>
                <input type="hidden" name="split_nombre" id="split_nombre">
            </div>
            <div class="botones">
                <button type="submit" class="btn-primario">Crear equipo</button>
                <a href="panel.php" class="btn-secundario">Cancelar</a>
            </div>
        </form>
    </section>
</main>
<script>
    
document.querySelector('select[name="año"]').addEventListener('change', function() {
    const opt = this.options[this.selectedIndex];
    document.getElementById('split_nombre').value = opt.dataset.nombre || '';
});
</script>
</body>
</html>
