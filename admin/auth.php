<?php

const ROLES = ['auditor' => 1, 'editor' => 2, 'superadmin' => 3];

function auth(string $rolMinimo = 'editor'): void
{
    $logueado = isset($_SESSION['admin_logueado']) && $_SESSION['admin_logueado'] === true;

    if (!$logueado) {
        header('Location: login.php'); exit;
    }


    if (!isset($_SESSION['usuario_rol'])) {
        $_SESSION['usuario_rol'] = 'superadmin';
    }

    $rolActual = $_SESSION['usuario_rol'] ?? 'editor';
    $nivelActual  = ROLES[$rolActual]  ?? 0;
    $nivelMinimo  = ROLES[$rolMinimo]  ?? 0;

    if ($nivelActual < $nivelMinimo) {
        $_SESSION['mensaje'] = 'No tienes permisos para acceder a esa sección.';
        $_SESSION['tipo']    = 'error';

        header('Location: ' . (esAuditor() ? 'auditoria.php' : 'panel.php'));
        exit;
    }
}

function esSuperAdmin(): bool {
    return ($_SESSION['usuario_rol'] ?? '') === 'superadmin';
}

function esEditor(): bool {
    $rol = $_SESSION['usuario_rol'] ?? '';
    return $rol === 'editor' || $rol === 'superadmin';
}

function esAuditor(): bool {
    return ($_SESSION['usuario_rol'] ?? '') === 'auditor';
}

function usuarioNombre(): string {
    return $_SESSION['usuario_nombre'] ?? 'Admin';
}

function usuarioRol(): string {
    return $_SESSION['usuario_rol'] ?? 'editor';
}


function usuarioId(): int {
    return (int)($_SESSION['usuario_id'] ?? 0);
}