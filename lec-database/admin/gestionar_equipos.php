<?php
session_start();
require_once __DIR__ . '/auth.php';
auth('editor');
require_once __DIR__ . '/../clases/ConexionDB.php';
require_once __DIR__ . '/../clases/LecDB.php';
require_once __DIR__ . '/../ImagenHelper.php';
require_once __DIR__ . '/helpers.php';

$pdo = ConexionDB::getInstancia('backend')->getConexion();
$msg = ''; $err = '';

if (($_POST['accion'] ?? '') === 'crear_equipo') {
    $nombre   = trim($_POST['nombre'] ?? '');
    $pais     = trim($_POST['pais'] ?? '');
    $fund     = $_POST['fundacion'] ?: null;
    $idSplitN = (int)($_POST['id_split'] ?? 0);

    if (!$nombre) {
        $err = 'El nombre del equipo es obligatorio.';
    } elseif (!$idSplitN) {
        $err = 'Debes seleccionar un split para registrar el equipo.';
    } else {
        $splitInfo = null;
        foreach (LecDB::listarSplits() as $s) {
            if ((int)$s['id_split'] === $idSplitN) { $splitInfo = $s; break; }
        }
        $res = LecDB::insertarEquipo(
            $nombre, $pais, $fund,
            $splitInfo ? (int)$splitInfo['año'] : null,
            $splitInfo ? $splitInfo['nombre']   : null
        );
        $msg = $res['ok'] ? "✓ Equipo '{$nombre}' creado y registrado en el split." : $res['mensaje'];
        if (!$res['ok']) $err = $res['mensaje'];
    }
}

if (esSuperAdmin() && ($_POST['accion'] ?? '') === 'guardar_equipo') {
    $id     = (int)$_POST['id_equipo'];
    $nombre = trim($_POST['nombre'] ?? '');
    $pais   = trim($_POST['pais'] ?? '');
    $fund   = $_POST['fundacion'] ?: null;
    $activo = isset($_POST['activo']) ? 1 : 0;

    if (!$nombre) {
        $err = 'El nombre del equipo es obligatorio.';
    } else {
        $pdo->exec('SET @admin_bypass = 1');
        $pdo->exec('SET @msg_eq = NULL');
        $stmt = $pdo->prepare('CALL sp_editar_equipo(?,?,?,?,?,@msg_eq)');
        $stmt->execute([$id, $nombre, $pais, $fund, $activo]);
        while ($stmt->nextRowset()) {}
        $r   = $pdo->query('SELECT @msg_eq AS msg')->fetch();
        $pdo->exec('SET @admin_bypass = NULL');
        $msg = $r['msg'] ?? 'Equipo actualizado.';
    }
}

$splits   = LecDB::listarSplits();
$equipos  = LecDB::listarEquipos();
$editEq   = isset($_GET['edit_eq']) ? (int)$_GET['edit_eq'] : null;
$equipoEdit = null;

if ($editEq) {
    foreach ($equipos as $e) {
        if ((int)$e['id_equipo'] === $editEq) { $equipoEdit = $e; break; }
    }
    if (!$equipoEdit) {
        $stmt = $pdo->prepare('SELECT * FROM equipo WHERE id_equipo=?');
        $stmt->execute([$editEq]);
        $equipoEdit = $stmt->fetch() ?: null;
    }
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Gestionar equipos — LEC Admin</title>
<link rel="stylesheet" href="../assets/css/estilo.css">
<style>
.ge-wrap{max-width:1100px;margin:1.5rem auto;padding:0 1.5rem}
.ge-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:.8rem;margin-top:1.2rem}
.ge-card{background:#111;border:1px solid rgba(255,255,255,.07);border-radius:2px;padding:1rem;display:flex;align-items:center;gap:.8rem;transition:border-color .15s}
.ge-card.activo-edit{border-color:var(--cyan)}
.ge-logo{width:40px;height:40px;object-fit:contain;flex-shrink:0}
.ge-nombre{font-family:var(--font-h);font-size:.88rem;font-weight:800;color:#fff}
.ge-pais{font-size:.75rem;color:rgba(255,255,255,.3);margin-top:.15rem}
.form-edit{background:#111;border:1px solid rgba(255,255,255,.15);border-top:2px solid var(--cyan);border-radius:2px;padding:1.5rem;margin-bottom:1.5rem}
.form-edit h3{font-family:var(--font-h);font-size:.72rem;font-weight:800;letter-spacing:2px;text-transform:uppercase;color:var(--cyan);margin:0 0 1.2rem}
.form-row{display:flex;gap:.8rem;flex-wrap:wrap;align-items:flex-end}
.campo-sm label{font-family:var(--font-h);font-size:.58rem;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,.25);display:block;margin-bottom:.3rem}
.campo-sm input,.campo-sm select{background:#1a1a1a;border:1px solid rgba(255,255,255,.1);color:#fff;padding:.4rem .7rem;border-radius:2px;font-size:.85rem}
.campo-sm input:focus,.campo-sm select:focus{outline:none;border-color:var(--cyan)}
.flash-ok{background:rgba(10,200,185,.08);border:1px solid rgba(10,200,185,.2);color:var(--win);padding:.7rem 1rem;border-radius:2px;font-family:var(--font-h);font-size:.8rem;margin-bottom:1rem}
.flash-err{background:rgba(229,57,53,.08);border:1px solid rgba(229,57,53,.2);color:#ef5350;padding:.7rem 1rem;border-radius:2px;font-family:var(--font-h);font-size:.8rem;margin-bottom:1rem}
</style>
</head>
<body style="background:#000">
<?php require_once __DIR__ . '/admin_header.php'; ?>
<div class="ge-wrap">

    <?php if($msg): ?><div class="flash-ok">✓ <?= htmlspecialchars($msg) ?></div><?php endif; ?>
    <?php if($err): ?><div class="flash-err">⚠ <?= htmlspecialchars($err) ?></div><?php endif; ?>

    <?php if ($equipoEdit): ?>
    <div class="form-edit">
        <h3>Editando: <?= htmlspecialchars($equipoEdit['nombre']) ?></h3>
        <form method="POST" class="form-row">
            <input type="hidden" name="accion" value="guardar_equipo">
            <input type="hidden" name="id_equipo" value="<?= $equipoEdit['id_equipo'] ?>">
            <div class="campo-sm">
                <label>Nombre</label>
                <input type="text" name="nombre" value="<?= htmlspecialchars($equipoEdit['nombre']) ?>" required style="width:200px">
            </div>
            <div class="campo-sm">
                <label>País</label>
                <input type="text" name="pais" value="<?= htmlspecialchars($equipoEdit['pais'] ?? '') ?>" style="width:140px">
            </div>
            <div class="campo-sm">
                <label>Fundación</label>
                <input type="date" name="fundacion" value="<?= htmlspecialchars($equipoEdit['fundacion'] ?? '') ?>" style="width:160px">
            </div>
            <div class="campo-sm">
                <label>Estado</label>
                <select name="activo" style="width:110px">
                    <option value="1" <?= ($equipoEdit['activo']??1)?'selected':'' ?>>Activo</option>
                    <option value="0" <?= !($equipoEdit['activo']??1)?'selected':'' ?>>Inactivo</option>
                </select>
            </div>
            <div style="display:flex;gap:.5rem">
                <button type="submit" class="btn-primario">Guardar cambios</button>
                <a href="gestionar_equipos.php" class="btn-secundario">Cancelar</a>
            </div>
        </form>
    </div>
    <?php endif; ?>

    <!-- Formulario crear equipo -->
    <div style="background:#111;border:1px solid rgba(255,255,255,.07);border-radius:2px;padding:1.2rem;margin-bottom:1.5rem">
        <div style="font-family:var(--font-h);font-size:.68rem;font-weight:800;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,.3);margin-bottom:1rem">
            <span style="color:var(--cyan)">+</span> Añadir equipo
        </div>
        <form method="POST" style="display:flex;gap:.7rem;flex-wrap:wrap;align-items:flex-end">
            <input type="hidden" name="accion" value="crear_equipo">
            <div class="campo-sm">
                <label>Nombre *</label>
                <input type="text" name="nombre" required placeholder="Nombre del equipo" style="width:190px">
            </div>
            <div class="campo-sm">
                <label>País</label>
                <input type="text" name="pais" placeholder="España" style="width:130px">
            </div>
            <div class="campo-sm">
                <label>Fundación</label>
                <input type="date" name="fundacion" style="width:155px">
            </div>
            <div class="campo-sm">
                <label>Split *</label>
                <select name="id_split" required style="width:180px">
                    <option value="">Selecciona split...</option>
                    <?php foreach($splits as $s): ?>
                    <option value="<?= $s['id_split'] ?>">
                        <?= htmlspecialchars($s['nombre']==='Winter'?'LEC Versus':$s['nombre']) ?>
                        <?= htmlspecialchars($s['año']) ?>
                    </option>
                    <?php endforeach; ?>
                </select>
            </div>
            <button type="submit" class="btn-primario">Crear equipo</button>
        </form>
    </div>

    <div style="font-family:var(--font-h);font-size:.62rem;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,.2)">
        <?= count($equipos) ?> equipo<?= count($equipos)!==1?'s':'' ?>
    </div>

    <div class="ge-grid">
    <?php foreach ($equipos as $e):
        $logo  = ImagenHelper::logoEquipo($e['nombre']);
        $color = ImagenHelper::colorEquipo($e['nombre']);
        $esEdit = $editEq === (int)$e['id_equipo'];
    ?>
    <div class="ge-card <?= $esEdit?'activo-edit':'' ?>" style="border-color:<?= $esEdit?'var(--cyan)':'rgba(255,255,255,.07)' ?>">
        <img src="../<?= htmlspecialchars($logo) ?>" class="ge-logo"
             onerror="this.style.opacity='.15'" alt="<?= htmlspecialchars($e['nombre']) ?>">
        <div style="flex:1;min-width:0">
            <div class="ge-nombre"><?= htmlspecialchars($e['nombre']) ?></div>
            <div class="ge-pais"><?= htmlspecialchars($e['pais'] ?? '') ?>
                <?php if(!$e['activo']): ?><span style="color:#ef5350;margin-left:.3rem">· Inactivo</span><?php endif; ?>
            </div>
        </div>
        <?php if(esSuperAdmin()): ?><a href="gestionar_equipos.php?edit_eq=<?= $e['id_equipo'] ?>"
           class="btn-secundario" style="padding:.25rem .6rem;font-size:.65rem;white-space:nowrap">Editar</a><?php endif; ?>
    </div>
    <?php endforeach; ?>
    </div>
</div>
</body>
</html>