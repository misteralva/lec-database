<?php
require_once __DIR__ . '/clases/ConexionDB.php';
require_once __DIR__ . '/clases/LecDB.php';
require_once __DIR__ . '/ImagenHelper.php';

function callSP(PDO $pdo, string $sql, array $params = []): array {
    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $data = $stmt->fetchAll();
        while ($stmt->nextRowset()) {}
        return $data;
    } catch (Exception $e) {
        error_log("callSP [$sql]: " . $e->getMessage());
        return [];
    }
}

$idSplit     = isset($_GET['id_split'])     ? (int)$_GET['id_split']     : null;
$año         = isset($_GET['año'])          ? (int)$_GET['año']          : null;
$splitNombre = isset($_GET['split_nombre']) ? trim($_GET['split_nombre']) : null;

$equipos = LecDB::listarEquipos($idSplit, $año, $splitNombre);
$años    = LecDB::listarAños();

$idEquipoVer  = isset($_GET['equipo']) ? (int)$_GET['equipo'] : null;
$jugadores    = [];
$entrenadores = [];
$equipoActual = null;

if ($idEquipoVer) {
    $jugadores = LecDB::listarJugadoresEquipo($idEquipoVer, $idSplit, $año, $splitNombre);

    try {
        $pdo = ConexionDB::getInstancia('readonly')->getConexion();
        $entrenadores = callSP($pdo, "CALL sp_get_entrenador_equipo(?, ?)", [$idEquipoVer, $idSplit]);
    } catch (Exception $e) {}

    foreach ($equipos as $eq) {
        if ((int)$eq['id_equipo'] === $idEquipoVer) { $equipoActual = $eq; break; }
    }
    if (!$equipoActual) {
        foreach (LecDB::listarEquipos() as $eq) {
            if ((int)$eq['id_equipo'] === $idEquipoVer) { $equipoActual = $eq; break; }
        }
    }
}

$paramsFiltro = http_build_query(array_filter([
    'año' => $año, 'split_nombre' => $splitNombre, 'id_split' => $idSplit
]));
$urlVolver = 'equipos.php' . ($paramsFiltro ? '?' . $paramsFiltro : '');

$paginaActiva = 'equipos';
$tituloPagina = $equipoActual ? htmlspecialchars($equipoActual['nombre']) : 'Equipos';
require_once __DIR__ . '/includes/header.php';
?>
<main>

<?php if ($idEquipoVer && $equipoActual): ?>
    <?php
        $nombreEq = $equipoActual['nombre'];
        $colorEq  = ImagenHelper::colorEquipo($nombreEq);
        $logoEq   = ImagenHelper::logoEquipo($nombreEq);
        $fondoEq  = ImagenHelper::fondoEquipo($nombreEq);
    ?>

    <div class="eq-hero" style="--color-eq: <?= htmlspecialchars($colorEq) ?>">
        <div class="eq-hero-fondo" style="background-image: url('<?= htmlspecialchars($fondoEq) ?>')"></div>
        <div class="eq-hero-color-overlay"
             style="background: linear-gradient(90deg, <?= htmlspecialchars($colorEq) ?>44 0%, transparent 60%)"></div>
        <div class="eq-hero-overlay"></div>
        <div class="eq-hero-content">
            <img src="<?= htmlspecialchars($logoEq) ?>" alt="<?= htmlspecialchars($nombreEq) ?>"
                 class="eq-hero-logo" onerror="this.style.display='none'">
            <div>
                <h1 class="eq-hero-nombre"><?= htmlspecialchars($nombreEq) ?></h1>
                <p class="eq-hero-liga">LEC · EMEA</p>
            </div>
        </div>
        <a href="<?= htmlspecialchars($urlVolver) ?>" class="eq-hero-volver">← Equipos</a>
    </div>

    <div class="seccion">

        
        <?php if (empty($jugadores)): ?>
            <p class="aviso">No hay jugadores registrados para este período.</p>
        <?php else: ?>
            <div class="jugadores-grid">
                <?php foreach ($jugadores as $j):
                    $fotoUrl = ImagenHelper::fotoJugador($j['nickname'], $nombreEq);
                    $rolCss  = strtolower($j['rol']);
                ?>
                <div class="jugador-card" style="--color-eq: <?= htmlspecialchars($colorEq) ?>">
                    <div class="jugador-card-fondo">
                        <img src="<?= htmlspecialchars($logoEq) ?>" alt=""
                             class="jugador-card-watermark" onerror="this.style.display='none'">
                    </div>
                    <div class="jugador-rol-icon jugador-rol-<?= htmlspecialchars($rolCss) ?>">
                        <?= ImagenHelper::iconoRol($j['rol']) ?>
                    </div>
                    <div class="jugador-foto-wrap">
                        <img src="<?= htmlspecialchars($fotoUrl) ?>"
                             alt="<?= htmlspecialchars($j['nickname']) ?>"
                             class="jugador-foto"
                             onerror="this.src='assets/img/placeholder_jugador.png'">
                    </div>
                    <div class="jugador-info">
                        <h3 class="jugador-nick"><?= htmlspecialchars($j['nickname']) ?></h3>
                        <p class="jugador-real"><?= htmlspecialchars($j['nombre_real'] ?? '') ?></p>
                    </div>
                </div>
                <?php endforeach; ?>
            </div>
        <?php endif; ?>

    
        <?php if (!empty($entrenadores)): ?>
        <div class="staff-seccion">
            <p class="staff-titulo">Cuerpo técnico</p>
            <div class="staff-grid">
            <?php foreach ($entrenadores as $coach): ?>
                <div class="staff-card">
                    <?php
                        $nickFile = str_replace(' ', '_', $coach['nickname']);
                        $fotoExt  = file_exists($_SERVER['DOCUMENT_ROOT'] . '/proyecto/assets/img/entrenadores/' . $nickFile . '.webp') ? '.webp' : '.png';
                        $fotoCoach = 'assets/img/entrenadores/' . $nickFile . $fotoExt;
                    ?>
                    <img src="<?= htmlspecialchars($fotoCoach) ?>"
                         onerror="this.src='assets/img/placeholder_jugador.png'"
                         class="staff-foto" alt="<?= htmlspecialchars($coach['nickname']) ?>">
                    <div class="staff-info">
                        <span class="staff-rol"><?= htmlspecialchars($coach['rol']) ?></span>
                        <span class="staff-nombre"><?= htmlspecialchars($coach['nombre']) ?></span>
                        <span class="staff-nick"><?= htmlspecialchars($coach['nickname']) ?></span>
                    </div>
                </div>
            <?php endforeach; ?>
            </div>
        </div>
        <?php endif; ?>

    </div>

<?php else: ?>

    
    <div class="seccion">
        <div class="seccion-cabecera">
            <h2>Equipos</h2>
            <form method="GET" action="equipos.php" class="filtro-form">
                <label>Año:</label>
                <select name="año">
                    <option value="">Todos</option>
                    <?php foreach ($años as $a): ?>
                        <option value="<?= htmlspecialchars($a['año']) ?>"
                            <?= $año === (int)$a['año'] ? 'selected' : '' ?>>
                            <?= htmlspecialchars($a['año']) ?>
                        </option>
                    <?php endforeach; ?>
                </select>
                <label>Split:</label>
                <select name="split_nombre">
                    <option value="">Todos</option>
                    <option value="Spring" <?= $splitNombre === 'Spring' ? 'selected' : '' ?>>Spring</option>
                    <option value="Summer" <?= $splitNombre === 'Summer' ? 'selected' : '' ?>>Summer</option>
                    <option value="Winter" <?= $splitNombre === 'Winter' ? 'selected' : '' ?>>LEC Versus</option>
                </select>
                <button type="submit" class="btn-secundario">Filtrar</button>
                <a href="equipos.php" class="btn-secundario">Limpiar</a>
            </form>
        </div>

        <?php if (empty($equipos)): ?>
            <p class="aviso">No hay equipos para los filtros seleccionados.</p>
        <?php else: ?>
            <div class="equipos-lista">
                <?php foreach ($equipos as $equipo):
                    $colorEq = ImagenHelper::colorEquipo($equipo['nombre']);
                    $logoEq  = ImagenHelper::logoEquipo($equipo['nombre']);
                ?>
                <a href="equipos.php?equipo=<?= htmlspecialchars($equipo['id_equipo']) ?>&<?= htmlspecialchars($paramsFiltro) ?>"
                   class="equipo-fila" style="--color-eq: <?= htmlspecialchars($colorEq) ?>">
                    <div class="equipo-fila-logo">
                        <img src="<?= htmlspecialchars($logoEq) ?>"
                             alt="<?= htmlspecialchars($equipo['nombre']) ?>"
                             onerror="this.style.opacity='0'">
                    </div>
                    <span class="equipo-fila-nombre"><?= htmlspecialchars($equipo['nombre']) ?></span>
                    <span class="equipo-fila-pais"><?= htmlspecialchars($equipo['pais'] ?? '') ?></span>
                    <span class="equipo-fila-arrow">›</span>
                </a>
                <?php endforeach; ?>
            </div>
        <?php endif; ?>
    </div>

<?php endif; ?>
</main>
<?php require_once __DIR__ . '/includes/footer.php'; ?>