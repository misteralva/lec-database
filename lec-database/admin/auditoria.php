<?php
session_start();
require_once __DIR__ . '/auth.php';
auth('auditor');

require_once __DIR__ . '/../clases/ConexionDB.php';

try {
    $pdo = ConexionDB::getInstancia('auditor')->getConexion();
} catch (Exception $e) {
    $pdo = ConexionDB::getInstancia('backend')->getConexion();
}

$pagina   = max(1, (int)($_GET['pagina'] ?? 1));
$limite   = 50;
$offset   = ($pagina - 1) * $limite;
$tabla    = $_GET['tabla']  ?? '';
$accion   = $_GET['accion'] ?? '';
$busqueda = $_GET['q']      ?? '';

$where = []; $params = [];
if ($tabla)    { $where[] = 'tabla_afectada = ?'; $params[] = $tabla; }
if ($accion)   { $where[] = 'accion = ?';          $params[] = $accion; }
if ($busqueda) { $where[] = 'detalle LIKE ?';      $params[] = "%$busqueda%"; }
$whereSQL = $where ? 'WHERE ' . implode(' AND ', $where) : '';

try {
    $total = $pdo->prepare("SELECT COUNT(*) FROM auditoria_lec $whereSQL");
    $total->execute($params);
    $totalReg = (int)$total->fetchColumn();
} catch (Exception $e) {
    $totalReg = 0;
}
$totalPag = max(1, (int)ceil($totalReg / $limite));

$stmt = $pdo->prepare("SELECT * FROM auditoria_lec $whereSQL ORDER BY fecha_registro DESC LIMIT $limite OFFSET $offset");
$stmt->execute($params);
$registros = $stmt->fetchAll();

$tablas = $pdo->query("SELECT DISTINCT tabla_afectada FROM auditoria_lec ORDER BY tabla_afectada")->fetchAll(PDO::FETCH_COLUMN);

$stats = [];
try { $stats = $pdo->query("SELECT accion, COUNT(*) AS n FROM auditoria_lec GROUP BY accion")->fetchAll(); } catch(Exception $e){}
?>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Auditoría — LEC Admin</title>
<link rel="stylesheet" href="../assets/css/estilo.css">
<style>
.aud-wrap{max-width:1400px;margin:1.5rem auto;padding:0 1.5rem}
.aud-filtros{display:flex;gap:.6rem;flex-wrap:wrap;align-items:center;margin-bottom:1rem}
.aud-filtros select,.aud-filtros input{background:#111;border:1px solid rgba(255,255,255,.1);color:#fff;padding:.35rem .7rem;border-radius:2px;font-size:.83rem}
.aud-table{width:100%;border-collapse:collapse;font-size:.82rem}
.aud-table th{font-family:var(--font-h);font-size:.55rem;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,.2);padding:.5rem .8rem;border-bottom:1px solid rgba(255,255,255,.07);text-align:left;white-space:nowrap}
.aud-table td{padding:.5rem .8rem;border-bottom:1px solid rgba(255,255,255,.04);vertical-align:top}
.aud-table tr:hover td{background:rgba(255,255,255,.02)}
.badge-INSERT{color:#4caf50;background:rgba(76,175,80,.1);padding:.15rem .5rem;border-radius:2px;font-family:var(--font-h);font-size:.62rem;font-weight:700}
.badge-UPDATE{color:#ff9800;background:rgba(255,152,0,.1);padding:.15rem .5rem;border-radius:2px;font-family:var(--font-h);font-size:.62rem;font-weight:700}
.badge-DELETE{color:#f44336;background:rgba(244,67,54,.1);padding:.15rem .5rem;border-radius:2px;font-family:var(--font-h);font-size:.62rem;font-weight:700}
.aud-stat{background:#111;border:1px solid rgba(255,255,255,.07);padding:.6rem 1rem;border-radius:2px;font-family:var(--font-h);font-size:.65rem;font-weight:700;letter-spacing:1.5px;color:rgba(255,255,255,.3);display:inline-block}
.aud-stat strong{font-size:1.1rem;font-weight:900;color:#fff;display:block}
.pag-btn{font-family:var(--font-h);font-size:.65rem;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;padding:.35rem .8rem;background:#111;border:1px solid rgba(255,255,255,.1);color:rgba(255,255,255,.4);border-radius:2px;text-decoration:none}
.pag-btn.active{border-color:var(--cyan);color:#fff}
</style>
</head>
<body style="background:#000">
<?php require_once __DIR__ . '/admin_header.php'; ?>
<div class="aud-wrap">

    <div style="display:flex;gap:.8rem;margin-bottom:1.2rem;flex-wrap:wrap">
        <?php foreach($stats as $s): ?>
        <div class="aud-stat"><strong><?= number_format($s['n']) ?></strong><?= $s['accion'] ?>s</div>
        <?php endforeach; ?>
        <div class="aud-stat"><strong><?= number_format($totalReg) ?></strong><?= $whereSQL?'filtrados':'registros totales' ?></div>
    </div>

    <form method="GET" class="aud-filtros">
        <select name="tabla">
            <option value="">Todas las tablas</option>
            <?php foreach($tablas as $t): ?><option value="<?= htmlspecialchars($t) ?>" <?= $t===$tabla?'selected':'' ?>><?= htmlspecialchars($t) ?></option><?php endforeach; ?>
        </select>
        <select name="accion">
            <option value="">Todas las acciones</option>
            <?php foreach(['INSERT','UPDATE','DELETE'] as $ac): ?><option value="<?= $ac ?>" <?= $accion===$ac?'selected':'' ?>><?= $ac ?></option><?php endforeach; ?>
        </select>
        <input type="text" name="q" value="<?= htmlspecialchars($busqueda) ?>" placeholder="Buscar en detalle...">
        <button type="submit" class="btn-primario" style="padding:.35rem 1rem">Filtrar</button>
        <?php if($tabla||$accion||$busqueda): ?><a href="auditoria.php" class="btn-secundario" style="padding:.35rem 1rem">Limpiar</a><?php endif; ?>
    </form>
   
    <?php if(empty($registros)): ?>
        <p class="aviso">No hay registros<?= $whereSQL?' con estos filtros':'' ?>.</p>
    <?php else: ?>
    <table class="aud-table">
        <thead><tr><th>#</th><th>Fecha</th><th>Tabla</th><th>Acción</th><th>Usuario BD</th><th>Detalle</th></tr></thead>
        <tbody>
        <?php foreach($registros as $r): ?>
        <tr>
            <td style="color:rgba(255,255,255,.2);font-size:.75rem"><?= $r['id_auditoria'] ?></td>
            <td style="white-space:nowrap;color:rgba(255,255,255,.5);font-size:.78rem"><?= date('d/m/Y H:i:s',strtotime($r['fecha_registro'])) ?></td>
            <td><span style="font-family:var(--font-h);font-size:.72rem;font-weight:700;color:var(--cyan)"><?= htmlspecialchars($r['tabla_afectada']) ?></span></td>
            <td><span class="badge-<?= $r['accion'] ?>"><?= $r['accion'] ?></span></td>
            <td style="color:rgba(255,255,255,.3);font-size:.75rem;font-family:var(--font-h)"><?= htmlspecialchars($r['usuario']??'—') ?></td>
            <td style="color:rgba(255,255,255,.4);font-size:.78rem;max-width:500px"><?= htmlspecialchars($r['detalle']??'—') ?></td>
        </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
    <?php if($totalPag>1): ?>
    <div style="display:flex;gap:.4rem;margin-top:1.2rem;align-items:center">
        <?php for($i=max(1,$pagina-3);$i<=min($totalPag,$pagina+3);$i++): ?>
            <a href="?pagina=<?=$i?>&tabla=<?=urlencode($tabla)?>&accion=<?=urlencode($accion)?>&q=<?=urlencode($busqueda)?>" class="pag-btn <?=$i===$pagina?'active':'' ?>"><?=$i?></a>
        <?php endfor; ?>
        <div class="aud-stat" style="margin-left:.5rem">Pág. <?=$pagina?> de <?=$totalPag?></div>
    </div>
    <?php endif; ?>
    <?php endif; ?>
</div>
</body>
</html>