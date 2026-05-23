<?php
require_once __DIR__ . '/clases/ConexionDB.php';
require_once __DIR__ . '/clases/LecDB.php';
require_once __DIR__ . '/ImagenHelper.php';

$ultimosResultados = array_slice(LecDB::listarPartidos(null, true),  0, 6);
$proximosPartidos  = array_slice(LecDB::listarPartidos(null, false), 0, 5);
$equipos2026       = LecDB::listarEquipos(null, 2026, 'Spring');

$paginaActiva = 'inicio';
$tituloPagina = 'Inicio';
require_once __DIR__ . '/includes/header.php';
?>


<section class="hero-video">

    <div class="hero-bg"></div>


    <video class="hero-video-bg"
           autoplay muted loop playsinline preload="auto">
        <source src="assets/video/lec.mp4" type="video/mp4">
    </video>

    <div class="hero-overlay-video"></div>

    <div class="hero-video-content">
        <div class="hero-logos">
            <img src="assets/img/logos/league_of_legends.png"
                 alt="League of Legends"
                 onerror="this.style.display='none'">
            <div class="hero-logos-sep"></div>
            <img src="assets/img/logos/lec.png"
                 alt="LEC"
                 onerror="this.style.display='none'">
        </div>
    </div>

</section>

<main>


<?php if (!empty($proximosPartidos)): ?>
<div class="seccion">
    <div class="seccion-cabecera">
        <h2>Próximos partidos</h2>
        <a href="resultados.php" class="btn-secundario">Ver todos</a>
    </div>
    <div class="proximos-grid">
        <?php foreach ($proximosPartidos as $p): ?>
        <div class="proximo-card">
            <div class="proximo-meta">
                <?= htmlspecialchars($p['split']==='Winter'?'LEC Versus':$p['split']) ?>
                <?= $p['año'] ?> · <?= htmlspecialchars($p['tipo_serie']) ?>
            </div>
            <div class="proximo-fecha"><?= date('d M · H:i', strtotime($p['fecha_hora'])) ?></div>
            <div class="proximo-match">
                <div class="proximo-eq">
                    <img src="<?= htmlspecialchars(ImagenHelper::logoEquipo($p['equipo_1'])) ?>"
                         alt="<?= htmlspecialchars($p['equipo_1']) ?>"
                         onerror="this.style.opacity='0'">
                    <span><?= htmlspecialchars($p['equipo_1']) ?></span>
                </div>
                <span class="proximo-vs">VS</span>
                <div class="proximo-eq proximo-eq--der">
                    <img src="<?= htmlspecialchars(ImagenHelper::logoEquipo($p['equipo_2'])) ?>"
                         alt="<?= htmlspecialchars($p['equipo_2']) ?>"
                         onerror="this.style.opacity='0'">
                    <span><?= htmlspecialchars($p['equipo_2']) ?></span>
                </div>
            </div>
        </div>
        <?php endforeach; ?>
    </div>
</div>
<?php endif; ?>


<?php if (!empty($equipos2026)): ?>
<div class="seccion">
    <div class="seccion-cabecera">
        <h2>Equipos Spring 2026</h2>
        <a href="equipos.php" class="btn-secundario">Ver plantillas</a>
    </div>
    <div class="equipos-logos-grid">
        <?php foreach ($equipos2026 as $eq):
            $color = ImagenHelper::colorEquipo($eq['nombre']);
            $logo  = ImagenHelper::logoEquipo($eq['nombre']);
        ?>
        <a href="equipos.php?equipo=<?= $eq['id_equipo'] ?>"
           class="equipo-logo-item"
           style="--color-eq:<?= htmlspecialchars($color) ?>">
            <img src="<?= htmlspecialchars($logo) ?>"
                 alt="<?= htmlspecialchars($eq['nombre']) ?>"
                 onerror="this.style.opacity='0'">
            <span><?= htmlspecialchars($eq['nombre']) ?></span>
        </a>
        <?php endforeach; ?>
    </div>
</div>
<?php endif; ?>


<?php if (!empty($ultimosResultados)): ?>
<div class="seccion">
    <div class="seccion-cabecera">
        <h2>Últimos resultados</h2>
        <a href="resultados.php" class="btn-secundario">Ver todos</a>
    </div>
    <div class="partidos-lista">
        <?php foreach ($ultimosResultados as $p):
            $eq1Gana = $p['mapas_eq1'] > $p['mapas_eq2'];
        ?>
        <a href="partido.php?id=<?= $p['id_partido'] ?>" class="partido-card">
            <div class="partido-card-meta">
                <?= htmlspecialchars(date('d/m/Y', strtotime($p['fecha_hora']))) ?> ·
                <?= htmlspecialchars($p['fase']) ?> ·
                <?= htmlspecialchars($p['split']==='Winter'?'LEC Versus':$p['split']) ?>
                <?= $p['año'] ?>
            </div>
            <div class="partido-eq <?= $eq1Gana?'ganador':'perdedor' ?>">
                <img class="partido-eq-logo"
                     src="<?= htmlspecialchars(ImagenHelper::logoEquipo($p['equipo_1'])) ?>"
                     alt="" onerror="this.style.opacity='0'">
                <span class="partido-eq-nombre"><?= htmlspecialchars($p['equipo_1']) ?></span>
            </div>
            <div class="partido-centro">
                <div class="partido-score">
                    <span class="<?= $eq1Gana?'score-win':'' ?>"><?= $p['mapas_eq1'] ?></span>
                    <span class="score-sep">—</span>
                    <span class="<?= !$eq1Gana?'score-win':'' ?>"><?= $p['mapas_eq2'] ?></span>
                </div>
                <span class="partido-tipo"><?= htmlspecialchars($p['tipo_serie']) ?></span>
            </div>
            <div class="partido-eq partido-eq--der <?= !$eq1Gana?'ganador':'perdedor' ?>">
                <img class="partido-eq-logo"
                     src="<?= htmlspecialchars(ImagenHelper::logoEquipo($p['equipo_2'])) ?>"
                     alt="" onerror="this.style.opacity='0'">
                <span class="partido-eq-nombre"><?= htmlspecialchars($p['equipo_2']) ?></span>
            </div>
        </a>
        <?php endforeach; ?>
    </div>
</div>
<?php endif; ?>

</main>

<?php require_once __DIR__ . '/includes/footer.php'; ?>