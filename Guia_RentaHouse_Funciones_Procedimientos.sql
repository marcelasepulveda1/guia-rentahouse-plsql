-- =====================================================================
-- Guia de ejercicios: Funciones y Procedimientos Almacenados - Renta House
-- BDY1103 Taller de Base de Datos
-- Requisito: ejecutar antes el Script de Carga Renta House.sql
-- =====================================================================

SET SERVEROUTPUT ON;

-- =====================================================================
-- EJERCICIO 1 - FUNCION FN_TOTAL_MENSUAL
-- =====================================================================

-- Creacion
CREATE OR REPLACE FUNCTION fn_total_mensual (
    p_nro_propiedad IN propiedad.nro_propiedad%TYPE
) RETURN NUMBER
IS
    v_arriendo   propiedad.valor_arriendo%TYPE;
    v_gasto      propiedad.valor_gasto_comun%TYPE;
BEGIN
    SELECT valor_arriendo,
           NVL(valor_gasto_comun, 0)
      INTO v_arriendo,
           v_gasto
      FROM propiedad
     WHERE nro_propiedad = p_nro_propiedad;

    RETURN v_arriendo + v_gasto;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- La propiedad no existe
        RETURN 0;
END fn_total_mensual;
/

-- Prueba
-- Departamentos sin amoblar (tipo 'C') con su costo mensual total
SELECT nro_propiedad,
       direccion_propiedad,
       valor_arriendo,
       valor_gasto_comun,
       fn_total_mensual(nro_propiedad) AS total_mensual
  FROM propiedad
 WHERE id_tipo_propiedad = 'C'
 ORDER BY nro_propiedad;

-- Propiedad que no existe → debe dar 0
SELECT fn_total_mensual(9999) AS total_mensual
  FROM dual;

-- =====================================================================
-- EJERCICIO 2 - FUNCION FN_CANT_PROPIEDADES
-- =====================================================================

-- Creacion
CREATE OR REPLACE FUNCTION fn_cant_propiedades (
    p_numrut_emp IN empleado.numrut_emp%TYPE
) RETURN NUMBER
IS
    v_cantidad NUMBER := 0;
BEGIN
    SELECT COUNT(*)
      INTO v_cantidad
      FROM propiedad
     WHERE numrut_emp = p_numrut_emp;

    RETURN v_cantidad;
END fn_cant_propiedades;
/

-- Prueba
-- Ejecutivos de arriendo (categoría 3) con al menos una propiedad
SELECT e.numrut_emp,
       e.nombre_emp,
       e.appaterno_emp,
       fn_cant_propiedades(e.numrut_emp) AS cant_propiedades
  FROM empleado e
 WHERE e.id_categoria_emp = 3
   AND fn_cant_propiedades(e.numrut_emp) > 0
 ORDER BY cant_propiedades DESC,
          e.numrut_emp;

-- =====================================================================
-- EJERCICIO 3 - PROCEDIMIENTO SP_REAJUSTAR_ARRIENDO
-- =====================================================================

-- Creacion
CREATE OR REPLACE PROCEDURE sp_reajustar_arriendo (
    p_nro_propiedad IN propiedad.nro_propiedad%TYPE,
    p_porcentaje    IN NUMBER
)
IS
    v_valor_anterior propiedad.valor_arriendo%TYPE;
    v_valor_nuevo    propiedad.valor_arriendo%TYPE;
BEGIN
    -- 1. Obtener el valor actual
    SELECT valor_arriendo
      INTO v_valor_anterior
      FROM propiedad
     WHERE nro_propiedad = p_nro_propiedad;

    -- 2. Calcular el nuevo valor redondeado a entero
    v_valor_nuevo := ROUND(v_valor_anterior * (1 + p_porcentaje / 100));

    -- 3. Actualizar y confirmar
    UPDATE propiedad
       SET valor_arriendo = v_valor_nuevo
     WHERE nro_propiedad = p_nro_propiedad;

    COMMIT;

    -- 4. Informar
    DBMS_OUTPUT.PUT_LINE('Propiedad: '      || p_nro_propiedad);
    DBMS_OUTPUT.PUT_LINE('Valor anterior: ' || v_valor_anterior);
    DBMS_OUTPUT.PUT_LINE('Valor nuevo: '    || v_valor_nuevo);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('La propiedad ' || p_nro_propiedad || ' no existe.');
END sp_reajustar_arriendo;
/

-- Prueba
SET SERVEROUTPUT ON;

-- Reajuste de 10% a la propiedad 1002
EXEC sp_reajustar_arriendo(1002, 10);

-- Propiedad que no existe
EXEC sp_reajustar_arriendo(9999, 10);

-- =====================================================================
-- EJERCICIO 4 - PROCEDIMIENTO SP_RESUMEN_PROPIETARIO
-- =====================================================================

-- Creacion
CREATE OR REPLACE PROCEDURE sp_resumen_propietario (
    p_numrut_prop IN propietario.numrut_prop%TYPE
)
IS
    v_nombre_completo VARCHAR2(60);
    v_costo           NUMBER;
    v_cantidad        NUMBER := 0;
    v_total           NUMBER := 0;

    -- Cursor con las propiedades del propietario, ordenadas por número
    CURSOR c_propiedades IS
        SELECT nro_propiedad,
               direccion_propiedad
          FROM propiedad
         WHERE numrut_prop = p_numrut_prop
         ORDER BY nro_propiedad;
BEGIN
    -- 1. Nombre del propietario (si no existe, salta a la excepción)
    SELECT nombre_prop || ' ' || appaterno_prop || ' ' || apmaterno_prop
      INTO v_nombre_completo
      FROM propietario
     WHERE numrut_prop = p_numrut_prop;

    DBMS_OUTPUT.PUT_LINE('Propietario: ' || v_nombre_completo);
    DBMS_OUTPUT.PUT_LINE('----------------------------------------');

    -- 2. Recorrer sus propiedades
    FOR r_prop IN c_propiedades LOOP
        v_costo    := fn_total_mensual(r_prop.nro_propiedad);  -- reutiliza la función del Ej. 1
        v_cantidad := v_cantidad + 1;
        v_total    := v_total + v_costo;

        DBMS_OUTPUT.PUT_LINE(r_prop.nro_propiedad || ' | ' ||
                             r_prop.direccion_propiedad || ' | ' ||
                             v_costo);
    END LOOP;

    -- 3. Totales
    DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Cantidad de propiedades: ' || v_cantidad);
    DBMS_OUTPUT.PUT_LINE('Total mensual cartera: '   || v_total);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('El propietario ' || p_numrut_prop || ' no existe.');
END sp_resumen_propietario;
/

-- Prueba
SET SERVEROUTPUT ON;

-- Propietario que existe
EXEC sp_resumen_propietario(12878526);

-- Propietario que no existe
EXEC sp_resumen_propietario(11111111);
