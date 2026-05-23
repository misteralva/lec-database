<?php
session_start();
require_once __DIR__ . '/auth.php';
auth('superadmin');
require_once __DIR__ . '/../clases/ConexionDB.php';
require_once __DIR__ . '/../clases/LecDB.php';
require_once __DIR__ . '/helpers.php';

$pdo = ConexionDB::getInstancia('backend')->getConexion();
$msg = ''; $err = '';

if (($_POST['accion'] ?? '') === 'cerrar_split') {
    $id     = (int)$_POST['id_split'];
    $fecha  = $_POST['fecha_fin_cierre'] ?: date('Y-m-d');
    $pdo->exec('SET @msg_cierre = NULL');
    $stmt = $pdo->prepare('CALL sp_cerrar_split(?,?,@msg_cierre)');
    $stmt->execute([$id, $fecha]);
    while ($stmt->nextRowset()) {}
    $r   = $pdo->query('SELECT @msg_cierre AS msg')->fetch();
    $msg = $r['msg'] ?? 'Split cerrado.';
    if (str_starts_with($msg, 'Err')) $err = $msg;
}

if (($_POST['accion'] ?? '') === 'crear_split') {
    $nombre   = trim($_POST['nombre'] ?? '');
    $año      = (int)($_POST['año'] ?? date('Y'));
    $inicio   = $_POST['fecha_inicio'] ?? null;
    $fin      = $_POST['fecha_fin'] ?: null;
    $fase     = trim($_POST['tipo_fase'] ?? 'Regular Season');
    $incluir  = isset($_POST['incluir_equipos']) ? 1 : 0;

    if (!$nombre || !$año || !$inicio) {
        $err = 'Nombre, año y fecha de inicio son obligatorios.';
    } else {
        $pdo->exec('SET @id_split = NULL, @msg_split = NULL');
        $stmt = $pdo->prepare('CALL sp_crear_split(?,?,?,?,?,?,@id_split,@msg_split)');
        $stmt->execute([$nombre, $año, $inicio, $fin, $fase, $incluir]);
        while ($stmt->nextRowset()) {}
        $r   = $pdo->query('SELECT @id_split AS id, @msg_split AS msg')->fetch();
        $msg = $r['msg'] ?? 'Split creado.';
        if (!$r['id']) $err = $msg;
    }
}

$splits = callSP($pdo, 'CALL sp_listar_splits_admin()');
$añoActual = (int)date('Y');
?>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Gestionar splits — LEC Admin</title>
<link rel="stylesheet" href="../assets/css/estilo.css">
<style>
.gs-wrap{max-width:900px;margin:1.5rem auto;padding:0 1.5rem}
.gs-card{background:#111;border:1px solid rgba(255,255,255,.07);border-radius:2px;padding:1rem 1.2rem;margin-bottom:.6rem;display:flex;align-items:center;gap:1.2rem;flex-wrap:wrap}
.gs-año{font-family:var(--font-h);font-size:1.4rem;font-weight:900;color:var(--cyan);min-width:50px}
.gs-nombre{font-family:var(--font-h);font-size:.9rem;font-weight:800;color:#fff;flex:1}
.gs-meta{font-family:var(--font-h);font-size:.65rem;color:rgba(255,255,255,.25);display:flex;gap:1rem}
.gs-badge{font-family:var(--font-h);font-size:.6rem;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;padding:.2rem .6rem;border-radius:2px;white-space:nowrap}
.flash-ok{background:rgba(10,200,185,.08);border:1px solid rgba(10,200,185,.2);color:var(--win);padding:.7rem 1rem;border-radius:2px;font-family:var(--font-h);font-size:.8rem;margin-bottom:1rem}
.flash-err{background:rgba(229,57,53,.08);border:1px solid rgba(229,57,53,.2);color:#ef5350;padding:.7rem 1rem;border-radius:2px;font-family:var(--font-h);font-size:.8rem;margin-bottom:1rem}
.campo-sm label{font-family:var(--font-h);font-size:.58rem;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,.25);display:block;margin-bottom:.3rem}
.campo-sm input,.campo-sm select{background:#1a1a1a;border:1px solid rgba(255,255,255,.1);color:#fff;padding:.4rem .7rem;border-radius:2px;font-size:.85rem}
.campo-sm input:focus,.campo-sm select:focus{outline:none;border-color:var(--cyan)}
</style>
</head>
<body style="background:#000">
<?php require_once __DIR__ . '/admin_header.php'; ?>
<div class="gs-wrap">

    <?php if($msg && !$err): ?><div class="flash-ok">✓ <?= htmlspecialchars($msg) ?></div><?php endif; ?>
    <?php if($err): ?><div class="flash-err">⚠ <?= htmlspecialchars($err) ?></div><?php endif; ?>

    
    <div style="background:#111;border:1px solid rgba(255,255,255,.07);border-top:2px solid var(--cyan);border-radius:2px;padding:1.5rem;margin-bottom:2rem">
        <div style="font-family:var(--font-h);font-size:.7rem;font-weight:800;letter-spacing:2px;text-transform:uppercase;color:var(--cyan);margin-bottom:1.2rem">
            + Nuevo split
        </div>
        <form method="POST" style="display:flex;gap:.8rem;flex-wrap:wrap;align-items:flex-end">
            <input type="hidden" name="accion" value="crear_split">

            <div class="campo-sm">
                <label>Nombre *</label>
                <select name="nombre" style="width:160px">
                    <option value="Spring">Spring</option>
                    <option value="Summer">Summer</option>
                    <option value="Winter">LEC Versus (Winter)</option>
                </select>
            </div>

            <div class="campo-sm">
                <label>Año *</label>
                <input type="number" name="año" value="<?= $añoActual + 1 ?>"
                       min="2024" max="2035" style="width:90px">
            </div>

            <div class="campo-sm">
                <label>Inicio *</label>
                <input type="date" name="fecha_inicio" style="width:160px"
                       value="<?= ($añoActual+1) ?>-01-15">
            </div>

            <div class="campo-sm">
                <label>Fin</label>
                <input type="date" name="fecha_fin" style="width:160px"
                       value="<?= ($añoActual+1) ?>-04-30">
            </div>

            <div class="campo-sm">
                <label>Tipo de fase</label>
                <select name="tipo_fase" style="width:160px">
                    <option value="Regular Season">Regular Season</option>
                    <option value="Playoffs">Playoffs</option>
                    <option value="Play-In">Play-In</option>
                </select>
            </div>

            <div class="campo-sm" style="align-self:center;margin-top:.8rem">
                <label style="display:flex;align-items:center;gap:.4rem;cursor:pointer">
                    <input type="checkbox" name="incluir_equipos" value="1" checked>
                    Añadir todos los equipos activos
                </label>
            </div>

            <button type="submit" class="btn-primario">Crear split</button>
        </form>
        <p style="font-family:var(--font-h);font-size:.65rem;color:rgba(255,255,255,.2);margin-top:.8rem">
            Si marcas "Añadir todos los equipos activos", los 10 equipos actuales se registrarán automáticamente en el nuevo split.
        </p>
    </div>

    
    <div style="font-family:var(--font-h);font-size:.62rem;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,.2);margin-bottom:.8rem">
        <?= count($splits) ?> splits registrados
    </div>

    <?php foreach ($splits as $s): ?>
    <div class="gs-card">
        <div class="gs-año"><?= $s['año'] ?></div>
        <div style="flex:1">
            <div class="gs-nombre">
                <?= htmlspecialchars($s['nombre'] === 'Winter' ? 'LEC Versus' : $s['nombre']) ?>
                <span style="font-weight:400;color:rgba(255,255,255,.3);font-size:.75rem;margin-left:.4rem">
                    Split #<?= $s['id_split'] ?>
                </span>
            </div>
            <div class="gs-meta">
                <?php if($s['fecha_inicio']): ?>
                <span><?= date('d/m/Y', strtotime($s['fecha_inicio'])) ?>
                    <?= $s['fecha_fin'] ? ' — ' . date('d/m/Y', strtotime($s['fecha_fin'])) : '' ?>
                </span>
                <?php endif; ?>
                <span><?= $s['num_equipos'] ?> equipos</span>
                <span><?= $s['num_partidos'] ?> partidos</span>
            </div>
        </div>
        <?php if (!$s['fecha_fin'] || strtotime($s['fecha_fin']) >= strtotime('today')): ?>
        <form method="POST" style="display:flex;gap:.5rem;align-items:center"
              onsubmit="return confirm('¿Cerrar este split? Se pondrá la fecha de fin y no se podrán añadir más partidos.')">
            <input type="hidden" name="accion" value="cerrar_split">
            <input type="hidden" name="id_split" value="<?= $s['id_split'] ?>">
            <input type="date" name="fecha_fin_cierre"
                   value="<?= date('Y-m-d') ?>"
                   style="background:#1a1a1a;border:1px solid rgba(255,255,255,.1);color:#fff;padding:.3rem .5rem;border-radius:2px;font-size:.8rem">
            <button type="submit" class="btn-secundario"
                    style="padding:.3rem .7rem;font-size:.7rem;color:#ff9800;border-color:rgba(255,152,0,.3)">
                Cerrar split
            </button>
        </form>
        <?php else: ?>
        <span class="gs-badge" style="background:rgba(255,255,255,.04);color:rgba(255,255,255,.25);border:1px solid rgba(255,255,255,.07)">
            Cerrado <?= date('d/m/Y', strtotime($s['fecha_fin'])) ?>
        </span>
        <?php endif; ?>
    </div>
    <?php endforeach; ?>

</div>
</body>
</html>