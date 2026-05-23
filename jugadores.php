<?php
require_once __DIR__ . '/clases/ConexionDB.php';
require_once __DIR__ . '/clases/LecDB.php';
require_once __DIR__ . '/ImagenHelper.php';

$busqueda     = trim($_GET['q']   ?? '');
$nacionalidad = trim($_GET['nac'] ?? '');
$rol          = trim($_GET['rol'] ?? '');

$jugadores = LecDB::buscarJugador(
    $busqueda     !== '' ? $busqueda     : null,
    $nacionalidad !== '' ? $nacionalidad : null,
    $rol          !== '' ? $rol          : null
);

$paginaActiva = 'jugadores';
$tituloPagina = 'Jugadores';
require_once __DIR__ . '/includes/header.php';
?>
<main>
<div class="seccion">
    <div class="seccion-cabecera">
        <h2>Jugadores</h2>
    </div>

    <form method="GET" action="jugadores.php" class="buscador-form">
        <input type="text" name="q" placeholder="Buscar por nickname..."
               value="<?= htmlspecialchars($busqueda) ?>" class="input-busqueda">
        <select name="rol">
            <option value="">Todos los roles</option>
            <?php foreach (['Top','Jungle','Mid','ADC','Support'] as $r): ?>
                <option value="<?= $r ?>" <?= $rol === $r ? 'selected' : '' ?>><?= $r ?></option>
            <?php endforeach; ?>
        </select>
        <button type="submit" class="btn-primario">Buscar</button>
        <a href="jugadores.php" class="btn-secundario">Limpiar</a>
    </form>

    <?php if (empty($jugadores)): ?>
        <p class="aviso">
            <?= $busqueda !== '' || $rol !== '' ? 'No se encontraron jugadores con esos filtros.' : 'Usa el buscador para encontrar jugadores.' ?>
        </p>
    <?php else: ?>
        <p style="color:var(--text2);font-size:.85rem;margin-bottom:1rem;">
            <?= count($jugadores) ?> jugador(es) encontrado(s).
        </p>
        <table class="tabla-partidos">
            <thead>
                <tr>
                    <th></th>
                    <th>Nickname</th>
                    <th>Nombre real</th>
                    <th>Rol</th>
                    <th>Nacionalidad</th>
                    <th>Edad</th>
                    <th>Equipo actual</th>
                    <th>Split</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($jugadores as $j):
                    $equipoActual = $j['equipo_actual'] ?? '';
                    $foto = $equipoActual !== ''
                        ? ImagenHelper::fotoJugador($j['nickname'], $equipoActual)
                        : 'assets/img/placeholder_jugador.png';
                    $color = $equipoActual !== ''
                        ? ImagenHelper::colorEquipo($equipoActual)
                        : 'var(--border)';
                ?>
                <tr>
                    <td>
                        <img src="<?= htmlspecialchars($foto) ?>"
                             alt="<?= htmlspecialchars($j['nickname']) ?>"
                             class="jugador-avatar"
                             style="border-color:<?= htmlspecialchars($color) ?>"
                             onerror="this.style.opacity='0'">
                    </td>
                    <td><strong><?= htmlspecialchars($j['nickname']) ?></strong></td>
                    <td><?= htmlspecialchars($j['nombre_real'] ?? '—') ?></td>
                    <td>
                        <span class="rol rol-<?= strtolower(htmlspecialchars($j['rol_principal'])) ?>">
                            <?= ImagenHelper::iconoRol($j['rol_principal']) ?>
                        </span>
                    </td>
                    <td><?= htmlspecialchars($j['nacionalidad'] ?? '—') ?></td>
                    <td><?= htmlspecialchars($j['edad'] ?? '—') ?></td>
                    <td><?= htmlspecialchars($equipoActual ?: '—') ?></td>
                    <td><?= htmlspecialchars($j['split_actual'] ?? '—') ?></td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    <?php endif; ?>
</div>
</main>
<?php require_once __DIR__ . '/includes/footer.php'; ?>