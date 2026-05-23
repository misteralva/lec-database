<?php
require_once __DIR__ . '/clases/ConexionDB.php';
require_once __DIR__ . '/clases/LecDB.php';
require_once __DIR__ . '/ImagenHelper.php';

$idPartido = isset($_GET['id']) ? (int)$_GET['id'] : 0;
if (!$idPartido) { header('Location: resultados.php'); exit; }

$datos   = LecDB::detallePartido($idPartido);
$partido = $datos['partido'];
$mapas   = $datos['mapas'];
$stats   = $datos['stats'];

if (!$partido) { header('Location: resultados.php'); exit; }

$statsPorMapa = [];
foreach ($stats as $s) {
    $statsPorMapa[$s['numero_mapa']][] = $s;
}

$eq1Gana  = $partido['mapas_eq1'] > $partido['mapas_eq2'];
$logoEq1  = ImagenHelper::logoEquipo($partido['equipo_1']);
$logoEq2  = ImagenHelper::logoEquipo($partido['equipo_2']);
$splitLabel = $partido['split'] === 'Winter' ? 'LEC Versus' : $partido['split'];

$paginaActiva = 'resultados';
$tituloPagina = $partido['equipo_1'] . ' vs ' . $partido['equipo_2'];
require_once __DIR__ . '/includes/header.php';
?>
<main>

<div class="partido-detalle-hero">
    <div class="partido-detalle-inner">
        <div class="partido-detalle-eq">
            <img class="partido-detalle-logo"
                 src="<?= htmlspecialchars($logoEq1) ?>"
                 alt="<?= htmlspecialchars($partido['equipo_1']) ?>"
                 onerror="this.style.opacity='0'">
            <span class="partido-detalle-nombre <?= $eq1Gana ? 'ganador' : 'perdedor' ?>">
                <?= htmlspecialchars($partido['equipo_1']) ?>
            </span>
        </div>

        <div class="partido-detalle-centro">
            <div class="partido-detalle-score">
                <span class="<?= $eq1Gana ? 'win-n' : '' ?>"><?= htmlspecialchars($partido['mapas_eq1']) ?></span>
                <span class="sep">—</span>
                <span class="<?= !$eq1Gana ? 'win-n' : '' ?>"><?= htmlspecialchars($partido['mapas_eq2']) ?></span>
            </div>
            <div class="partido-detalle-meta">
                <?= htmlspecialchars($partido['tipo_serie']) ?> &middot;
                <?= htmlspecialchars($partido['fase']) ?> &middot;
                <?= htmlspecialchars($splitLabel) ?> <?= htmlspecialchars($partido['año']) ?>
            </div>
            <div class="partido-detalle-fecha">
                <?= htmlspecialchars(date('d/m/Y H:i', strtotime($partido['fecha_hora']))) ?>
            </div>
            <?php if (!$partido['finalizado']): ?>
                <span class="badge badge-pendiente" style="margin-top:.4rem">Pendiente</span>
            <?php endif; ?>
        </div>

        <div class="partido-detalle-eq">
            <img class="partido-detalle-logo"
                 src="<?= htmlspecialchars($logoEq2) ?>"
                 alt="<?= htmlspecialchars($partido['equipo_2']) ?>"
                 onerror="this.style.opacity='0'">
            <span class="partido-detalle-nombre <?= !$eq1Gana ? 'ganador' : 'perdedor' ?>">
                <?= htmlspecialchars($partido['equipo_2']) ?>
            </span>
        </div>
    </div>
</div>

<div class="seccion">
    <a href="resultados.php" class="btn-volver">← Volver a resultados</a>

    <?php if (empty($mapas)): ?>
        <p class="aviso">Este partido no tiene mapas registrados todavía.</p>
    <?php else: ?>
        <?php foreach ($mapas as $mapa): ?>
        <div class="mapa-bloque">
            <h3>
                Mapa <?= htmlspecialchars($mapa['numero_mapa']) ?>
                <?php if ($mapa['equipo_ganador']): ?>
                    <span class="mapa-ganador">— <?= htmlspecialchars($mapa['equipo_ganador']) ?></span>
                <?php endif; ?>
                <?php if ($mapa['duracion_minutos']): ?>
                    <span class="mapa-duracion"><?= htmlspecialchars($mapa['duracion_minutos']) ?> min</span>
                <?php endif; ?>
            </h3>

            <?php if (!empty($statsPorMapa[$mapa['numero_mapa']])): ?>
            <table class="tabla-stats">
                <thead>
                    <tr>
                        <th>Equipo</th><th>Jugador</th><th>Campeón</th><th>Rol</th>
                        <th>K</th><th>D</th><th>A</th><th>KDA</th><th>CS</th><th>Oro</th>
                    </tr>
                </thead>
                <tbody>
                    <?php
                    $equipoAnterior = null;
                    foreach ($statsPorMapa[$mapa['numero_mapa']] as $s):
                        if ($equipoAnterior !== $s['equipo'] && $equipoAnterior !== null):
                    ?>
                    <tr class="separador-equipo"><td colspan="10"></td></tr>
                    <?php
                        endif;
                        $equipoAnterior = $s['equipo'];
                    ?>
                    <tr>
                        <td><?= htmlspecialchars($s['equipo']) ?></td>
                        <td><strong><?= htmlspecialchars($s['nickname']) ?></strong></td>
                        <td><?= htmlspecialchars($s['campeon']) ?></td>
                        <td><?= ImagenHelper::iconoRol($s['rol_jugado']) ?></td>
                        <td><?= htmlspecialchars($s['kills']) ?></td>
                        <td><?= htmlspecialchars($s['deaths']) ?></td>
                        <td><?= htmlspecialchars($s['assists']) ?></td>
                        <td><?= htmlspecialchars($s['kda']) ?></td>
                        <td><?= htmlspecialchars($s['cs']) ?></td>
                        <td><?= htmlspecialchars(number_format($s['oro'])) ?></td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
            <?php else: ?>
                <p class="aviso" style="border-radius:0">No hay estadísticas para este mapa.</p>
            <?php endif; ?>
        </div>
        <?php endforeach; ?>
    <?php endif; ?>
</div>
</main>
<?php require_once __DIR__ . '/includes/footer.php'; ?>