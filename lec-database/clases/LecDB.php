<?php
require_once __DIR__ . '/ConexionDB.php';

class LecDB
{
    private static function pdo(): PDO
    {
        return ConexionDB::getInstancia()->getConexion();
    }

    private static function call(string $sp, array $params = []): array
    {
        $pdo  = self::pdo();
        $stmt = $pdo->prepare($sp);
        $stmt->execute($params);
        $data = $stmt->fetchAll();
        while ($stmt->nextRowset()) {}
        return $data;
    }


    public static function listarClasificacion(int $año): array
    {
        return self::call('CALL sp_listar_clasificacion(?)', [$año]);
    }

    public static function listarSplits(?bool $soloAbiertos = null): array
    {
        return self::call('CALL sp_listar_splits(?)', [$soloAbiertos]);
    }

    public static function listarPartidos(
        ?int    $idSplit     = null,
        ?bool   $finalizado  = null,
        ?int    $año         = null,
        ?string $splitNombre = null
    ): array {
        return self::call('CALL sp_listar_partidos(?, ?, ?, ?)', [$idSplit, $finalizado, $año, $splitNombre]);
    }

    public static function listarEquipos(
        ?int    $idSplit     = null,
        ?int    $año         = null,
        ?string $splitNombre = null
    ): array {
        return self::call('CALL sp_listar_equipos(?, ?, ?)', [$idSplit, $año, $splitNombre]);
    }

    public static function listarJugadoresEquipo(
        int     $idEquipo,
        ?int    $idSplit     = null,
        ?int    $año         = null,
        ?string $splitNombre = null
    ): array {
        return self::call('CALL sp_listar_jugadores_equipo(?, ?, ?, ?)', [$idEquipo, $idSplit, $año, $splitNombre]);
    }

    public static function buscarJugador(
        ?string $nickname     = null,
        ?string $nacionalidad = null,
        ?string $rol          = null
    ): array {
        return self::call('CALL sp_buscar_jugador(?, ?, ?)', [$nickname, $nacionalidad, $rol]);
    }

    public static function listarAños(): array
    {
        return self::call('CALL sp_listar_años()');
    }

    public static function listarFasesPorSplit(int $idSplit): array
    {
        return self::call('CALL sp_listar_fases_split(?)', [$idSplit]);
    }

    public static function listarHistorialesPorSplit(int $idSplit): array
    {
        return self::call('CALL sp_listar_historiales_split(?)', [$idSplit]);
    }

    public static function obtenerPartidoAdmin(int $idPartido): array|false
    {
        $rows = self::call('CALL sp_obtener_partido_admin(?)', [$idPartido]);
        return $rows[0] ?? false;
    }

    public static function detallePartido(int $idPartido): array
    {
        $pdo  = self::pdo();
        $stmt = $pdo->prepare('CALL sp_detalle_partido(?)');
        $stmt->execute([$idPartido]);

        $partido = $stmt->fetchAll();
        $stmt->nextRowset();
        $mapas = $stmt->fetchAll();
        $stmt->nextRowset();
        $stats = $stmt->fetchAll();

        return [
            'partido' => $partido[0] ?? null,
            'mapas'   => $mapas,
            'stats'   => $stats,
        ];
    }


    public static function registrarPartido(
        int    $idFase,
        int    $idHistEq1,
        int    $idHistEq2,
        string $fechaHora,
        string $tipoSerie
    ): array {
        $pdo = self::pdo();
        $pdo->exec('SET @id_partido = NULL, @mensaje = NULL');
        $stmt = $pdo->prepare('CALL sp_registrar_partido(?, ?, ?, ?, ?, @id_partido, @mensaje)');
        $stmt->execute([$idFase, $idHistEq1, $idHistEq2, $fechaHora, $tipoSerie]);
        $r = $pdo->query('SELECT @id_partido AS id, @mensaje AS mensaje')->fetch();
        return ['ok' => $r['id'] !== null, 'id' => $r['id'], 'mensaje' => $r['mensaje']];
    }

    public static function actualizarResultado(int $idPartido, int $mapasEq1, int $mapasEq2): array
    {
        $pdo = self::pdo();
        $pdo->exec('SET @mensaje = NULL');
        $stmt = $pdo->prepare('CALL sp_actualizar_resultado(?, ?, ?, @mensaje)');
        $stmt->execute([$idPartido, $mapasEq1, $mapasEq2]);
        $r  = $pdo->query('SELECT @mensaje AS mensaje')->fetch();
        $ok = str_contains($r['mensaje'] ?? '', 'Error') === false;
        return ['ok' => $ok, 'mensaje' => $r['mensaje']];
    }

    public static function eliminarPartido(int $idPartido, bool $forzar = false): array
    {
        $pdo = self::pdo();
        $pdo->exec('SET @mensaje = NULL');
        $stmt = $pdo->prepare('CALL sp_eliminar_partido(?, ?, @mensaje)');
        $stmt->execute([$idPartido, $forzar]);
        $r  = $pdo->query('SELECT @mensaje AS mensaje')->fetch();
        $ok = str_contains($r['mensaje'] ?? '', 'Error') === false;
        return ['ok' => $ok, 'mensaje' => $r['mensaje']];
    }

    public static function insertarEquipo(
        string  $nombre,
        string  $pais,
        ?string $fundacion   = null,
        ?int    $año         = null,
        ?string $splitNombre = null
    ): array {
        $pdo = self::pdo();
        $pdo->exec('SET @id_equipo = NULL, @mensaje = NULL');
        $stmt = $pdo->prepare('CALL sp_insertar_equipo(?, ?, ?, ?, ?, @id_equipo, @mensaje)');
        $stmt->execute([$nombre, $pais, $fundacion, $año, $splitNombre]);
        $r = $pdo->query('SELECT @id_equipo AS id, @mensaje AS mensaje')->fetch();
        return ['ok' => $r['id'] !== null, 'id' => $r['id'], 'mensaje' => $r['mensaje']];
    }

    public static function registrarEquipoSplit(int $idEquipo, int $idSplit): array
    {
        $pdo = self::pdo();
        $pdo->exec('SET @id_historial = NULL, @mensaje = NULL');
        $stmt = $pdo->prepare('CALL sp_registrar_equipo_split(?, ?, @id_historial, @mensaje)');
        $stmt->execute([$idEquipo, $idSplit]);
        $r = $pdo->query('SELECT @id_historial AS id, @mensaje AS mensaje')->fetch();
        return ['ok' => $r['id'] !== null, 'id' => $r['id'], 'mensaje' => $r['mensaje']];
    }

    public static function gestionarJugador(
        int     $idJugador,
        string  $accion,
        ?string $nuevoRol = null,
        ?string $fechaFin = null,
        bool    $forzar   = false
    ): array {
        $pdo = self::pdo();
        $pdo->exec('SET @mensaje = NULL');
        $stmt = $pdo->prepare('CALL sp_gestionar_jugador(?, ?, ?, ?, ?, @mensaje)');
        $stmt->execute([$idJugador, $accion, $nuevoRol, $fechaFin, $forzar]);
        $r  = $pdo->query('SELECT @mensaje AS mensaje')->fetch();
        $ok = str_contains($r['mensaje'] ?? '', 'Error') === false;
        return ['ok' => $ok, 'mensaje' => $r['mensaje']];
    }

    public static function ficharJugador(
        string $nickname,
        string $nombreReal,
        string $nacionalidad,
        string $fechaNac,
        string $rol,
        int    $idHistorial,
        bool   $esTitular,
        string $fechaInicio
    ): array {
        $pdo = self::pdo();
        $pdo->exec('SET @id_jugador = NULL, @mensaje = NULL');
        $stmt = $pdo->prepare('CALL sp_fichar_jugador(?, ?, ?, ?, ?, ?, ?, ?, @id_jugador, @mensaje)');
        $stmt->execute([$nickname, $nombreReal, $nacionalidad, $fechaNac, $rol, $idHistorial, $esTitular, $fechaInicio]);
        $r = $pdo->query('SELECT @id_jugador AS id, @mensaje AS mensaje')->fetch();
        return ['ok' => $r['id'] !== null, 'id' => $r['id'], 'mensaje' => $r['mensaje']];
    }
}