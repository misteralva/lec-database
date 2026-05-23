<?php
session_start();
if (isset($_SESSION['admin_logueado']) && $_SESSION['admin_logueado'] === true) {
    header('Location: panel.php'); exit;
}

require_once __DIR__ . '/../clases/ConexionDB.php';
require_once __DIR__ . '/../clases/Config.php';

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $usuario = trim($_POST['usuario'] ?? '');
    $pass    = $_POST['password'] ?? '';
    $logueado = false;

    if ($usuario && $pass) {

        
        try {
            $pdo = ConexionDB::getInstancia('backend')->getConexion();
            $tablaExiste = $pdo->query("SHOW TABLES LIKE 'usuarios_admin'")->fetchColumn();

            if ($tablaExiste) {
                $stmt = $pdo->prepare("SELECT * FROM usuarios_admin WHERE (email=? OR nombre=?) AND activo=TRUE LIMIT 1");
                $stmt->execute([$usuario, $usuario]);
                $user = $stmt->fetch();

                if ($user && password_verify($pass, $user['password_hash'])) {
                    session_regenerate_id(true);
                    $_SESSION['usuario_id']     = $user['id_usuario'];
                    $_SESSION['usuario_nombre'] = $user['nombre'];
                    $_SESSION['usuario_rol']    = $user['rol'];
                    $_SESSION['admin_logueado'] = true;
                    try {
                        $pdo->prepare("UPDATE usuarios_admin SET ultimo_acceso=NOW() WHERE id_usuario=?")
                            ->execute([$user['id_usuario']]);
                    } catch (Exception $e) {}
                    $logueado = true;
                }
            }
        } catch (Exception $e) {
            
        }

        
        if (!$logueado) {
            $adminUser = Config::get('ADMIN_USER', 'admin');
            $adminPass = Config::get('ADMIN_PASS', 'password');
            if ($usuario === $adminUser && $pass === $adminPass) {
                session_regenerate_id(true);
                $_SESSION['usuario_nombre'] = 'Administrador';
                $_SESSION['usuario_rol']    = 'superadmin';
                $_SESSION['admin_logueado'] = true;
                $logueado = true;
            }
        }
    }

    if ($logueado) {
        $destino = ($_SESSION['usuario_rol'] ?? '') === 'auditor' ? 'auditoria.php' : 'panel.php';
        header("Location: $destino"); exit;
    }

    $error = 'Usuario o contraseña incorrectos.';
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Acceso — LEC Admin</title>
<link rel="stylesheet" href="../assets/css/estilo.css">
<style>
body{display:flex;align-items:center;justify-content:center;min-height:100vh;background:#000}
.box{background:#111;border:1px solid rgba(255,255,255,.08);border-radius:4px;padding:2.5rem 2rem;width:100%;max-width:380px}
.logo{text-align:center;margin-bottom:2rem;font-family:'Barlow Condensed',sans-serif;font-size:1.1rem;font-weight:900;letter-spacing:4px;text-transform:uppercase;color:#fff}
.logo em{color:var(--cyan);font-style:normal}
.lbl{font-family:var(--font-h);font-size:.62rem;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,.3);display:block;margin-bottom:.4rem}
.inp{width:100%;background:#1a1a1a;border:1px solid rgba(255,255,255,.1);color:#fff;padding:.65rem .9rem;border-radius:2px;font-size:.9rem;margin-bottom:1rem;box-sizing:border-box}
.inp:focus{outline:none;border-color:var(--cyan)}
.err{background:rgba(229,57,53,.08);border:1px solid rgba(229,57,53,.2);color:#ef5350;padding:.6rem .9rem;border-radius:2px;font-family:var(--font-h);font-size:.78rem;margin-bottom:1rem}
.btn{width:100%;padding:.75rem;font-family:'Barlow Condensed',sans-serif;font-size:.85rem;font-weight:800;letter-spacing:2px;text-transform:uppercase;background:var(--cyan);color:#000;border:none;border-radius:2px;cursor:pointer}
.btn:hover{opacity:.85}
</style>
</head>
<body>
<div class="box">
    <div class="logo"><em>⚡</em> LEC Admin</div>
    <?php if($error): ?><div class="err">⚠ <?= htmlspecialchars($error) ?></div><?php endif; ?>
    <form method="POST" autocomplete="off">
        <label class="lbl">Usuario o email</label>
        <input type="text" name="usuario" class="inp" value="<?= htmlspecialchars($_POST['usuario']??'') ?>" autofocus required>
        <label class="lbl">Contraseña</label>
        <input type="password" name="password" class="inp" required>
        <button type="submit" class="btn">Entrar</button>
    </form>
    <div style="text-align:center;margin-top:1.2rem">
        <a href="../index.php" style="font-family:var(--font-h);font-size:.65rem;color:rgba(255,255,255,.2);text-decoration:none">← Volver al sitio</a>
    </div>
</div>
</body>
</html>