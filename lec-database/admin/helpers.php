<?php

function callSP(PDO $pdo, string $sql, array $params = []): array {
    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $data = $stmt->fetchAll();
        while ($stmt->nextRowset()) { }
        return $data;
    } catch (Exception $e) {
        error_log("callSP error [$sql]: " . $e->getMessage());
        return [];
    }
}


function execSP(PDO $pdo, string $sql, array $params = []): void {
    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        while ($stmt->nextRowset()) {}
    } catch (Exception $e) {
        error_log("execSP error [$sql]: " . $e->getMessage());
    }
}