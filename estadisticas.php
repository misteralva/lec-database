<?php
require_once __DIR__ . '/clases/ConexionDB.php';
require_once __DIR__ . '/clases/LecDB.php';
require_once __DIR__ . '/ImagenHelper.php';

$splits = LecDB::listarSplits();
$idSplitSel = isset($_GET['id_split']) ? (int)$_GET['id_split'] : null;

$pdo = ConexionDB::getInstancia('readonly')->getConexion();

function callSP(PDO $pdo, string $sql, array $params = []): array {
    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $data = $stmt->fetchAll();
        while ($stmt->nextRowset()) {}
        return $data;
    } catch (Exception $e) {
        return [];
    }
}

$split = $idSplitSel ?: null;


$topKDA         = callSP($pdo, "CALL sp_top_kda(?, 15)",          [$split]);
$topCS          = callSP($pdo, "CALL sp_top_cs(?, 10)",           [$split]);
$winRates       = callSP($pdo, "CALL sp_win_rate_equipos(?)",      [$split]);
$statsPorRol    = callSP($pdo, "CALL sp_stats_por_rol(?)",        [$split]);
$winRateJug     = callSP($pdo, "CALL sp_win_rate_jugadores(?, 10)", [$split]);
$resumen        = callSP($pdo, "CALL sp_resumen_torneo(?)",        [$split]);
$resumenData    = $resumen[0] ?? [];



$kdaLabels    = array_column($topKDA, 'nickname');
$kdaData      = array_column($topKDA, 'kda');
$kdaEquipos   = array_column($topKDA, 'equipo');

$wrLabels = array_column($winRates, 'nombre');
$wrData   = array_map(fn($r) =>
    $r['partidos'] > 0 ? round($r['victorias'] * 100 / $r['partidos'], 1) : 0,
    $winRates
);
$wrPartidos = array_column($winRates, 'partidos');

$coloresEquipo = [
    'G2 Esports'   => '#1428a0',
    'Fnatic'       => '#ff5900',
    'Team Vitality'=> '#c9be00',
    'Karmine Corp' => '#00d4ff',
    'Natus Vincere'=> '#f5a623',
    'GIANTX'       => '#00b4d8',
    'Movistar KOI' => '#00c4cc',
    'SK Gaming'    => '#cc0000',
    'Shifters'     => '#00cc66',
    'Team Heretics'=> '#8b00ff',
];
$kdaColors = array_map(fn($eq) => $coloresEquipo[$eq] ?? '#1EDD88', $kdaEquipos);

$roles = array_column($statsPorRol, 'rol');
$rolKDA = array_column($statsPorRol, 'kda');
$rolKills = array_column($statsPorRol, 'kills_prom');
$rolDeaths = array_column($statsPorRol, 'deaths_prom');
$rolAssists = array_column($statsPorRol, 'assists_prom');


$allJugadores = callSP($pdo, "CALL sp_get_jugadores_comparador()");


$paginaActiva = 'estadisticas';
$tituloPagina = 'Estadísticas';
require_once __DIR__ . '/includes/header.php';
?>
<main>

<div class="seccion stats-hero">
    <div class="seccion-cabecera">
        <h2>Estadísticas</h2>
        <form method="GET" action="estadisticas.php" class="filtro-form">
            <label>Split:</label>
            <select name="id_split" onchange="this.form.submit()">
                <option value="">Todos los splits</option>
                <?php foreach ($splits as $s): ?>
                    <option value="<?= $s['id_split'] ?>"
                        <?= $idSplitSel == $s['id_split'] ? 'selected' : '' ?>>
                        <?= htmlspecialchars($s['nombre'] === 'Winter' ? 'LEC Versus' : $s['nombre']) ?>
                        <?= htmlspecialchars($s['año']) ?>
                    </option>
                <?php endforeach; ?>
            </select>
        </form>
    </div>

   
    <div class="stats-cards">
        <div class="stat-card">
            <div class="stat-card-val"><?= count($topKDA) ?></div>
            <div class="stat-card-label">Jugadores con datos</div>
        </div>
        <div class="stat-card">
            <?php $topPlayer = $topKDA[0] ?? null; ?>
            <div class="stat-card-val"><?= $topPlayer ? htmlspecialchars($topPlayer['nickname']) : '—' ?></div>
            <div class="stat-card-label">Mayor KDA</div>
            <div class="stat-card-sub"><?= $topPlayer ? htmlspecialchars($topPlayer['kda']) : '' ?></div>
        </div>
        <div class="stat-card">
            <?php $topCSplayer = $topCS[0] ?? null; ?>
            <div class="stat-card-val"><?= $topCSplayer ? htmlspecialchars($topCSplayer['nickname']) : '—' ?></div>
            <div class="stat-card-label">Mayor CS promedio</div>
            <div class="stat-card-sub"><?= $topCSplayer ? htmlspecialchars($topCSplayer['cs_promedio']) . ' cs/m' : '' ?></div>
        </div>
        <div class="stat-card">
            <?php $topWR = $winRates[0] ?? null; ?>
            <div class="stat-card-val"><?= $topWR ? htmlspecialchars($topWR['nombre']) : '—' ?></div>
            <div class="stat-card-label">Mayor win rate</div>
            <div class="stat-card-sub"><?= $topWR ? round($topWR['victorias'] * 100 / max($topWR['partidos'],1),0) . '%' : '' ?></div>
        </div>
    </div>
</div>


<div class="seccion">
    <div class="charts-grid-2">

 
        <div class="chart-box">
            <div class="chart-box-header">
                <h3>Top KDA — Jugadores</h3>
                <span class="chart-badge">Mín. 2 mapas</span>
            </div>
            <div class="chart-wrap" style="height:340px">
                <canvas id="chartKDA"></canvas>
            </div>
        </div>

    
        <div class="chart-box">
            <div class="chart-box-header">
                <h3>Win Rate por equipo</h3>
                <span class="chart-badge">% victorias</span>
            </div>
            <div class="chart-wrap" style="height:340px">
                <canvas id="chartWR"></canvas>
            </div>
        </div>

    </div>
</div>


<div class="seccion">
    <div class="seccion-cabecera"><h2>Media por rol</h2></div>
    <div class="charts-grid-2">
        <div class="chart-box">
            <div class="chart-box-header"><h3>KDA promedio por rol</h3></div>
            <div class="chart-wrap" style="height:280px">
                <canvas id="chartRolKDA"></canvas>
            </div>
        </div>
        <div class="chart-box">
            <div class="chart-box-header"><h3>K/D/A promedio por rol</h3></div>
            <div class="chart-wrap" style="height:280px">
                <canvas id="chartRolKDA2"></canvas>
            </div>
        </div>
    </div>
</div>


<div class="seccion">
    <div class="seccion-cabecera">
        <h2>Comparador de jugadores</h2>
    </div>
    <div class="comparador">
        <div class="comparador-selects">
            <div class="campo">
                <label>Jugador 1</label>
                <select id="jugador1">
                    <option value="">Selecciona un jugador</option>
                    <?php foreach ($allJugadores as $j): ?>
                        <option value="<?= $j['id_jugador'] ?>" data-rol="<?= htmlspecialchars($j['rol_principal']) ?>">
                            <?= htmlspecialchars($j['nickname']) ?> (<?= htmlspecialchars($j['rol_principal']) ?>)
                        </option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="comparador-vs">VS</div>
            <div class="campo">
                <label>Jugador 2</label>
                <select id="jugador2">
                    <option value="">Selecciona un jugador</option>
                    <?php foreach ($allJugadores as $j): ?>
                        <option value="<?= $j['id_jugador'] ?>" data-rol="<?= htmlspecialchars($j['rol_principal']) ?>">
                            <?= htmlspecialchars($j['nickname']) ?> (<?= htmlspecialchars($j['rol_principal']) ?>)
                        </option>
                    <?php endforeach; ?>
                </select>
            </div>
            <button class="btn-primario" onclick="compararJugadores()">Comparar</button>
        </div>
        <div class="chart-box" style="margin-top:1.5rem">
            <div class="chart-wrap" style="height:360px">
                <canvas id="chartComparador"></canvas>
            </div>
            <p id="comparador-vacio" style="text-align:center;padding:3rem;color:var(--text3);font-family:var(--font-h);letter-spacing:2px;text-transform:uppercase;font-size:.75rem">
                Selecciona dos jugadores para comparar
            </p>
        </div>
    </div>
</div>


<div class="seccion">
    <div class="seccion-cabecera"><h2>Top CS promedio — Carries</h2></div>
    <table class="tabla-clasificacion">
        <thead>
            <tr>
                <th>#</th>
                <th>Jugador</th>
                <th>Equipo</th>
                <th>Rol</th>
                <th>CS prom.</th>
                <th>CS/min</th>
                <th>Mapas</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($topCS as $i => $j): ?>
            <tr>
                <td class="pos-num"><?= $i+1 ?></td>
                <td><strong><?= htmlspecialchars($j['nickname']) ?></strong></td>
                <td><?= htmlspecialchars($j['equipo']) ?></td>
                <td><?= ImagenHelper::iconoRol($j['rol_principal']) ?></td>
                <td style="font-family:var(--font-h);font-weight:700;color:var(--win)"><?= $j['cs_promedio'] ?></td>
                <td style="color:var(--text2)"><?= $j['cs_min'] ?></td>
                <td style="color:var(--text3)"><?= $j['mapas'] ?></td>
            </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
</div>



    <?php if (!empty($resumenData)): ?>
    <div class="seccion seccion-stats">
        <h2 class="stats-titulo">📊 Resumen del split</h2>
        <div class="stats-resumen-grid">
            <div class="resumen-card"><div class="resumen-num"><?= $resumenData['total_partidos'] ?? '—' ?></div><div class="resumen-lbl">Partidos</div></div>
            <div class="resumen-card"><div class="resumen-num"><?= $resumenData['total_mapas'] ?? '—' ?></div><div class="resumen-lbl">Mapas jugados</div></div>
            <div class="resumen-card"><div class="resumen-num"><?= ($resumenData['duracion_media_min'] ?? '—') ?> min</div><div class="resumen-lbl">Duración media</div></div>
            <div class="resumen-card"><div class="resumen-num"><?= $resumenData['kills_media_mapa'] ?? '—' ?></div><div class="resumen-lbl">Kills / mapa</div></div>
        </div>
    </div>
    <?php endif; ?>

  
    <?php if (!empty($winRateJug)): ?>
    <div class="seccion seccion-stats">
        <h2 class="stats-titulo">🏆 Mejor win rate (jugadores)</h2>
        <table class="tabla-stats">
            <thead><tr><th>#</th><th>Jugador</th><th>Equipo</th><th>Rol</th><th class="c">Partidos</th><th class="c">Victorias</th><th class="c">Win Rate</th></tr></thead>
            <tbody>
            <?php foreach ($winRateJug as $i => $j): ?>
            <tr>
                <td class="rank"><?= $i+1 ?></td>
                <td><strong><?= htmlspecialchars($j['nickname']) ?></strong></td>
                <td style="color:rgba(255,255,255,.4)"><?= htmlspecialchars($j['equipo']) ?></td>
                <td><?= ImagenHelper::iconoRol($j['rol_principal']) ?></td>
                <td class="c"><?= $j['partidos'] ?></td>
                <td class="c"><?= $j['victorias'] ?></td>
                <td class="c"><span style="font-family:var(--font-h);font-weight:800;color:<?= $j['win_rate']>=60?'var(--win)':($j['win_rate']>=50?'#fff':'#ef5350') ?>"><?= $j['win_rate'] ?>%</span></td>
            </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php endif; ?>

</main>

<?php require_once __DIR__ . '/includes/footer.php'; ?>


<script>
const PHP = {
    kdaLabels:  <?= json_encode($kdaLabels) ?>,
    kdaData:    <?= json_encode(array_map('floatval', $kdaData)) ?>,
    kdaColors:  <?= json_encode($kdaColors) ?>,
    kdaEquipos: <?= json_encode($kdaEquipos) ?>,
    wrLabels:   <?= json_encode($wrLabels) ?>,
    wrData:     <?= json_encode(array_map('floatval', $wrData)) ?>,
    wrPartidos: <?= json_encode(array_map('intval',   $wrPartidos)) ?>,
    roles:      <?= json_encode($roles) ?>,
    rolKDA:     <?= json_encode(array_map('floatval', $rolKDA)) ?>,
    rolKills:   <?= json_encode(array_map('floatval', $rolKills)) ?>,
    rolDeaths:  <?= json_encode(array_map('floatval', $rolDeaths)) ?>,
    rolAssists: <?= json_encode(array_map('floatval', $rolAssists)) ?>,
    splitId:    <?= json_encode($idSplitSel) ?>,
};
</script>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
<script src="assets/js/estadisticas.js"></script>