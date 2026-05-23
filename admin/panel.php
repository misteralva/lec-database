<?php
session_start();
require_once __DIR__ . '/auth.php';

if (isset($_SESSION['usuario_rol']) && $_SESSION['usuario_rol'] === 'auditor') {
    header('Location: auditoria.php'); exit;
}
auth('editor');
if (!isset($_SESSION['admin_logueado']) || $_SESSION['admin_logueado'] !== true) {
    header('Location: login.php'); exit;
}

require_once __DIR__ . '/../clases/ConexionDB.php';
require_once __DIR__ . '/../clases/LecDB.php';
require_once __DIR__ . '/../includes/csrf.php';

$año         = isset($_GET['año'])          ? (int)$_GET['año']          : null;
$splitNombre = isset($_GET['split_nombre']) ? trim($_GET['split_nombre']) : null;
$finalizado  = isset($_GET['finalizado'])   ? (int)$_GET['finalizado']   : null;
$seccion     = $_GET['sec'] ?? 'pendientes';

$filtroFinalizado = $finalizado === 1 ? true : ($finalizado === 0 ? false : null);
$partidos = LecDB::listarPartidos(null, $filtroFinalizado, $año, $splitNombre);
$equipos  = LecDB::listarEquipos(null, $año, $splitNombre);
$años     = LecDB::listarAños();

$pdo = ConexionDB::getInstancia()->getConexion();
$totalPartidos  = (int)$pdo->query("SELECT COUNT(*) FROM partido")->fetchColumn();
$pendientes     = (int)$pdo->query("SELECT COUNT(*) FROM partido WHERE finalizado=FALSE")->fetchColumn();
$totalJugadores = (int)$pdo->query("SELECT COUNT(*) FROM jugador")->fetchColumn();
$totalEquipos   = (int)$pdo->query("SELECT COUNT(*) FROM equipo WHERE activo=TRUE")->fetchColumn();
$totalMapas     = (int)$pdo->query("SELECT COUNT(*) FROM mapa")->fetchColumn();
$totalStats     = (int)$pdo->query("SELECT COUNT(*) FROM estadistica_jugador")->fetchColumn();

$mensaje = $_SESSION['mensaje'] ?? null;
$tipo    = $_SESSION['tipo']    ?? null;
unset($_SESSION['mensaje'], $_SESSION['tipo']);
?>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Panel Admin — LEC</title>
<link rel="stylesheet" href="../assets/css/estilo.css">
<style>
.admin-layout { display:grid; grid-template-columns:220px 1fr; min-height:calc(100vh - 52px); }
.sidebar {
    background:#080808; border-right:1px solid rgba(255,255,255,.06);
    padding:1.2rem 0; position:sticky; top:52px;
    height:calc(100vh - 52px); overflow-y:auto;
}
.sb-section { font-family:var(--font-h); font-size:.52rem; font-weight:700; letter-spacing:3px; text-transform:uppercase; color:rgba(255,255,255,.15); padding:.6rem 1.4rem .25rem; margin-top:.5rem; }
.sb-link {
    display:flex; align-items:center; gap:.7rem; padding:.6rem 1.4rem;
    color:rgba(255,255,255,.4); font-family:var(--font-h); font-size:.78rem; font-weight:700;
    letter-spacing:1.5px; text-transform:uppercase; text-decoration:none;
    border-left:2px solid transparent; transition:color .12s, background .12s, border-color .12s;
}
.sb-link:hover { color:rgba(255,255,255,.75); background:rgba(255,255,255,.025); }
.sb-link.on { color:#fff; border-left-color:var(--cyan); background:rgba(10,200,185,.05); }
.sb-icon { width:18px; text-align:center; flex-shrink:0; font-size:.95rem; }
.sb-badge { margin-left:auto; font-family:var(--font-h); font-size:.58rem; font-weight:800; background:var(--win); color:#000; padding:.1rem .45rem; border-radius:1px; min-width:18px; text-align:center; }

.main-area { padding:1.8rem 2rem; }
.metrics { display:grid; grid-template-columns:repeat(6,1fr); gap:1px; background:#000; margin-bottom:1.8rem; }
.metric { background:#111; padding:1.1rem 1.3rem; }
.metric-n { font-family:var(--font-h); font-size:1.9rem; font-weight:900; color:#fff; line-height:1; }
.metric-n.hi { color:var(--win); }
.metric-l { font-family:var(--font-h); font-size:.55rem; font-weight:700; letter-spacing:2px; text-transform:uppercase; color:rgba(255,255,255,.2); margin-top:.25rem; }

.top-bar { display:flex; align-items:center; justify-content:space-between; margin-bottom:1.2rem; }
.page-title { font-family:var(--font-h); font-size:1.1rem; font-weight:900; letter-spacing:2px; text-transform:uppercase; color:#fff; }

.tabs { display:flex; border-bottom:1px solid rgba(255,255,255,.06); margin-bottom:1.4rem; }
.tab { font-family:var(--font-h); font-size:.7rem; font-weight:700; letter-spacing:2px; text-transform:uppercase; color:rgba(255,255,255,.3); padding:.65rem 1.2rem; border-bottom:2px solid transparent; text-decoration:none; transition:color .12s, border-color .12s; }
.tab:hover { color:rgba(255,255,255,.6); }
.tab.on { color:#fff; border-bottom-color:var(--cyan); }

.filter-row { display:flex; align-items:center; gap:.6rem; margin-bottom:1.1rem; flex-wrap:wrap; }
.filter-select { background:#111; border:1px solid rgba(255,255,255,.1); color:rgba(255,255,255,.7); padding:.38rem .7rem; border-radius:2px; font-size:.8rem; font-family:var(--font-b); }
.filter-select:focus { outline:none; border-color:var(--cyan); }
.filter-select option { background:#111; }

.match-row {
    display:grid; grid-template-columns:1fr auto 1fr auto; align-items:center; gap:1rem;
    padding:.8rem 0; border-bottom:1px solid rgba(255,255,255,.04); transition:background .1s;
}
.match-row:hover { background:rgba(255,255,255,.02); }
.match-row.pending { border-left:2px solid var(--win); padding-left:.8rem; }
.match-team { font-family:var(--font-h); font-size:.95rem; font-weight:700; color:#fff; }
.match-team.dim { color:rgba(255,255,255,.25); }
.match-team.right { text-align:right; }
.match-meta { font-family:var(--font-h); font-size:.58rem; font-weight:600; letter-spacing:2px; text-transform:uppercase; color:rgba(255,255,255,.18); margin-bottom:2px; }
.match-score { font-family:var(--font-h); font-size:1.3rem; font-weight:900; letter-spacing:3px; text-align:center; }
.match-pending-label { font-family:var(--font-h); font-size:.65rem; font-weight:700; letter-spacing:2px; color:rgba(255,255,255,.2); }
.match-actions { display:flex; gap:.35rem; }

.empty-msg { padding:3rem; text-align:center; font-family:var(--font-h); font-size:.72rem; font-weight:700; letter-spacing:2px; text-transform:uppercase; color:rgba(255,255,255,.15); }

.flash { padding:.6rem 1rem; border-radius:2px; margin-bottom:1rem; font-family:var(--font-h); font-size:.8rem; font-weight:700; letter-spacing:1px; }
.flash-ok  { background:rgba(10,200,185,.08); border:1px solid rgba(10,200,185,.2); color:var(--win); }
.flash-err { background:rgba(229,57,53,.08);  border:1px solid rgba(229,57,53,.2);  color:#ef5350; }

@media(max-width:1000px){ .admin-layout{grid-template-columns:1fr;} .sidebar{display:none;} .metrics{grid-template-columns:repeat(3,1fr);} }
@media(max-width:600px){ .metrics{grid-template-columns:repeat(2,1fr);} .match-row{grid-template-columns:1fr;} }
</style>
</head>
<body style="background:#000">


<header style="background:#080808;border-bottom:1px solid rgba(255,255,255,.08);padding:0 1.5rem;position:sticky;top:0;z-index:200">
<div style="display:flex;align-items:center;height:52px;gap:1.2rem">
    <a href="auditoria.php" class="sidebar-link">🔍 Auditoría</a>
        <a href="panel.php" style="font-family:'Barlow Condensed',sans-serif;font-size:1.05rem;font-weight:900;letter-spacing:3px;text-transform:uppercase;color:#fff;text-decoration:none;flex-shrink:0">
        <span style="color:var(--cyan)">⚡</span> LEC Admin
    </a>
    <div style="width:1px;height:18px;background:rgba(255,255,255,.08);flex-shrink:0"></div>
    <a href="nuevo_partido.php"      style="font-family:'Barlow Condensed',sans-serif;font-size:.7rem;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,.55);text-decoration:none;padding:.3rem .75rem;border:1px solid rgba(255,255,255,.1);border-radius:2px;white-space:nowrap;transition:color .12s,border-color .12s">+ Partido</a>
    
    
    <a href="../index.php" target="_blank" style="font-family:'Barlow Condensed',sans-serif;font-size:.7rem;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,.4);text-decoration:none;margin-left:auto;white-space:nowrap">Ver web ↗</a>
    <span style="font-family:'Barlow Condensed',sans-serif;font-size:.68rem;color:rgba(255,255,255,.2);white-space:nowrap">👤 <?= htmlspecialchars(usuarioNombre()) ?> <span style='font-size:.6rem;color:rgba(255,255,255,.2);margin-left:.3rem'><?= usuarioRol() ?></span></span>
    <a href="logout.php" style="font-family:'Barlow Condensed',sans-serif;font-size:.68rem;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,.3);text-decoration:none;padding:.28rem .7rem;border:1px solid rgba(255,255,255,.07);border-radius:2px;white-space:nowrap">Salir</a>
</div>
</header>

<?php if ($mensaje): ?>
<div class="flash flash-<?= $tipo==='exito'?'ok':'err' ?>" style="margin:0;border-radius:0;border-left:none;border-right:none;border-top:none">
    <?= htmlspecialchars($mensaje) ?>
</div>
<?php endif; ?>

<div class="admin-layout">


<aside class="sidebar">
    <div class="sb-section">Principal</div>
    <a href="panel.php?sec=pendientes" class="sb-link <?= $seccion==='pendientes'?'on':'' ?>">
        <span class="sb-icon">⏳</span> Pendientes
        <?php if ($pendientes > 0): ?><span class="sb-badge"><?= $pendientes ?></span><?php endif; ?>
    </a>
    <a href="panel.php?sec=partidos" class="sb-link <?= $seccion==='partidos'?'on':'' ?>">
        <span class="sb-icon">🎮</span> Todos los partidos
    </a>
    <div class="sb-section">Añadir</div>
    <a href="nuevo_partido.php" class="sb-link">
        <span class="sb-icon">➕</span> Nuevo partido
    </a>
    <div class="sb-section">Ver</div>
    <a href="panel.php?sec=equipos" class="sb-link <?= $seccion==='equipos'?'on':'' ?>">
        <span class="sb-icon">📋</span> Equipos
    </a>
    <div style="border-top:1px solid rgba(255,255,255,.06);margin:.5rem 0"></div>
    <?php if(esEditor()): ?>
    <a href="gestionar_equipos.php" class="sb-link">🏟 Gestionar equipos</a>
    <a href="gestionar_jugadores.php" class="sb-link">👤 Gestionar jugadores</a>
    <?php endif; ?>
    <?php if(esSuperAdmin()): ?>
    <a href="gestionar_splits.php" class="sb-link">📅 Gestionar splits</a>
    <a href="gestionar_usuarios.php" class="sb-link">👥 Gestionar usuarios</a>
    <a href="auditoria.php" class="sb-link">🔍 Auditoría</a>
    <?php endif; ?>
    <a href="../estadisticas.php" target="_blank" class="sb-link">
        <span class="sb-icon">📈</span> Estadísticas web ↗
    </a>
    <a href="../index.php" target="_blank" class="sb-link">
        <span class="sb-icon">🌐</span> Sitio web ↗
    </a>
</aside>


<div class="main-area">

   
    <div class="metrics">
        <div class="metric"><div class="metric-n hi"><?= $pendientes ?></div><div class="metric-l">Pendientes</div></div>
        <div class="metric"><div class="metric-n"><?= $totalPartidos ?></div><div class="metric-l">Partidos</div></div>
        <div class="metric"><div class="metric-n"><?= $totalMapas ?></div><div class="metric-l">Mapas</div></div>
        <div class="metric"><div class="metric-n"><?= $totalStats ?></div><div class="metric-l">Estadísticas</div></div>
        <div class="metric"><div class="metric-n"><?= $totalEquipos ?></div><div class="metric-l">Equipos</div></div>
        <div class="metric"><div class="metric-n"><?= $totalJugadores ?></div><div class="metric-l">Jugadores</div></div>
    </div>

    <?php if ($seccion === 'pendientes'): ?>
    
    <div class="top-bar">
        <div class="page-title">Partidos pendientes <span style="color:var(--win);font-size:.9rem">(<?= $pendientes ?>)</span></div>
        <a href="nuevo_partido.php" class="btn-primario">+ Nuevo partido</a>
    </div>
    <?php
    $pend = LecDB::listarPartidos(null, false, $año, $splitNombre);
    if (empty($pend)): ?>
        <div class="empty-msg">No hay partidos pendientes</div>
    <?php else: ?>
        
        <form method="GET" action="panel.php" class="filter-row">
            <input type="hidden" name="sec" value="pendientes">
            <select name="split_nombre" class="filter-select" onchange="this.form.submit()">
                <option value="">Todos los splits</option>
                <option value="Spring" <?= $splitNombre==='Spring'?'selected':'' ?>>Spring</option>
                <option value="Summer" <?= $splitNombre==='Summer'?'selected':'' ?>>Summer</option>
                <option value="Winter" <?= $splitNombre==='Winter'?'selected':'' ?>>LEC Versus</option>
            </select>
            <select name="año" class="filter-select" onchange="this.form.submit()">
                <option value="">Todos los años</option>
                <?php foreach ($años as $a): ?>
                    <option value="<?= $a['año'] ?>" <?= $año==$a['año']?'selected':'' ?>><?= $a['año'] ?></option>
                <?php endforeach; ?>
            </select>
            <a href="panel.php?sec=pendientes" style="font-family:var(--font-h);font-size:.68rem;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,.3);text-decoration:none">Limpiar</a>
        </form>
        <?php foreach ($pend as $p): ?>
        <div class="match-row pending">
            <div>
                <div class="match-meta"><?= date('d/m/Y H:i', strtotime($p['fecha_hora'])) ?> · <?= htmlspecialchars($p['split']==='Winter'?'LEC Versus':$p['split']) ?> <?= $p['año'] ?> · <?= htmlspecialchars($p['tipo_serie']) ?></div>
                <div class="match-team"><?= htmlspecialchars($p['equipo_1']) ?></div>
            </div>
            <div class="match-pending-label">PENDIENTE</div>
            <div>
                <div class="match-meta" style="text-align:right"><?= htmlspecialchars($p['fase']) ?></div>
                <div class="match-team right"><?= htmlspecialchars($p['equipo_2']) ?></div>
            </div>
            <div class="match-actions">
                <a href="editar_resultado.php?id=<?= $p['id_partido'] ?>" class="btn-primario" style="padding:.38rem .9rem;font-size:.72rem">✏ Resultado + Stats</a>
                <a href="eliminar_partido.php?id=<?= $p['id_partido'] ?>" class="btn-peligro" style="padding:.38rem .6rem;font-size:.72rem">✕</a>
            </div>
        </div>
        <?php endforeach; ?>
    <?php endif; ?>

    <?php elseif ($seccion === 'partidos'): ?>
    
    <div class="top-bar">
        <div class="page-title">Partidos</div>
        <a href="nuevo_partido.php" class="btn-primario">+ Nuevo</a>
    </div>
    <form method="GET" action="panel.php" class="filter-row">
        <input type="hidden" name="sec" value="partidos">
        <select name="año"          class="filter-select"><option value="">Todos los años</option><?php foreach ($años as $a): ?><option value="<?= $a['año'] ?>" <?= $año==$a['año']?'selected':'' ?>><?= $a['año'] ?></option><?php endforeach; ?></select>
        <select name="split_nombre" class="filter-select"><option value="">Todos los splits</option><option value="Spring" <?= $splitNombre==='Spring'?'selected':'' ?>>Spring</option><option value="Summer" <?= $splitNombre==='Summer'?'selected':'' ?>>Summer</option><option value="Winter" <?= $splitNombre==='Winter'?'selected':'' ?>>LEC Versus</option></select>
        <select name="finalizado"   class="filter-select"><option value="">Todos</option><option value="1" <?= $finalizado===1?'selected':'' ?>>Finalizados</option><option value="0" <?= $finalizado===0?'selected':'' ?>>Pendientes</option></select>
        <button type="submit" class="btn-secundario" style="padding:.38rem .8rem;font-size:.72rem">Filtrar</button>
        <a href="panel.php?sec=partidos" style="font-family:var(--font-h);font-size:.68rem;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,.3);text-decoration:none">Limpiar</a>
    </form>
    <p style="font-family:var(--font-h);font-size:.6rem;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,.18);margin-bottom:.8rem"><?= count($partidos) ?> partidos</p>
    <?php if (empty($partidos)): ?>
        <div class="empty-msg">No hay partidos para los filtros seleccionados</div>
    <?php else: ?>
        <?php foreach ($partidos as $p):
            $fin = $p['finalizado'];
            $e1w = $fin && $p['mapas_eq1'] > $p['mapas_eq2'];
        ?>
        <div class="match-row <?= !$fin?'pending':'' ?>">
            <div>
                <div class="match-meta"><?= date('d/m/Y', strtotime($p['fecha_hora'])) ?> · <?= htmlspecialchars($p['split']==='Winter'?'LEC Versus':$p['split']) ?> <?= $p['año'] ?></div>
                <div class="match-team <?= $fin&&!$e1w?'dim':'' ?>"><?= htmlspecialchars($p['equipo_1']) ?></div>
            </div>
            <div class="match-score" style="color:<?= !$fin?'rgba(255,255,255,.2)':'#fff' ?>">
                <?php if ($fin): ?>
                    <span style="color:<?= $e1w?'var(--win)':'inherit' ?>"><?= $p['mapas_eq1'] ?></span>
                    <span style="color:rgba(255,255,255,.2)"> — </span>
                    <span style="color:<?= !$e1w?'var(--win)':'inherit' ?>"><?= $p['mapas_eq2'] ?></span>
                <?php else: ?><span style="font-size:.7rem;letter-spacing:2px;text-transform:uppercase">—</span>
                <?php endif; ?>
            </div>
            <div>
                <div class="match-meta" style="text-align:right"><?= htmlspecialchars($p['tipo_serie']) ?></div>
                <div class="match-team right <?= $fin&&$e1w?'dim':'' ?>"><?= htmlspecialchars($p['equipo_2']) ?></div>
            </div>
            <div class="match-actions">
                <a href="editar_resultado.php?id=<?= $p['id_partido'] ?>" class="btn-secundario" style="padding:.3rem .65rem;font-size:.7rem">✏</a>
                <a href="eliminar_partido.php?id=<?= $p['id_partido'] ?>" class="btn-peligro"    style="padding:.3rem .55rem;font-size:.7rem">✕</a>
            </div>
        </div>
        <?php endforeach; ?>
    <?php endif; ?>

    <?php elseif ($seccion === 'equipos'): ?>
    
    <div class="top-bar">
        <div class="page-title">Equipos</div>
        <a href="nuevo_equipo.php" class="btn-primario">+ Equipo</a>
    </div>
    <?php if (empty($equipos)): ?>
        <div class="empty-msg">No hay equipos</div>
    <?php else: ?>
        <?php foreach ($equipos as $eq): ?>
        <div class="match-row">
            <div><div class="match-meta">ID <?= $eq['id_equipo'] ?></div><div class="match-team"><?= htmlspecialchars($eq['nombre']) ?></div></div>
            <div style="font-family:var(--font-h);font-size:.7rem;color:rgba(255,255,255,.25);letter-spacing:1px"><?= htmlspecialchars($eq['pais']??'—') ?></div>
            <div style="font-family:var(--font-h);font-size:.7rem;color:rgba(255,255,255,.3);text-align:right"><?= $eq['titulares'] ?> titulares</div>
            <div></div>
        </div>
        <?php endforeach; ?>
    <?php endif; ?>

    <?php else: ?>
        <script>window.location='panel.php?sec=pendientes'</script>
    <?php endif; ?>

</div>
</div>
</body>
</html>