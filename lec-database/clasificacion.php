<?php
require_once __DIR__ . '/clases/ConexionDB.php';
require_once __DIR__ . '/clases/LecDB.php';
require_once __DIR__ . '/ImagenHelper.php';

$añoActual = (int) date('Y');
$año = isset($_GET['año']) ? (int) $_GET['año'] : $añoActual;

$clasificacion = LecDB::listarClasificacion($año);

$paginaActiva = 'clasificacion';
$tituloPagina = 'Clasificación';
require_once __DIR__ . '/includes/header.php';
?>
<main>
<div class="seccion">
    <div class="seccion-cabecera">
        <h2>Clasificación <?= htmlspecialchars($año) ?></h2>
        <form method="GET" action="clasificacion.php" class="filtro-form">
            <label for="año">Año:</label>
            <select name="año" id="año" onchange="this.form.submit()">
                <?php for ($a = $añoActual; $a >= 2013; $a--): ?>
                    <option value="<?= $a ?>" <?= $a === $año ? 'selected' : '' ?>><?= $a ?></option>
                <?php endfor; ?>
            </select>
        </form>
    </div>

    <?php if (empty($clasificacion)): ?>
        <p class="aviso">No hay datos de clasificación para <?= htmlspecialchars($año) ?>.</p>
    <?php else: ?>
        <table class="tabla-clasificacion">
            <thead>
                <tr>
                    <th>#</th>
                    <th>Equipo</th>
                    <th class="c">Partidos</th>
                    <th class="c">V</th>
                    <th class="c">D</th>
                    <th class="c">Win Rate</th>
                    <th class="c">Mapas</th>
                    <th>Splits</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($clasificacion as $pos => $eq): ?>
                <tr>
                    <td class="rank"><?= $pos + 1 ?></td>
                    <td>
                        <img src="assets/img/equipos/<?= $eq['id_equipo'] ?>.png"
                             onerror="this.style.display='none'" width="20" style="vertical-align:middle;margin-right:.4rem">
                        <strong><?= htmlspecialchars($eq['equipo']) ?></strong>
                    </td>
                    <td class="c"><?= $eq['partidos'] ?></td>
                    <td class="c" style="color:var(--win);font-weight:700"><?= $eq['victorias'] ?></td>
                    <td class="c" style="color:#ef5350;font-weight:700"><?= $eq['derrotas'] ?></td>
                    <td class="c">
                        <span style="font-family:var(--font-h);font-weight:800;color:<?= ($eq['win_rate']??0)>=60?'var(--win)':( ($eq['win_rate']??0)>=50?'#fff':'#ef5350') ?>">
                            <?= $eq['win_rate'] ?? 0 ?>%
                        </span>
                    </td>
                    <td class="c" style="color:rgba(255,255,255,.4);font-size:.8rem">
                        <?= ($eq['mapas_ganados'] ?? 0) ?>-<?= ($eq['mapas_perdidos'] ?? 0) ?>
                    </td>
                    <td style="color:rgba(255,255,255,.35);font-size:.75rem"><?= htmlspecialchars($eq['splits'] ?? '') ?></td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
        <p class="leyenda">
            <span class="dot worlds"></span> Clasificado a Worlds &nbsp;
            <span class="dot msi"></span> Clasificado al MSI
        </p>
    <?php endif; ?>
</div>
</main>
<?php require_once __DIR__ . '/includes/footer.php'; ?>