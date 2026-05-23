<?php
session_start();
require_once __DIR__ . '/../clases/ConexionDB.php';
require_once __DIR__ . '/../clases/Config.php';
require_once __DIR__ . '/auth.php';
auth('superadmin'); 

$pdo = ConexionDB::getInstancia('backend')->getConexion();
$msg = ''; $err = '';


$tablaExiste = false;
try {
    $tablaExiste = (bool)$pdo->query("SHOW TABLES LIKE 'usuarios_admin'")->fetchColumn();
} catch(Exception $e) {}

if (!$tablaExiste) {
    
    try {
        $pdo->exec("CREATE TABLE usuarios_admin (
            id_usuario    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            nombre        VARCHAR(80)  NOT NULL,
            email         VARCHAR(120) NOT NULL UNIQUE,
            password_hash VARCHAR(255) NOT NULL,
            rol           ENUM('superadmin','editor','auditor') NOT NULL DEFAULT 'editor',
            activo        BOOLEAN NOT NULL DEFAULT TRUE,
            ultimo_acceso DATETIME NULL,
            fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");

        
        $hashInicial = password_hash('password', PASSWORD_BCRYPT, ['cost' => 10]);
        $pdo->prepare("INSERT IGNORE INTO usuarios_admin (nombre,email,password_hash,rol) VALUES (?,?,?,?)")
            ->execute(['Administrador','admin@lec.es', $hashInicial,'superadmin']);

        $tablaExiste = true;
        $msg = '✓ Tabla de usuarios creada. Usuario inicial: admin@lec.es / password';
    } catch (Exception $e) {
        $err = 'Error al crear la tabla: ' . $e->getMessage();
    }
}


if ($tablaExiste && ($_POST['accion'] ?? '') === 'crear') {
    $nombre = trim($_POST['nombre'] ?? '');
    $email  = trim($_POST['email'] ?? '');
    $pass   = $_POST['password'] ?? '';
    $rol    = in_array($_POST['rol'], ['editor','auditor','superadmin']) ? $_POST['rol'] : 'editor';

    if (!$nombre || !$email || !$pass) {
        $err = 'Todos los campos son obligatorios.';
    } elseif (strlen($pass) < 8) {
        $err = 'La contraseña debe tener al menos 8 caracteres.';
    } else {
        try {
            $hash = password_hash($pass, PASSWORD_BCRYPT, ['cost'=>12]);
            $pdo->prepare("INSERT INTO usuarios_admin (nombre,email,password_hash,rol) VALUES (?,?,?,?)")
                ->execute([$nombre, $email, $hash, $rol]);
            $msg = "✓ Usuario '$nombre' creado correctamente.";
        } catch (PDOException $e) {
            $err = str_contains($e->getMessage(),'Duplicate') ? 'Ese email ya existe.' : 'Error al crear el usuario.';
        }
    }
}


if ($tablaExiste && ($_POST['accion'] ?? '') === 'toggle') {
    $id = (int)$_POST['id_usuario'];
    if ($id !== usuarioId()) { 
        $pdo->prepare("UPDATE usuarios_admin SET activo = NOT activo WHERE id_usuario=?")->execute([$id]);
        $msg = 'Estado del usuario actualizado.';
    }
}


if ($tablaExiste && ($_POST['accion'] ?? '') === 'cambiar_pass') {
    $id   = (int)$_POST['id_usuario'];
    $pass = $_POST['nueva_pass'] ?? '';
    if (strlen($pass) < 8) {
        $err = 'La contraseña debe tener al menos 8 caracteres.';
    } else {
        $hash = password_hash($pass, PASSWORD_BCRYPT, ['cost'=>12]);
        $pdo->prepare("UPDATE usuarios_admin SET password_hash=? WHERE id_usuario=?")->execute([$hash, $id]);
        $msg = 'Contraseña actualizada correctamente.';
    }
}


if ($tablaExiste && ($_POST['accion'] ?? '') === 'cambiar_rol') {
    $id  = (int)$_POST['id_usuario'];
    $rol = in_array($_POST['rol'], ['editor','auditor','superadmin']) ? $_POST['rol'] : 'editor';
    if ($id !== usuarioId()) {
        $pdo->prepare("UPDATE usuarios_admin SET rol=? WHERE id_usuario=?")->execute([$rol, $id]);
        $msg = 'Rol actualizado correctamente.';
    } else {
        $err = 'No puedes cambiar tu propio rol.';
    }
}


if ($tablaExiste && ($_POST['accion'] ?? '') === 'eliminar') {
    $id = (int)$_POST['id_usuario'];
    if ($id !== usuarioId()) {
        $pdo->prepare("DELETE FROM usuarios_admin WHERE id_usuario=?")->execute([$id]);
        $msg = 'Usuario eliminado correctamente.';
    } else {
        $err = 'No puedes eliminar tu propia cuenta.';
    }
}

$usuarios = [];
if ($tablaExiste) {
    try { $usuarios = $pdo->query("SELECT * FROM usuarios_admin ORDER BY id_usuario ASC")->fetchAll(); }
    catch(Exception $e) { $err = 'Error al cargar usuarios: ' . $e->getMessage(); }
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Usuarios — LEC Admin</title>
<link rel="stylesheet" href="../assets/css/estilo.css">
<style>
.gu-wrap{max-width:1000px;margin:1.5rem auto;padding:0 1.5rem}
.gu-card{background:#111;border:1px solid rgba(255,255,255,.07);border-radius:2px;padding:1.2rem;margin-bottom:.8rem;display:flex;align-items:center;gap:1rem;flex-wrap:wrap}
.gu-avatar{width:40px;height:40px;border-radius:50%;background:var(--s2);display:flex;align-items:center;justify-content:center;font-family:var(--font-h);font-size:1rem;font-weight:900;color:var(--cyan);flex-shrink:0}
.gu-info{flex:1;min-width:200px}
.gu-nombre{font-family:var(--font-h);font-size:.95rem;font-weight:800;color:#fff}
.gu-email{font-family:var(--font-h);font-size:.68rem;color:rgba(255,255,255,.3);margin-top:.2rem}
.gu-acceso{font-family:var(--font-h);font-size:.62rem;color:rgba(255,255,255,.2);margin-top:.2rem}
.badge-superadmin{background:rgba(10,200,185,.12);color:var(--cyan);border:1px solid rgba(10,200,185,.25);padding:.2rem .7rem;border-radius:2px;font-family:var(--font-h);font-size:.6rem;font-weight:800;letter-spacing:1.5px;text-transform:uppercase}
.badge-editor{background:rgba(255,255,255,.05);color:rgba(255,255,255,.4);border:1px solid rgba(255,255,255,.1);padding:.2rem .7rem;border-radius:2px;font-family:var(--font-h);font-size:.6rem;font-weight:800;letter-spacing:1.5px;text-transform:uppercase}
.badge-auditor{background:rgba(156,39,176,.1);color:#ce93d8;border:1px solid rgba(156,39,176,.2);padding:.2rem .7rem;border-radius:2px;font-family:var(--font-h);font-size:.6rem;font-weight:800;letter-spacing:1.5px;text-transform:uppercase}
.badge-inactivo{background:rgba(244,67,54,.08);color:#ef5350;border:1px solid rgba(244,67,54,.2);padding:.2rem .7rem;border-radius:2px;font-family:var(--font-h);font-size:.6rem;font-weight:800;text-transform:uppercase}
.inp-sm{background:#1a1a1a;border:1px solid rgba(255,255,255,.1);color:#fff;padding:.3rem .6rem;border-radius:2px;font-size:.82rem;width:200px}
.inp-sm:focus{outline:none;border-color:var(--cyan)}
.flash-ok{background:rgba(10,200,185,.08);border:1px solid rgba(10,200,185,.2);color:var(--win);padding:.6rem 1rem;border-radius:2px;font-family:var(--font-h);font-size:.8rem;margin-bottom:1rem}
.flash-err{background:rgba(229,57,53,.08);border:1px solid rgba(229,57,53,.2);color:#ef5350;padding:.6rem 1rem;border-radius:2px;font-family:var(--font-h);font-size:.8rem;margin-bottom:1rem}
</style>
</head>
<body style="background:#000">
<?php require_once __DIR__ . '/admin_header.php'; ?>
<div class="gu-wrap">
    <?php if($msg): ?><div class="flash-ok"><?= htmlspecialchars($msg) ?></div><?php endif; ?>
    <?php if($err): ?><div class="flash-err">⚠ <?= htmlspecialchars($err) ?></div><?php endif; ?>

    
    <div style="background:#111;border:1px solid rgba(255,255,255,.07);border-radius:2px;padding:1.2rem;margin-bottom:1.5rem">
        <div style="font-family:var(--font-h);font-size:.72rem;font-weight:800;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,.3);margin-bottom:1rem;display:flex;align-items:center;gap:.5rem">
            <span style="color:var(--cyan)">+</span> Nuevo usuario
        </div>
        <form method="POST" style="display:flex;gap:.7rem;flex-wrap:wrap;align-items:flex-end">
            <input type="hidden" name="accion" value="crear">
            <div><label style="font-family:var(--font-h);font-size:.58rem;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,.2);display:block;margin-bottom:.3rem">Nombre</label>
                <input type="text" name="nombre" class="inp-sm" required placeholder="Nombre completo"></div>
            <div><label style="font-family:var(--font-h);font-size:.58rem;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,.2);display:block;margin-bottom:.3rem">Email</label>
                <input type="email" name="email" class="inp-sm" required placeholder="email@ejemplo.com"></div>
            <div><label style="font-family:var(--font-h);font-size:.58rem;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,.2);display:block;margin-bottom:.3rem">Contraseña</label>
                <input type="password" name="password" class="inp-sm" required placeholder="Mín. 8 caracteres"></div>
            <div><label style="font-family:var(--font-h);font-size:.58rem;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,.2);display:block;margin-bottom:.3rem">Rol</label>
                <select name="rol" class="inp-sm" style="width:auto">
                    <option value="editor">Editor</option>
                    <option value="auditor">Auditor</option>
                    <option value="superadmin">Superadmin</option>
                </select></div>
            <button type="submit" class="btn-primario">Crear usuario</button>
        </form>
    </div>

    
    <div style="font-family:var(--font-h);font-size:.62rem;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,.2);margin-bottom:.8rem">
        <?= count($usuarios) ?> usuario<?= count($usuarios)!==1?'s':'' ?> registrado<?= count($usuarios)!==1?'s':'' ?>
    </div>

    <?php foreach($usuarios as $u): ?>
    <div class="gu-card" style="<?= !$u['activo']?'opacity:.5':'' ?>">
        <div class="gu-avatar"><?= strtoupper($u['nombre'][0]) ?></div>
        <div class="gu-info">
            <div class="gu-nombre"><?= htmlspecialchars($u['nombre']) ?></div>
            <div class="gu-email"><?= htmlspecialchars($u['email']) ?></div>
            <div class="gu-acceso">Último acceso: <?= $u['ultimo_acceso'] ? date('d/m/Y H:i', strtotime($u['ultimo_acceso'])) : 'Nunca' ?></div>
        </div>
        <div style="display:flex;gap:.5rem;align-items:center;flex-wrap:wrap">
            <span class="badge-<?= $u['rol'] ?>"><?= ucfirst($u['rol']) ?></span>
            <?php if(!$u['activo']): ?><span class="badge-inactivo">Inactivo</span><?php endif; ?>
        </div>
        <div style="display:flex;gap:.5rem;flex-wrap:wrap;align-items:center">
            
            <form method="POST" style="display:flex;gap:.4rem;align-items:center">
                <input type="hidden" name="accion" value="cambiar_pass">
                <input type="hidden" name="id_usuario" value="<?= $u['id_usuario'] ?>">
                <input type="password" name="nueva_pass" class="inp-sm" placeholder="Nueva contraseña" style="width:160px">
                <button type="submit" class="btn-secundario" style="padding:.3rem .8rem;font-size:.72rem">Cambiar</button>
            </form>
            
            <?php if($u['id_usuario'] !== usuarioId()): ?>
            <form method="POST" style="display:flex;gap:.4rem;align-items:center">
                <input type="hidden" name="accion" value="cambiar_rol">
                <input type="hidden" name="id_usuario" value="<?= $u['id_usuario'] ?>">
                <select name="rol" class="inp-sm" style="width:auto">
                    <option value="editor"     <?= $u['rol']==='editor'?'selected':'' ?>>Editor</option>
                    <option value="auditor"    <?= $u['rol']==='auditor'?'selected':'' ?>>Auditor</option>
                    <option value="superadmin" <?= $u['rol']==='superadmin'?'selected':'' ?>>Superadmin</option>
                </select>
                <button type="submit" class="btn-secundario" style="padding:.3rem .8rem;font-size:.72rem">Cambiar rol</button>
            </form>
            <?php endif; ?>
            
            <?php if($u['id_usuario'] !== usuarioId()): ?>
            <form method="POST">
                <input type="hidden" name="accion" value="toggle">
                <input type="hidden" name="id_usuario" value="<?= $u['id_usuario'] ?>">
                <button type="submit" class="btn-secundario" style="padding:.3rem .8rem;font-size:.72rem;<?= $u['activo']?'color:#ef5350':'' ?>">
                    <?= $u['activo'] ? 'Desactivar' : 'Activar' ?>
                </button>
            </form>
            
            <form method="POST" onsubmit="return confirm('¿Seguro que quieres eliminar a <?= htmlspecialchars(addslashes($u['nombre'])) ?>? Esta acción no se puede deshacer.')">
                <input type="hidden" name="accion" value="eliminar">
                <input type="hidden" name="id_usuario" value="<?= $u['id_usuario'] ?>">
                <button type="submit" class="btn-secundario" style="padding:.3rem .8rem;font-size:.72rem;color:#ef5350;border-color:rgba(239,83,80,.3)">
                    Eliminar
                </button>
            </form>
            <?php endif; ?>
        </div>
    </div>
    <?php endforeach; ?>
</div>
</body>
</html>