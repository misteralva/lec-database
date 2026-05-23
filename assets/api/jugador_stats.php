<?php
header('Content-Type: application/json');
require_once __DIR__ . '/../../clases/ConexionDB.php';

$id1   = isset($_GET['id1'])   ? (int)$_GET['id1']   : 0;
$id2   = isset($_GET['id2'])   ? (int)$_GET['id2']   : 0;
$split = isset($_GET['split']) ? (int)$_GET['split']  : null;

if (!$id1 || !$id2) {
    echo json_encode(['error' => 'IDs requeridos']);
    exit;
}

$pdo = ConexionDB::getInstancia()->getConexion();

function getStats(PDO $pdo, int $idJ, ?int $idSplit): array {
    
    $stmt = $pdo->prepare('CALL sp_stats_jugador(?, ?)');
    $stmt->execute([$idJ, $idSplit]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    while ($stmt->nextRowset()) {}

    if (!$row) {
        return ['nickname' => '?', 'kda' => 0, 'kills' => 0,
                'assists' => 0, 'cs' => 0, 'wr' => 0];
    }
    $row['wr'] = $row['mapas'] > 0
        ? round($row['wins'] * 100 / $row['mapas'], 1)
        : 0;
    return $row;
}

echo json_encode([
    'j1' => getStats($pdo, $id1, $split),
    'j2' => getStats($pdo, $id2, $split),
]);