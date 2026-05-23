<?php
session_start();
require_once __DIR__ . '/auth.php';
auth('editor');

require_once __DIR__ . '/../clases/ConexionDB.php';
require_once __DIR__ . '/../clases/LecDB.php';
require_once __DIR__ . '/../includes/csrf.php';

$error = '';

$splits = LecDB::listarSplits();

$idSplitSel  = !empty($splits)
    ? (isset($_POST['id_split']) ? (int)$_POST['id_split'] : (int)$splits[0]['id_split'])
    : 0;

$fases       = $idSplitSel ? LecDB::listarFasesPorSplit($idSplitSel)       : [];
$historiales = $idSplitSel ? LecDB::listarHistorialesPorSplit($idSplitSel) : [];

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['crear'])) {
    if (!csrf_verify()) {
        $error = 'Token de seguridad inválido. Recarga la página.';
    } else {
        $idFase    = (int)   ($_POST['id_fase']      ?? 0);
        $idHistEq1 = (int)   ($_POST['id_hist_eq1']  ?? 0);
        $idHistEq2 = (int)   ($_POST['id_hist_eq2']  ?? 0);
        $fechaHora = trim(    $_POST['fecha_hora']    ?? '');
        $tipoSerie = trim(    $_POST['tipo_serie']    ?? '');

        if (!$idFase || !$idHistEq1 || !$idHistEq2 || !$fechaHora || !$tipoSerie) {
            $error = 'Debes rellenar todos los campos.';
        } elseif ($idHistEq1 === $idHistEq2) {
            $error = 'Los dos equipos no pueden ser el mismo.';
        } else {
            $resultado = LecDB::registrarPartido($idFase, $idHistEq1, $idHistEq2, $fechaHora, $tipoSerie);
            if ($resultado['ok']) {
                $_SESSION['mensaje'] = $resultado['mensaje'];
                $_SESSION['tipo']    = 'exito';
                header('Location: panel.php'); exit;
            } else {
                $error = $resultado['mensaje'];
            }
        }
    }
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Nuevo partido — LEC Admin</title>
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
        <h2>Nuevo partido</h2>

        <?php if ($error): ?>
            <div class="alerta alerta-error"><?= htmlspecialchars($error) ?></div>
        <?php endif; ?>

        <form method="POST" action="nuevo_partido.php" class="formulario">
            <?= csrf_field() ?>

            <div class="campo">
                <label>Split</label>
                <select name="id_split" onchange="this.form.submit()">
                    <?php foreach ($splits as $s): ?>
                        <option value="<?= htmlspecialchars($s['id_split']) ?>"
                            <?= (int)$s['id_split'] === $idSplitSel ? 'selected' : '' ?>>
                            <?= htmlspecialchars($s['nombre']) ?> <?= htmlspecialchars($s['año']) ?>
                            <?= empty($s['fecha_fin']) ? '(activo)' : '' ?>
                        </option>
                    <?php endforeach; ?>
                </select>
            </div>

            <div class="campo">
                <label>Fase</label>
                <select name="id_fase" required>
                    <?php foreach ($fases as $f): ?>
                        <option value="<?= htmlspecialchars($f['id_fase']) ?>"
                            <?= isset($_POST['id_fase']) && (int)$_POST['id_fase'] === (int)$f['id_fase'] ? 'selected' : '' ?>>
                            <?= htmlspecialchars($f['tipo']) ?> (<?= htmlspecialchars($f['formato']) ?>)
                        </option>
                    <?php endforeach; ?>
                </select>
            </div>

            <div class="campo">
                <label>Equipo 1</label>
                <select name="id_hist_eq1" required>
                    <?php foreach ($historiales as $h): ?>
                        <option value="<?= htmlspecialchars($h['id_historial_equipo']) ?>"
                            <?= isset($_POST['id_hist_eq1']) && (int)$_POST['id_hist_eq1'] === (int)$h['id_historial_equipo'] ? 'selected' : '' ?>>
                            <?= htmlspecialchars($h['nombre']) ?>
                        </option>
                    <?php endforeach; ?>
                </select>
            </div>

            <div class="campo">
                <label>Equipo 2</label>
                <select name="id_hist_eq2" required>
                    <?php foreach ($historiales as $h): ?>
                        <option value="<?= htmlspecialchars($h['id_historial_equipo']) ?>"
                            <?= isset($_POST['id_hist_eq2']) && (int)$_POST['id_hist_eq2'] === (int)$h['id_historial_equipo'] ? 'selected' : '' ?>>
                            <?= htmlspecialchars($h['nombre']) ?>
                        </option>
                    <?php endforeach; ?>
                </select>
            </div>

            <div class="campo">
                <label>Fecha y hora</label>
                <input type="datetime-local" name="fecha_hora"
                       value="<?= htmlspecialchars($_POST['fecha_hora'] ?? '') ?>" required>
            </div>

            <div class="campo">
                <label>Tipo de serie</label>
                <select name="tipo_serie" required>
                    <option value="Bo1" <?= ($_POST['tipo_serie'] ?? '') === 'Bo1' ? 'selected' : '' ?>>Bo1</option>
                    <option value="Bo3" <?= ($_POST['tipo_serie'] ?? '') === 'Bo3' ? 'selected' : '' ?>>Bo3</option>
                    <option value="Bo5" <?= ($_POST['tipo_serie'] ?? '') === 'Bo5' ? 'selected' : '' ?>>Bo5</option>
                </select>
            </div>

            <div class="botones">
                <button type="submit" name="crear" class="btn-primario">Crear partido</button>
                <a href="panel.php" class="btn-secundario">Cancelar</a>
            </div>
        </form>
    </section>
</main>
</body>
</html>