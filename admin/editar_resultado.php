<?php
session_start();
require_once __DIR__ . '/auth.php';
auth('editor');

require_once __DIR__ . '/../clases/ConexionDB.php';
require_once __DIR__ . '/../clases/LecDB.php';
require_once __DIR__ . '/../includes/csrf.php';
require_once __DIR__ . '/helpers.php';

$idPartido = isset($_GET['id']) ? (int)$_GET['id'] : 0;
if (!$idPartido) { header('Location: panel.php'); exit; }

$pdo = ConexionDB::getInstancia('backend')->getConexion();
$resultP = callSP($pdo, "CALL sp_get_partido(?)", [$idPartido]);

$esTemporadaPasada = false;
if (!empty($partido)) {
    $añoPartido = (int)($partido[0]['año_split'] ?? (int)date('Y'));
    $esTemporadaPasada = $añoPartido < (int)date('Y');
}
if ($esTemporadaPasada && !esSuperAdmin()) {
    $_SESSION['mensaje'] = '⚠ Este partido es de una temporada pasada. Solo el administrador puede modificarlo.';
    $_SESSION['tipo']    = 'error';
    header('Location: panel.php'); exit;
}
$partido = $resultP[0] ?? null;
if (!$partido) { header('Location: panel.php'); exit; }
function getJugadores(PDO $pdo, int $hist): array {
    return callSP($pdo, "CALL sp_get_jugadores_historial(?)", [$hist]);
}
$jugEq1 = getJugadores($pdo, $partido['hist1']);
$jugEq2 = getJugadores($pdo, $partido['hist2']);
$tipo   = $partido['tipo_serie'];
$maxWin = $tipo==='Bo1' ? 1 : ($tipo==='Bo3' ? 2 : 3);
$maxMaps= $tipo==='Bo1' ? 1 : ($tipo==='Bo3' ? 3 : 5);
$statsExist = [];
$mapasExist = [];
foreach (callSP($pdo, "CALL sp_get_mapas_partido(?)", [$idPartido]) as $m) {
    $mapasExist[$m['numero_mapa']] = $m;
}

foreach (callSP($pdo, "CALL sp_get_stats_partido(?)", [$idPartido]) as $s) {
    $statsExist[$s['numero_mapa']][$s['id_jugador']] = $s;
}

$error = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST' && csrf_verify()) {

    $me1 = (int)$_POST['mapas_eq1'];
    $me2 = (int)$_POST['mapas_eq2'];
    $valido = true;
    if ($me1 < 0 || $me2 < 0) {
        $error = 'El marcador no puede ser negativo.'; $valido = false;
    } elseif ($me1 > $maxWin || $me2 > $maxWin) {
        $error = "En $tipo el máximo de mapas ganados es $maxWin (no puede quedar {$me1}-{$me2})."; $valido = false;
    } elseif ($me1 === $me2 && $tipo !== 'Bo1') {
        $error = 'El marcador no puede estar empatado al finalizar.'; $valido = false;
    } elseif ($me1 < $maxWin && $me2 < $maxWin) {
        $error = "Para $tipo uno de los equipos debe llegar a $maxWin. Marcador {$me1}-{$me2} es incompleto."; $valido = false;
    }

    if ($valido) {
        $totalMapas = $me1 + $me2;
        $fin = ($me1===$maxWin || $me2===$maxWin) ? 1 : 0;
        if (esSuperAdmin()) {
        $pdo->exec('SET @admin_bypass = 1');
    }
        execSP($pdo, "CALL sp_guardar_marcador(?,?,?,?,@msg_marc)", [$idPartido, $me1, $me2, $fin]);
        $mapsData = $_POST['mapa'] ?? [];
        foreach ($mapsData as $nm => $mData) {
            $nm  = (int)$nm;
            if ($nm < 1 || $nm > $maxMaps) continue;
            $dur = (int)($mData['duracion'] ?? 30);
            $gan = ($mData['ganador'] ?? 'eq1') === 'eq1' ? $partido['hist1'] : $partido['hist2'];
            execSP($pdo, "CALL sp_guardar_mapa(?,?,?,?,@msg_mapa)", [$idPartido, $nm, $dur, $gan]);
            $statsJugadores = $mData['stats'] ?? [];
            foreach ($statsJugadores as $jid => $sData) {
                $jid = (int)$jid;
                $ch  = trim($sData['campeon'] ?? '');
                if (empty($ch)) continue;
                $k  = (int)($sData['kills']   ?? 0);
                $d  = (int)($sData['deaths']  ?? 0);
                $a  = (int)($sData['assists'] ?? 0);
                $cs = (int)($sData['cs']      ?? 0);
                $or = (int)($sData['oro']     ?? 0);
                execSP($pdo, "CALL sp_registrar_estadisticas(?,?,?,?,?,?,?,?,?,@msg)", [$idPartido, $nm, $jid, $k, $d, $a, $cs, $or, $ch]);
            }
        }
        $pdo->exec('SET @admin_bypass = NULL');
        $_SESSION['mensaje'] = '✅ Partido guardado correctamente.';
        $_SESSION['tipo']    = 'exito';
        header('Location: panel.php');
        exit;
    }
}

?>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Editar partido — LEC Admin</title>
<link rel="stylesheet" href="../assets/css/estilo.css">
<style>
.er-wrap { max-width:1200px; margin:2rem auto; padding:0 1.5rem; }
.er-score-box { background:#111; border:1px solid rgba(255,255,255,.08); border-radius:2px; padding:1.5rem; margin-bottom:1.5rem; display:flex; align-items:center; gap:2rem; flex-wrap:wrap; }
.score-eq { font-family:var(--font-h); font-size:.75rem; font-weight:700; letter-spacing:2px; text-transform:uppercase; color:rgba(255,255,255,.3); text-align:center; margin-bottom:.4rem; }
.score-inp-wrap { display:flex; flex-direction:column; align-items:center; }
.score-inp { width:80px; text-align:center; font-family:var(--font-h); font-size:2.5rem; font-weight:900; background:#1a1a1a; border:1px solid rgba(255,255,255,.12); color:#fff; padding:.4rem; border-radius:2px; }
.score-dash { font-family:var(--font-h); font-size:2rem; color:rgba(255,255,255,.15); font-weight:300; align-self:flex-end; padding-bottom:.6rem; }
.er-hint { font-family:var(--font-h); font-size:.65rem; font-weight:700; letter-spacing:1.5px; text-transform:uppercase; color:rgba(255,255,255,.2); margin-left:auto; }
.mapa-section { background:#111; border:1px solid rgba(255,255,255,.07); border-radius:2px; margin-bottom:1rem; overflow:hidden; }
.mapa-header { background:#000; padding:.7rem 1.2rem; display:flex; align-items:center; gap:1rem; border-bottom:1px solid rgba(255,255,255,.06); }
.mapa-num { font-family:var(--font-h); font-size:.85rem; font-weight:900; letter-spacing:2px; text-transform:uppercase; color:#fff; }
.mapa-meta { display:flex; align-items:center; gap:.8rem; margin-left:auto; flex-wrap:wrap; }
.mapa-meta label { font-family:var(--font-h); font-size:.6rem; font-weight:700; letter-spacing:2px; text-transform:uppercase; color:rgba(255,255,255,.2); }
.mi { background:#1a1a1a; border:1px solid rgba(255,255,255,.1); color:#fff; padding:.35rem .6rem; border-radius:2px; font-family:var(--font-b); font-size:.85rem; }
.mi:focus { outline:none; border-color:var(--cyan); }
.stats-table { width:100%; border-collapse:collapse; }
.stats-table th { font-family:var(--font-h); font-size:.58rem; letter-spacing:2px; text-transform:uppercase; color:rgba(255,255,255,.18); padding:.45rem .8rem; border-bottom:1px solid rgba(255,255,255,.05); text-align:left; }
.stats-table th.c { text-align:center; }
.stats-table td { padding:.4rem .8rem; border-bottom:1px solid rgba(255,255,255,.04); vertical-align:middle; }
.stats-table td.c { text-align:center; }
.si { width:100%; background:#1a1a1a; border:1px solid rgba(255,255,255,.1); color:#fff; padding:.3rem .5rem; border-radius:2px; font-size:.82rem; font-family:var(--font-b); text-align:center; }
.si.champ { text-align:left; min-width:130px; }
.si:focus { outline:none; border-color:var(--cyan); }
.team-row td { background:#050505; padding:.3rem .8rem; font-family:var(--font-h); font-size:.6rem; font-weight:800; letter-spacing:2px; text-transform:uppercase; color:var(--cyan); }
.save-bar { position:sticky; bottom:0; background:rgba(0,0,0,.95); border-top:1px solid rgba(255,255,255,.08); padding:1rem 1.5rem; display:flex; align-items:center; gap:1rem; backdrop-filter:blur(10px); z-index:100; }
.error-msg { background:rgba(229,57,53,.1); border:1px solid rgba(229,57,53,.25); color:#ef5350; padding:.7rem 1rem; border-radius:2px; font-family:var(--font-h); font-size:.8rem; font-weight:600; margin-bottom:1rem; }
</style>
</head>
<body style="background:#000">


<header style="background:#080808;border-bottom:1px solid rgba(255,255,255,.08);padding:0 1.5rem;position:sticky;top:0;z-index:200">
    <div style="display:flex;align-items:center;height:52px;gap:1.2rem">
        <a href="panel.php" style="font-family:'Barlow Condensed',sans-serif;font-size:1rem;font-weight:900;letter-spacing:3px;text-transform:uppercase;color:#fff;text-decoration:none"><span style="color:var(--cyan)">⚡</span> LEC Admin</a>
        <a href="panel.php?sec=pendientes" style="font-family:'Barlow Condensed',sans-serif;font-size:.7rem;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,.4);text-decoration:none">← Volver</a>
        <div style="margin-left:auto;font-family:'Barlow Condensed',sans-serif;font-size:.8rem;color:rgba(255,255,255,.4)">
            <?= htmlspecialchars($partido['equipo_1']) ?> vs <?= htmlspecialchars($partido['equipo_2']) ?>
            — <span style="color:rgba(255,255,255,.2)"><?= htmlspecialchars($tipo) ?></span>
        </div>
    </div>
</header>

<?php if ($error): ?>
<div style="background:rgba(239,83,80,.1);border:1px solid rgba(239,83,80,.3);color:#ef5350;
            padding:.8rem 1.2rem;border-radius:2px;margin-bottom:1.2rem;
            font-family:var(--font-h);font-size:.82rem;font-weight:700">
    ⚠ <?= htmlspecialchars($error) ?>
</div>
<?php endif; ?>
<form method="POST" id="mainForm">
<?= csrf_field() ?>

<div class="er-wrap">

    <?php if ($error): ?>
        <div class="error-msg">⚠ <?= htmlspecialchars($error) ?></div>
    <?php endif; ?>

    
    <div class="er-score-box">
        <div class="score-inp-wrap">
            <div class="score-eq"><?= htmlspecialchars($partido['equipo_1']) ?></div>
            <input type="number" name="mapas_eq1" id="me1" class="score-inp"
                   value="<?= $partido['mapas_eq1'] ?>" min="0" max="<?= $maxWin ?>"
                   oninput="updateMaps()">
        </div>
        <span class="score-dash">—</span>
        <div class="score-inp-wrap">
            <div class="score-eq"><?= htmlspecialchars($partido['equipo_2']) ?></div>
            <input type="number" name="mapas_eq2" id="me2" class="score-inp"
                   value="<?= $partido['mapas_eq2'] ?>" min="0" max="<?= $maxWin ?>"
                   oninput="updateMaps()">
        </div>
        <div class="er-hint" id="scoreHint">
            <?= $tipo ?> · máximo <?= $maxWin ?> mapas ganados
        </div>
    </div>

    
    <?php for ($nm = 1; $nm <= $maxMaps; $nm++):
        $mExist  = $mapasExist[$nm] ?? null;
        $ganEq1  = $mExist ? ($mExist['ganador'] === $partido['hist1']) : true;
        $durExist= $mExist ? $mExist['duracion_minutos'] : 30;
    ?>
    <div class="mapa-section" id="mapa_<?= $nm ?>" style="display:none">
        <div class="mapa-header">
            <span class="mapa-num">Mapa <?= $nm ?></span>
            <div class="mapa-meta">
                <label>Ganador</label>
                <select name="mapa[<?= $nm ?>][ganador]" class="mi">
                    <option value="eq1" <?= $ganEq1?'selected':'' ?>><?= htmlspecialchars($partido['equipo_1']) ?></option>
                    <option value="eq2" <?= !$ganEq1?'selected':'' ?>><?= htmlspecialchars($partido['equipo_2']) ?></option>
                </select>
                <label>Duración (min)</label>
                <input type="number" name="mapa[<?= $nm ?>][duracion]" class="mi" value="<?= $durExist ?>" min="15" max="70" style="width:70px">
            </div>
        </div>
        <table class="stats-table">
            <thead>
                <tr>
                    <th>Jugador</th>
                    <th>Campeón</th>
                    <th class="c">K</th>
                    <th class="c">D</th>
                    <th class="c">A</th>
                    <th class="c">CS</th>
                    <th class="c">Oro</th>
                </tr>
            </thead>
            <tbody>
                <tr class="team-row"><td colspan="7"><?= htmlspecialchars($partido['equipo_1']) ?></td></tr>
                <?php foreach ($jugEq1 as $j):
                    $s = $statsExist[$nm][$j['id_jugador']] ?? null;
                    $jid = $j['id_jugador'];
                ?>
                <tr>
                    <td>
                        <strong><?= htmlspecialchars($j['nickname']) ?></strong>
                        <span style="color:rgba(255,255,255,.2);font-size:.72rem;margin-left:.4rem"><?= $j['rol'] ?></span>
                    </td>
                    <td><input type="text" name="mapa[<?= $nm ?>][stats][<?= $jid ?>][campeon]" class="si champ" value="<?= htmlspecialchars($s['campeon']??'') ?>" placeholder="Campeón" list="champs" autocomplete="off"></td>
                    <td class="c"><input type="number" name="mapa[<?= $nm ?>][stats][<?= $jid ?>][kills]"   class="si" value="<?= $s['kills']??0 ?>"   min="0" max="50" style="width:55px"></td>
                    <td class="c"><input type="number" name="mapa[<?= $nm ?>][stats][<?= $jid ?>][deaths]"  class="si" value="<?= $s['deaths']??0 ?>"  min="0" max="50" style="width:55px"></td>
                    <td class="c"><input type="number" name="mapa[<?= $nm ?>][stats][<?= $jid ?>][assists]" class="si" value="<?= $s['assists']??0 ?>" min="0" max="50" style="width:55px"></td>
                    <td class="c"><input type="number" name="mapa[<?= $nm ?>][stats][<?= $jid ?>][cs]"      class="si" value="<?= $s['cs']??0 ?>"      min="0" max="600" style="width:65px"></td>
                    <td class="c"><input type="number" name="mapa[<?= $nm ?>][stats][<?= $jid ?>][oro]"     class="si" value="<?= $s['oro']??0 ?>"     min="0" style="width:80px"></td>
                </tr>
                <?php endforeach; ?>
                <tr class="team-row"><td colspan="7"><?= htmlspecialchars($partido['equipo_2']) ?></td></tr>
                <?php foreach ($jugEq2 as $j):
                    $s = $statsExist[$nm][$j['id_jugador']] ?? null;
                    $jid = $j['id_jugador'];
                ?>
                <tr>
                    <td>
                        <strong><?= htmlspecialchars($j['nickname']) ?></strong>
                        <span style="color:rgba(255,255,255,.2);font-size:.72rem;margin-left:.4rem"><?= $j['rol'] ?></span>
                    </td>
                    <td><input type="text" name="mapa[<?= $nm ?>][stats][<?= $jid ?>][campeon]" class="si champ" value="<?= htmlspecialchars($s['campeon']??'') ?>" placeholder="Campeón" list="champs" autocomplete="off"></td>
                    <td class="c"><input type="number" name="mapa[<?= $nm ?>][stats][<?= $jid ?>][kills]"   class="si" value="<?= $s['kills']??0 ?>"   min="0" max="50" style="width:55px"></td>
                    <td class="c"><input type="number" name="mapa[<?= $nm ?>][stats][<?= $jid ?>][deaths]"  class="si" value="<?= $s['deaths']??0 ?>"  min="0" max="50" style="width:55px"></td>
                    <td class="c"><input type="number" name="mapa[<?= $nm ?>][stats][<?= $jid ?>][assists]" class="si" value="<?= $s['assists']??0 ?>" min="0" max="50" style="width:55px"></td>
                    <td class="c"><input type="number" name="mapa[<?= $nm ?>][stats][<?= $jid ?>][cs]"      class="si" value="<?= $s['cs']??0 ?>"      min="0" max="600" style="width:65px"></td>
                    <td class="c"><input type="number" name="mapa[<?= $nm ?>][stats][<?= $jid ?>][oro]"     class="si" value="<?= $s['oro']??0 ?>"     min="0" style="width:80px"></td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php endfor; ?>

    
    <div style="height:80px"></div>

</div>


<div class="save-bar">
    <a href="panel.php?sec=pendientes" class="btn-secundario">← Cancelar</a>
    <div id="scoreError" style="color:#ef5350;font-family:var(--font-h);font-size:.75rem;font-weight:700;letter-spacing:1px;display:none"></div>
    <div style="margin-left:auto;font-family:var(--font-h);font-size:.7rem;color:rgba(255,255,255,.25);letter-spacing:1px" id="mapsInfo"></div>
    <button type="submit" class="btn-primario" style="padding:.7rem 2rem;font-size:.85rem" id="saveBtn">
        💾 Guardar partido
    </button>
</div>

</form>

<datalist id="champs">
    <?php foreach (['Aatrox','Ahri','Akali','Alistar','Aphelios','Ashe','Azir','Belveth','Blitzcrank','Braum','Caitlyn','Camille','Cassiopeia','Corki','Darius','Elise','Ezreal','Fiora','Galio','Garen','Gnar','Gragas','Graves','Hecarim','Jarvan IV','Jax','Jayce','Jhin','Jinx','Kaisa','Karma','Kindred','Lee Sin','Lissandra','Lucian','Lulu','Malphite','Milio','Miss Fortune','Nautilus','Nami','Nidalee','Ornn','Orianna','Rakan','Renata Glasc','Renekton','Sejuani','Sivir','Soraka','Syndra','Taliyah','Thresh','Tristana','Varus','Viego','Viktor','Wukong','Xayah','Zeri','Zoe','Zyra'] as $ch): ?>
        <option value="<?= $ch ?>">
    <?php endforeach; ?>
</datalist>

<script>
const MAXWIN  = <?= $maxWin ?>;
const TIPO    = '<?= $tipo ?>';
const MAXMAPS = <?= $maxMaps ?>;

function updateMaps() {
    const me1 = parseInt(document.getElementById('me1').value) || 0;
    const me2 = parseInt(document.getElementById('me2').value) || 0;
    const errEl = document.getElementById('scoreError');
    const mapsInfo = document.getElementById('mapsInfo');
    let err = '';
    if (me1 > MAXWIN || me2 > MAXWIN) {
        err = `En ${TIPO} el máximo es ${MAXWIN} (no puede ser ${me1}-${me2})`;
    } else if (me1 === me2 && (me1 > 0 || me2 > 0)) {
        err = 'El marcador no puede quedar empatado';
    }

    errEl.textContent = err;
    errEl.style.display = err ? 'block' : 'none';
    const totalMaps = me1 + me2;
    for (let i = 1; i <= MAXMAPS; i++) {
        const el = document.getElementById('mapa_' + i);
        if (el) el.style.display = (i <= totalMaps && !err) ? 'block' : 'none';
    }

    mapsInfo.textContent = totalMaps > 0 && !err
        ? `${totalMaps} mapa${totalMaps>1?'s':''} a registrar`
        : '';
}
updateMaps();
</script>
</body>
</html>