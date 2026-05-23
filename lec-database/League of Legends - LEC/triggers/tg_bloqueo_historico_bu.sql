DELIMITER $$

CREATE TRIGGER tg_bloqueo_historico_bu
BEFORE UPDATE ON partido
FOR EACH ROW
BEGIN
    -- Impide modificar cualquier campo de un partido cuyo split
    -- pertenece a una temporada anterior al año actual.
    -- Usa fn_get_año_split y fn_get_split_de_fase para obtener
    -- el año del split a partir de la fase del partido.
    
   IF fn_get_año_split(fn_get_split_de_fase(OLD.id_fase))
       < YEAR(CURDATE()) THEN
       
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Seguridad: No se pueden modificar datos de temporadas pasadas.';
    END IF;
END$$

DELIMITER ;