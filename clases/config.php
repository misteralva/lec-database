<?php

class Config
{
    private static array $vars   = [];
    private static bool  $loaded = false;

    public static function load(): void
    {
        if (self::$loaded) return;

        $path = dirname(__DIR__) . '/.env';

        if (!file_exists($path)) {
            throw new RuntimeException(
                "Archivo .env no encontrado en la raíz del proyecto."
            );
        }

        foreach (file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
            $line = trim($line);
            if ($line === '' || str_starts_with($line, '#')) continue;
            if (!str_contains($line, '=')) continue;
            [$key, $value] = explode('=', $line, 2);
            self::$vars[trim($key)] = trim($value);
        }

        self::$loaded = true;
    }

    public static function get(string $key): string
    {
        if (!self::$loaded) self::load();

        if (!array_key_exists($key, self::$vars)) {
            throw new RuntimeException(
                "Variable '$key' no encontrada en el .env"
            );
        }

        return self::$vars[$key];
    }

    public static function bool(string $key): bool
    {
        return in_array(strtolower(self::get($key)), ['true', '1', 'yes', 'on']);
    }
}