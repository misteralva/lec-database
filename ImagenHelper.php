<?php

class ImagenHelper
{
    
    private const BASE = __DIR__ . '/assets/img/';
  
    private const URL  = 'assets/img/';

   
    public static function slug(string $nombre): string
    {
        $nombre = mb_strtolower(trim($nombre));
        $nombre = str_replace(' ', '_', $nombre);
        // Quitar caracteres especiales
        $nombre = preg_replace('/[^a-z0-9_]/', '', $nombre);
        return $nombre;
    }

   
    public static function logoEquipo(string $equipo): string
    {
        $slug = self::slug($equipo);
        foreach (['webp', 'png', 'jpg'] as $ext) {
            $ruta = self::BASE . "equipos/{$slug}/logo.{$ext}";
            if (file_exists($ruta)) {
                return self::URL . "equipos/{$slug}/logo.{$ext}";
            }
        }
        return self::placeholder('placeholder_logo');
    }

    
    public static function fondoEquipo(string $equipo): string
    {
        $slug = self::slug($equipo);
        foreach (['webp', 'jpg', 'png'] as $ext) {
            $ruta = self::BASE . "equipos/{$slug}/fondo.{$ext}";
            if (file_exists($ruta)) {
                return self::URL . "equipos/{$slug}/fondo.{$ext}";
            }
        }
        return self::placeholder('placeholder_fondo');
    }

   
    public static function fotoJugador(string $nickname, string $equipo): string
    {
        $slugJugador = self::slug($nickname);
        $slugEquipo  = self::slug($equipo);

        foreach (['webp', 'png', 'jpg'] as $ext) {
            $ruta = self::BASE . "jugadores/{$slugEquipo}/{$slugJugador}.{$ext}";
            if (file_exists($ruta)) {
                return self::URL . "jugadores/{$slugEquipo}/{$slugJugador}.{$ext}";
            }
        }

        return self::placeholder('placeholder_jugador');
    }

   
    private static function placeholder(string $nombre): string
    {
        foreach (['webp', 'png', 'jpg'] as $ext) {
            if (file_exists(self::BASE . "{$nombre}.{$ext}")) {
                return self::URL . "{$nombre}.{$ext}";
            }
        }
        return self::URL . "{$nombre}.png";
    }

    
    public static function colorEquipo(string $equipo): string
    {
        $colores = [
            'g2_esports'     => '#1428a0',
            'fnatic'         => '#ff5900',
            'team_vitality'  => '#eeff00',
            'karmine_corp'   => '#00d4ff',
            'natus_vincere'  => '#f5a623',
            'giantx'         => '#00b4d8',
            'movistar_koi'   => '#00c4cc',
            'sk_gaming'      => '#cc0000',
            'shifters'       => '#00cc66',
            'team_heretics'  => '#8b00ff',
        ];

        $slug = self::slug($equipo);
        return $colores[$slug] ?? '#c89b3c';
    }
   
    public static function iconoRol(string $rol, string $base = ''): string
    {
        $slug = strtolower(trim($rol));

        
        $searchDir = __DIR__ . '/assets/img/roles/';

        $found = null;
        foreach (['svg','png','jpg','webp'] as $ext) {
            foreach ([$slug, ucfirst($slug), strtoupper($slug)] as $name) {
                if (file_exists($searchDir . $name . '.' . $ext)) {
                    $found = $base . 'assets/img/roles/' . $name . '.' . $ext;
                    break 2;
                }
            }
        }

        $title = htmlspecialchars($rol);
        if ($found) {
            return '<span class="rol rol-' . $slug . '" title="' . $title . '">'
                 . '<img src="' . htmlspecialchars($found) . '" alt="' . $title . '">'
                 . '</span>';
        }

       
        $letras = ['top'=>'T','jungle'=>'J','mid'=>'M','adc'=>'A','support'=>'S'];
        $letra  = $letras[$slug] ?? strtoupper($slug[0] ?? '?');
        return '<span class="rol rol-' . $slug . ' rol-letra" title="' . $title . '">'
             . $letra
             . '</span>';
    }


}