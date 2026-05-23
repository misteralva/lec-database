<?php
require_once __DIR__ . '/Config.php';

class ConexionDB
{
    private static array $instancias = [];
    private PDO $pdo;

    private function __construct(string $tipo)
    {
        $useRoles = Config::bool('DB_USE_ROLES');

        if ($useRoles) {
            $user = Config::get('DB_USER_' . strtoupper($tipo));
            $pass = Config::get('DB_PASS_' . strtoupper($tipo));
        } else {
            $user = Config::get('DB_USER');
            $pass = Config::get('DB_PASS');
        }

        $dsn = sprintf(
            'mysql:host=%s;port=%s;dbname=%s;charset=%s',
            Config::get('DB_HOST'),
            Config::get('DB_PORT'),
            Config::get('DB_NAME'),
            Config::get('DB_CHARSET')
        );

        try {
            $this->pdo = new PDO($dsn, $user, $pass, [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => true,
            ]);
        } catch (PDOException $e) {
            error_log("Error BD [{$tipo}@{$user}]: " . $e->getMessage());
            throw new RuntimeException("No se pudo conectar a la base de datos.");
        }
    }

    public static function getInstancia(string $tipo = 'readonly'): self
    {
        $useRoles = Config::bool('DB_USE_ROLES');
        $key      = $useRoles ? $tipo : 'default';

        if (!isset(self::$instancias[$key])) {
            self::$instancias[$key] = new self($useRoles ? $tipo : 'default');
        }

        return self::$instancias[$key];
    }

    public function getConexion(): PDO { return $this->pdo; }
    private function __clone() {}
    public function __wakeup(): void { throw new RuntimeException("No serializable."); }
}