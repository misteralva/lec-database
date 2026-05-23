<?php
session_start();
require_once __DIR__ . '/auth.php';
auth('editor');
require_once __DIR__ . '/../ImagenHelper.php';
require_once __DIR__ . '/../clases/ConexionDB.php';
require_once __DIR__ . '/../clases/LecDB.php';
require_once __DIR__ . '/helpers.php';
require_once __DIR__ . '/../includes/csrf.php';

$mensaje = '';
$tipo    = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!csrf_verify()) {
        $mensaje = 'Token de seguridad inválido. Recarga la página.';
        $tipo    = 'error';
    } else {
        $accion = $_POST['accion'] ?? '';

        if ($accion === 'fichar') {
            $res = LecDB::ficharJugador(
                trim($_POST['nickname']     ?? ''),
                trim($_POST['nombre_real']  ?? ''),
                trim($_POST['nacionalidad'] ?? ''),
                $_POST['fecha_nac']         ?? '',
                $_POST['rol']               ?? '',
                (int)($_POST['id_historial'] ?? 0),
                isset($_POST['es_titular']),
                $_POST['fecha_inicio']      ?? ''
            );
            $mensaje = $res['mensaje'];
            $tipo    = $res['ok'] ? 'exito' : 'error';
        }

        if (in_array($accion, ['TITULAR','SUPLENTE','ROL','BAJA'])) {
            $res = LecDB::gestionarJugador(
                (int)($_POST['id_jugador'] ?? 0),
                $accion,
                $_POST['nuevo_rol']  ?? null,
                $_POST['fecha_fin']  ?? null,
                isset($_POST['forzar'])
            );
            $mensaje = $res['mensaje'];
            $tipo    = $res['ok'] ? 'exito' : 'error';
        }

        if ($accion === 'editar_datos' && esSuperAdmin()) {
            $pdo = ConexionDB::getInstancia('backend')->getConexion();
            $pdo->exec('SET @admin_bypass = 1');
            $pdo->exec('SET @msg_jug = NULL');
            $stmt = $pdo->prepare('CALL sp_editar_jugador(?,?,?,?,?,?,@msg_jug)');
            $stmt->execute([
                (int)$_POST['id_jugador'],
                trim($_POST['nickname']     ?? ''),
                trim($_POST['nombre_real']  ?? ''),
                trim($_POST['nacionalidad'] ?? ''),
                $_POST['rol_principal']     ?? 'Top',
                isset($_POST['activo']) ? 1 : 0,
            ]);
            while ($stmt->nextRowset()) {}
            $r = $pdo->query('SELECT @msg_jug AS msg')->fetch();
            $pdo->exec('SET @admin_bypass = NULL');
            $mensaje = $r['msg'] ?? 'Jugador actualizado.';
            $tipo    = 'exito';
        }
    }
}

$splits = LecDB::listarSplits(true);

$busqueda     = trim($_GET['q'] ?? '');
$jugadores    = $busqueda !== '' ? LecDB::buscarJugador($busqueda) : [];
$idJugadorSel = isset($_GET['jugador']) ? (int)$_GET['jugador'] : null;
?>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Gestionar Jugadores — LEC Admin</title>
<link rel="stylesheet" href="../assets/css/estilo.css">
</head>
<body class="admin">

<header class="admin-header">
    <div class="header-inner">
        <a href="panel.php" class="logo">LEC Admin</a>
        <nav>
            <a href="panel.php">← Panel</a>
            <a href="logout.php" class="btn-logout">Cerrar sesión</a>
        </nav>
        <p class="admin-usuario">Hola, <?= htmlspecialchars(usuarioNombre()) ?></p>
    </div>
</header>

<main class="admin-main">

    <?php if ($mensaje): ?>
        <div class="alerta alerta-<?= htmlspecialchars($tipo) ?>"><?= htmlspecialchars($mensaje) ?></div>
    <?php endif; ?>

    
    <section class="seccion-admin">
        <h2>Fichar jugador</h2>
        <form method="POST" action="gestionar_jugadores.php" class="formulario">
            <?= csrf_field() ?>
            <input type="hidden" name="accion" value="fichar">

            <div class="campo">
                <label>Nickname</label>
                <input type="text" name="nickname" required>
            </div>
            <div class="campo">
                <label>Nombre real</label>
                <input type="text" name="nombre_real">
            </div>
            <div class="campo">
                <label>Nacionalidad</label>
                <input type="text" name="nacionalidad">
            </div>
            <div class="campo">
                <label>Fecha de nacimiento</label>
                <input type="date" name="fecha_nac">
            </div>
            <div class="campo">
                <label>Rol</label>
                <select name="rol" required>
                    <?php foreach (['Top','Jungle','Mid','ADC','Support'] as $r): ?>
                        <option value="<?= $r ?>"><?= $r ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="campo">
                <label>Equipo y split</label>
                <select name="id_historial" required>
                    <option value="">Selecciona un split abierto...</option>
                    <?php foreach ($splits as $s):
                        $historiales = LecDB::listarHistorialesPorSplit($s['id_split']);
                    ?>
                        <optgroup label="<?= htmlspecialchars($s['nombre_completo'] ?? ($s['nombre'] . ' ' . $s['año'])) ?>">
                            <?php foreach ($historiales as $h): ?>
                                <option value="<?= htmlspecialchars($h['id_historial_equipo']) ?>">
                                    <?= htmlspecialchars($h['nombre']) ?>
                                </option>
                            <?php endforeach; ?>
                        </optgroup>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="campo">
                <label>
                    <input type="checkbox" name="es_titular" value="1"> Titular
                </label>
            </div>
            <div class="campo">
                <label>Fecha de inicio del contrato</label>
                <input type="date" name="fecha_inicio" value="<?= date('Y-m-d') ?>" required>
            </div>
            <div class="botones">
                <button type="submit" class="btn-primario">Fichar jugador</button>
            </div>
        </form>
    </section>

    
    <section class="seccion-admin">
        <h2>Gestionar jugador existente</h2>

        <form method="GET" action="gestionar_jugadores.php" class="buscador-form" style="margin-bottom:1.2rem">
            <input type="text" name="q" placeholder="Buscar jugador por nickname..."
                   value="<?= htmlspecialchars($busqueda) ?>" class="input-busqueda">
            <button type="submit" class="btn-secundario">Buscar</button>
        </form>

        <?php if ($busqueda !== '' && empty($jugadores)): ?>
            <p class="aviso">No se encontraron jugadores con ese nickname.</p>
        <?php endif; ?>

        <?php if (!empty($jugadores)): ?>
        <table class="tabla-admin" style="margin-bottom:1.5rem">
            <thead>
                <tr><th>Nickname</th><th>Rol</th><th>Equipo actual</th><th>Split</th><th>Acción</th></tr>
            </thead>
            <tbody>
                <?php foreach ($jugadores as $j): ?>
                <tr>
                    <td><?= htmlspecialchars($j['nickname']) ?></td>
                    <td>
                        <span class="rol rol-<?= strtolower(htmlspecialchars($j['rol_principal'])) ?>">
                            <?= htmlspecialchars($j['rol_principal']) ?>
                        </span>
                    </td>
                    <td><?= htmlspecialchars($j['equipo_actual'] ?? '—') ?></td>
                    <td><?= htmlspecialchars($j['split_actual'] ?? '—') ?></td>
                    <td>
                        <a href="?q=<?= urlencode($busqueda) ?>&jugador=<?= $j['id_jugador'] ?>"
                           class="btn-secundario">Gestionar</a>
                    </td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
        <?php endif; ?>

        <?php if ($idJugadorSel): ?>
        <div class="formulario" style="border:1px solid var(--border);border-radius:var(--r-lg);padding:1.5rem">
            <h3 style="margin-bottom:1rem;font-family:var(--font-h);font-size:1.1rem;color:var(--text2)">
                Acciones — jugador ID <?= htmlspecialchars($idJugadorSel) ?>
            </h3>

            
            <form method="POST" action="gestionar_jugadores.php?q=<?= urlencode($busqueda) ?>&jugador=<?= $idJugadorSel ?>">
                <?= csrf_field() ?>
                <input type="hidden" name="id_jugador" value="<?= htmlspecialchars($idJugadorSel) ?>">
                <div class="botones" style="margin-bottom:1rem">
                    <button type="submit" name="accion" value="TITULAR" class="btn-secundario">Poner titular</button>
                    <button type="submit" name="accion" value="SUPLENTE" class="btn-secundario">Poner suplente</button>
                    <label style="display:flex;align-items:center;gap:.4rem;font-size:.85rem;color:var(--text2)">
                        <input type="checkbox" name="forzar" value="1"> Forzar
                    </label>
                </div>
            </form>

            
            <form method="POST" action="gestionar_jugadores.php?q=<?= urlencode($busqueda) ?>&jugador=<?= $idJugadorSel ?>" style="margin-bottom:1rem">
                <?= csrf_field() ?>
                <input type="hidden" name="accion" value="ROL">
                <input type="hidden" name="id_jugador" value="<?= htmlspecialchars($idJugadorSel) ?>">
                <div class="campo">
                    <label>Cambiar rol</label>
                    <div style="display:flex;gap:.8rem">
                        <select name="nuevo_rol">
                            <?php foreach (['Top','Jungle','Mid','ADC','Support'] as $r): ?>
                                <option value="<?= $r ?>"><?= $r ?></option>
                            <?php endforeach; ?>
                        </select>
                        <button type="submit" class="btn-secundario">Cambiar rol</button>
                    </div>
                </div>
            </form>

            
            <form method="POST" action="gestionar_jugadores.php?q=<?= urlencode($busqueda) ?>&jugador=<?= $idJugadorSel ?>">
                <?= csrf_field() ?>
                <input type="hidden" name="accion" value="BAJA">
                <input type="hidden" name="id_jugador" value="<?= htmlspecialchars($idJugadorSel) ?>">
                <div class="campo">
                    <label>Fecha de baja</label>
                    <div style="display:flex;gap:.8rem">
                        <input type="date" name="fecha_fin" value="<?= date('Y-m-d') ?>" required>
                        <button type="submit" class="btn-peligro"
                                onclick="return confirm('¿Seguro que quieres dar de baja a este jugador?')">
                            Dar de baja
                        </button>
                    </div>
                </div>
            </form>
        <?php if(esSuperAdmin()): ?>
        <div class="formulario" style="border:1px solid rgba(10,200,185,.2);border-radius:var(--r-lg);padding:1.5rem;margin-top:1rem">
            <h3 style="margin-bottom:1rem;font-family:var(--font-h);font-size:.72rem;font-weight:800;letter-spacing:2px;text-transform:uppercase;color:var(--cyan)">
                Editar datos del jugador (superadmin)
            </h3>
            <?php
            $jugSel = null;
            if ($idJugadorSel) {
                $stmt2 = ConexionDB::getInstancia('backend')->getConexion()
                             ->prepare('SELECT * FROM jugador WHERE id_jugador=?');
                $stmt2->execute([$idJugadorSel]);
                $jugSel = $stmt2->fetch();
            }
            ?>
            <form method="POST" action="gestionar_jugadores.php?q=<?= urlencode($busqueda) ?>&jugador=<?= $idJugadorSel ?>"
                  style="display:flex;gap:.7rem;flex-wrap:wrap;align-items:flex-end">
                <?= csrf_field() ?>
                <input type="hidden" name="accion" value="editar_datos">
                <input type="hidden" name="id_jugador" value="<?= $idJugadorSel ?>">
                <div class="campo" style="margin-bottom:0">
                    <label>Nickname</label>
                    <input type="text" name="nickname" value="<?= htmlspecialchars($jugSel['nickname'] ?? '') ?>" class="inp-sm" required>
                </div>
                <div class="campo" style="margin-bottom:0">
                    <label>Nombre real</label>
                    <input type="text" name="nombre_real" value="<?= htmlspecialchars($jugSel['nombre_real'] ?? '') ?>" class="inp-sm">
                </div>
                <div class="campo" style="margin-bottom:0">
                    <label>Nacionalidad</label>
                    <input type="text" name="nacionalidad" value="<?= htmlspecialchars($jugSel['nacionalidad'] ?? '') ?>" class="inp-sm">
                </div>
                <div class="campo" style="margin-bottom:0">
                    <label>Rol</label>
                    <select name="rol_principal" class="inp-sm" style="width:auto">
                        <?php foreach(['Top','Jungle','Mid','ADC','Support'] as $r): ?>
                        <option value="<?= $r ?>" <?= ($jugSel['rol_principal']??'')===$r?'selected':'' ?>><?= $r ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="campo" style="margin-bottom:0">
                    <label><input type="checkbox" name="activo" value="1" <?= ($jugSel['activo']??1)?'checked':'' ?>> Activo</label>
                </div>
                <button type="submit" class="btn-primario">Guardar datos</button>
            </form>
        </div>
        <?php endif; ?>
        </div>
        <?php endif; ?>
    </section>

</main>
</body>
</html>