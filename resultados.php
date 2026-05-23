<?php
require_once __DIR__ . '/clases/ConexionDB.php';
require_once __DIR__ . '/clases/LecDB.php';
require_once __DIR__ . '/ImagenHelper.php';

$idSplit     = isset($_GET['id_split'])     ? (int)$_GET['id_split']          : null;
$año         = isset($_GET['año'])          ? (int)$_GET['año']               : null;
$splitNombre = isset($_GET['split_nombre']) ? trim($_GET['split_nombre'])      : null;

$partidos = LecDB::listarPartidos($idSplit, true, $año, $splitNombre);
$años     = LecDB::listarAños();

$paginaActiva = 'resultados';
$tituloPagina = 'Resultados';
require_once __DIR__ . '/includes/header.php';
?>
<main>
<div class="seccion">
    <div class="seccion-cabecera">
        <h2>Resultados</h2>
        <form method="GET" action="resultados.php" class="filtro-form">
            <label for="año">Año:</label>
            <select name="año" id="año">
                <option value="">Todos</option>
                <?php foreach ($años as $a): ?>
                    <option value="<?= htmlspecialchars($a['año']) ?>"
                        <?= $año === (int)$a['año'] ? 'selected' : '' ?>>
                        <?= htmlspecialchars($a['año']) ?>
                    </option>
                <?php endforeach; ?>
            </select>
            <label for="split_nombre">Split:</label>
            <select name="split_nombre" id="split_nombre">
                <option value="">Todos</option>
                <option value="Spring" <?= $splitNombre === 'Spring' ? 'selected' : '' ?>>Spring</option>
                <option value="Summer" <?= $splitNombre === 'Summer' ? 'selected' : '' ?>>Summer</option>
                <option value="Winter" <?= $splitNombre === 'Winter' ? 'selected' : '' ?>>LEC Versus</option>
            </select>
            <button type="submit" class="btn-secundario">Filtrar</button>
            <a href="resultados.php" class="btn-secundario">Limpiar</a>
        </form>
    </div>

    <?php if (empty($partidos)): ?>
        <p class="aviso">No hay resultados para los filtros seleccionados.</p>
    <?php else: ?>
        <div class="partidos-lista">
            <?php foreach ($partidos as $p):
                $eq1Gana = $p['mapas_eq1'] > $p['mapas_eq2'];
            ?>
            <a href="partido.php?id=<?= htmlspecialchars($p['id_partido']) ?>" class="partido-card">
                <div class="partido-card-meta">
                    <?= htmlspecialchars(date('d/m/Y', strtotime($p['fecha_hora']))) ?> &middot;
                    <?= htmlspecialchars($p['fase']) ?> &middot;
                    <?= htmlspecialchars($p['split'] === 'Winter' ? 'LEC Versus' : $p['split']) ?>
                    <?= htmlspecialchars($p['año']) ?>
                </div>
                <div class="partido-eq <?= $eq1Gana ? 'ganador' : 'perdedor' ?>">
                    <img class="partido-eq-logo"
                         src="<?= htmlspecialchars(ImagenHelper::logoEquipo($p['equipo_1'])) ?>"
                         alt="<?= htmlspecialchars($p['equipo_1']) ?>"
                         onerror="this.style.opacity='0'">
                    <span class="partido-eq-nombre"><?= htmlspecialchars($p['equipo_1']) ?></span>
                </div>
                <div class="partido-centro">
                    <div class="partido-score">
                        <span class="<?= $eq1Gana ? 'score-win' : '' ?>"><?= htmlspecialchars($p['mapas_eq1']) ?></span>
                        <span class="score-sep">—</span>
                        <span class="<?= !$eq1Gana ? 'score-win' : '' ?>"><?= htmlspecialchars($p['mapas_eq2']) ?></span>
                    </div>
                    <span class="partido-tipo"><?= htmlspecialchars($p['tipo_serie']) ?></span>
                </div>
                <div class="partido-eq partido-eq--der <?= !$eq1Gana ? 'ganador' : 'perdedor' ?>">
                    <img class="partido-eq-logo"
                         src="<?= htmlspecialchars(ImagenHelper::logoEquipo($p['equipo_2'])) ?>"
                         alt="<?= htmlspecialchars($p['equipo_2']) ?>"
                         onerror="this.style.opacity='0'">
                    <span class="partido-eq-nombre"><?= htmlspecialchars($p['equipo_2']) ?></span>
                </div>
            </a>
            <?php endforeach; ?>
        </div>
    <?php endif; ?>
</div>
</main>
<?php require_once __DIR__ . '/includes/footer.php'; ?>
