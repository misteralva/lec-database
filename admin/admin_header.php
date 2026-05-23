<?php

?>
<header style="background:#080808;border-bottom:1px solid rgba(255,255,255,.08);padding:0 1.5rem;position:sticky;top:0;z-index:200">
    <div style="display:flex;align-items:center;height:52px;gap:1.2rem">
        <a href="panel.php" style="font-family:'Barlow Condensed',sans-serif;font-size:1rem;font-weight:900;letter-spacing:3px;text-transform:uppercase;color:#fff;text-decoration:none">
            <span style="color:var(--cyan)">⚡</span> LEC Admin
        </a>

        
        <nav style="display:flex;gap:.5rem;margin-left:.5rem">
            <?php if(esEditor()): ?>
            <a href="panel.php" style="font-family:'Barlow Condensed',sans-serif;font-size:.65rem;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;color:rgba(255,255,255,.35);text-decoration:none;padding:.25rem .6rem;border-radius:2px;<?= basename($_SERVER['PHP_SELF'])==='panel.php'?'color:#fff;':''; ?>">Panel</a>
            <a href="nuevo_partido.php" style="font-family:'Barlow Condensed',sans-serif;font-size:.65rem;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;color:rgba(255,255,255,.35);text-decoration:none;padding:.25rem .6rem;border-radius:2px">Nuevo partido</a>
            <a href="gestionar_jugadores.php" style="font-family:'Barlow Condensed',sans-serif;font-size:.65rem;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;color:rgba(255,255,255,.35);text-decoration:none;padding:.25rem .6rem;border-radius:2px">Jugadores</a>
            <?php endif; ?>
            <?php if(esSuperAdmin()): ?>
            <a href="gestionar_equipos.php" style="font-family:'Barlow Condensed',sans-serif;font-size:.65rem;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;color:rgba(255,255,255,.35);text-decoration:none;padding:.25rem .6rem;border-radius:2px">Equipos y Jugadores</a>
            <a href="gestionar_splits.php" style="font-family:'Barlow Condensed',sans-serif;font-size:.65rem;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;color:rgba(255,255,255,.35);text-decoration:none;padding:.25rem .6rem;border-radius:2px">Splits</a>
            <a href="gestionar_usuarios.php" style="font-family:'Barlow Condensed',sans-serif;font-size:.65rem;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;color:rgba(255,255,255,.35);text-decoration:none;padding:.25rem .6rem;border-radius:2px">Usuarios</a>
            <a href="auditoria.php" style="font-family:'Barlow Condensed',sans-serif;font-size:.65rem;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;color:rgba(255,255,255,.35);text-decoration:none;padding:.25rem .6rem;border-radius:2px">Auditoría</a>
            <?php endif; ?>
        </nav>

        
        <div style="margin-left:auto;display:flex;align-items:center;gap:1rem">
            <span style="font-family:'Barlow Condensed',sans-serif;font-size:.7rem;color:rgba(255,255,255,.3)">
                <?= htmlspecialchars(usuarioNombre()) ?>
                <span style="color:rgba(255,255,255,.15);font-size:.6rem"><?= usuarioRol() ?></span>
            </span>
            <a href="logout.php" style="font-family:'Barlow Condensed',sans-serif;font-size:.65rem;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;color:rgba(255,255,255,.3);text-decoration:none;padding:.3rem .7rem;border:1px solid rgba(255,255,255,.1);border-radius:2px;transition:all .15s"
               onmouseover="this.style.color='#fff';this.style.borderColor='rgba(255,255,255,.3)'"
               onmouseout="this.style.color='rgba(255,255,255,.3)';this.style.borderColor='rgba(255,255,255,.1)'">
                Cerrar sesión
            </a>
        </div>
    </div>
</header>