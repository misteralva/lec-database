USE LEC;

DROP PROCEDURE IF EXISTS sp_gestionar_jugador;

DELIMITER $$
CREATE PROCEDURE sp_gestionar_jugador(
    IN  p_id_jugador    INT UNSIGNED,
    IN  p_accion        VARCHAR(10),   
    IN  p_nuevo_rol     ENUM('Top','Jungle','Mid','ADC','Support'), 
    IN  p_fecha_fin     DATE,       
    IN  p_forzar        BOOLEAN,        
    OUT p_mensaje       VARCHAR(200)
)
sp_gestionar_jugador: BEGIN

    DECLARE v_id_historial          INT UNSIGNED;
    DECLARE v_rol_actual            VARCHAR(10);
    DECLARE v_es_titular            BOOLEAN;
    DECLARE v_id_split              INT UNSIGNED;
    DECLARE v_titular_exist         INT DEFAULT 0;
    DECLARE v_id_titular_anterior   INT UNSIGNED;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error interno: la operación no se pudo completar.';
    END;


    IF p_accion NOT IN ('TITULAR', 'SUPLENTE', 'ROL', 'BAJA') THEN
        SET p_mensaje = 'Error: acción no válida. Usa TITULAR, SUPLENTE, ROL o BAJA.';
        LEAVE sp_gestionar_jugador;
    END IF;

 
    SELECT jeh.id_historial_equipo, jeh.rol, jeh.es_titular
    INTO v_id_historial, v_rol_actual, v_es_titular
    FROM jugador_equipo_historial jeh
    WHERE jeh.id_jugador = p_id_jugador
      AND jeh.fecha_fin IS NULL
    LIMIT 1;

    IF v_id_historial IS NULL THEN
        SET p_mensaje = 'Error: el jugador no tiene ningún contrato activo.';
        LEAVE sp_gestionar_jugador;
    END IF;


    IF p_accion = 'TITULAR' THEN


        SELECT COUNT(*), id_jugador
        INTO v_titular_exist, v_id_titular_anterior
        FROM jugador_equipo_historial
        WHERE id_historial_equipo = v_id_historial
          AND rol = v_rol_actual
          AND es_titular = TRUE
          AND id_jugador <> p_id_jugador
          AND fecha_fin IS NULL
        LIMIT 1;

        IF v_titular_exist > 0 AND p_forzar = FALSE THEN
            SET p_mensaje = CONCAT('Error: ya hay un titular en el rol ', v_rol_actual,
                                   '. Usa p_forzar = TRUE para bajarlo a suplente.');
            LEAVE sp_gestionar_jugador;
        END IF;

        START TRANSACTION;
    
            IF v_titular_exist > 0 AND p_forzar = TRUE THEN
                UPDATE jugador_equipo_historial
                SET es_titular = FALSE
                WHERE id_jugador = v_id_titular_anterior
                  AND id_historial_equipo = v_id_historial
                  AND fecha_fin IS NULL;
            END IF;
        
            UPDATE jugador_equipo_historial
            SET es_titular = TRUE
            WHERE id_jugador = p_id_jugador AND fecha_fin IS NULL;
        COMMIT;

        SET p_mensaje = CONCAT('Jugador ', p_id_jugador, ' puesto como titular correctamente.');


    ELSEIF p_accion = 'SUPLENTE' THEN

        START TRANSACTION;
            UPDATE jugador_equipo_historial
            SET es_titular = FALSE
            WHERE id_jugador = p_id_jugador AND fecha_fin IS NULL;
        COMMIT;

        SET p_mensaje = CONCAT('Jugador ', p_id_jugador, ' puesto como suplente correctamente.');


    ELSEIF p_accion = 'ROL' THEN

        IF p_nuevo_rol IS NULL THEN
            SET p_mensaje = 'Error: debes indicar el nuevo rol.';
            LEAVE sp_gestionar_jugador;
        END IF;


        IF v_es_titular = TRUE THEN
            SELECT COUNT(*) INTO v_titular_exist
            FROM jugador_equipo_historial
            WHERE id_historial_equipo = v_id_historial
              AND rol = p_nuevo_rol
              AND es_titular = TRUE
              AND id_jugador <> p_id_jugador
              AND fecha_fin IS NULL;

            IF v_titular_exist > 0 THEN
                SET p_mensaje = CONCAT('Error: ya hay un titular en el rol ', p_nuevo_rol, '.');
                LEAVE sp_gestionar_jugador;
            END IF;
        END IF;

        START TRANSACTION;
            UPDATE jugador_equipo_historial
            SET rol = p_nuevo_rol
            WHERE id_jugador = p_id_jugador AND fecha_fin IS NULL;
        COMMIT;

        SET p_mensaje = CONCAT('Rol del jugador ', p_id_jugador, ' cambiado a ', p_nuevo_rol, '.');


    ELSEIF p_accion = 'BAJA' THEN

        IF p_fecha_fin IS NULL THEN
            SET p_mensaje = 'Error: debes indicar la fecha de fin del contrato.';
            LEAVE sp_gestionar_jugador;
        END IF;

  
        SET v_id_split = fn_get_split_de_historial(v_id_historial);

        IF fn_split_en_curso(v_id_split) THEN
            SET p_mensaje = 'Error: no se puede dar de baja a un jugador durante el split (regla LEC).';
            LEAVE sp_gestionar_jugador;
        END IF;

        START TRANSACTION;
         
            UPDATE jugador_equipo_historial
            SET fecha_fin = p_fecha_fin
            WHERE id_jugador = p_id_jugador AND fecha_fin IS NULL;
        COMMIT;

        SET p_mensaje = CONCAT('Jugador ', p_id_jugador, ' dado de baja correctamente.');

    END IF;

END$$
DELIMITER ;
