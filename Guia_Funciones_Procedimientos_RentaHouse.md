# Guía: Funciones y Procedimientos Almacenados — Caso Renta House

**Taller de Base de Datos · BDY1103**
Marcela Sepúlveda Huircán

---

## Antes de empezar

1. Ejecuta el **Script de Carga Renta House.sql** completo (F5) para crear y poblar las tablas.
2. Activa la salida por consola (para ver los `DBMS_OUTPUT`):

```sql
SET SERVEROUTPUT ON;
```

3. Haz los ejercicios **en orden**. El 4 usa la función del 1. Además, el 3 cambia el arriendo de la propiedad 1002, así que si lo ejecutas antes del 1, los resultados del 1 cambian.

### Repaso rápido: ¿función o procedimiento?

| | FUNCTION | PROCEDURE |
|---|---|---|
| ¿Devuelve un valor? | **Sí**, siempre con `RETURN` | No (muestra o modifica cosas) |
| ¿Se puede usar dentro de un `SELECT`? | **Sí** | No |
| ¿Cómo se ejecuta? | `SELECT fn(...) FROM DUAL;` | `EXEC sp(...);` |
| Uso típico | Calcular algo | Hacer una acción (UPDATE, reportes) |

Las columnas que usamos (según el script):

- `PROPIEDAD`: `nro_propiedad`, `direccion_propiedad`, `valor_arriendo`, `valor_gasto_comun`, `id_tipo_propiedad`, `numrut_prop`, `numrut_emp`
- `PROPIETARIO`: `numrut_prop`, `nombre_prop`, `appaterno_prop`, `apmaterno_prop`
- `EMPLEADO`: `numrut_emp`, `nombre_emp`, `appaterno_emp`, `id_categoria_emp` (3 = Ejecutivo de Arriendo)

---

## Ejercicio 1 — Función `FN_TOTAL_MENSUAL`

**Qué hace:** recibe el número de una propiedad y devuelve el arriendo más el gasto común. Si el gasto común es NULL, cuenta como 0. Si la propiedad no existe, devuelve 0.

### Código de creación

```sql
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
```

**Explicación:**

- `p_nro_propiedad IN propiedad.nro_propiedad%TYPE`: el parámetro tiene el mismo tipo que la columna. Así lo pide la guía (`%TYPE`).
- `NVL(valor_gasto_comun, 0)`: si el gasto común viene en NULL, lo reemplaza por 0. Sin esto, `240000 + NULL` daría NULL.
- `SELECT ... INTO`: guarda los valores de la fila en las variables.
- `NO_DATA_FOUND`: es la excepción que Oracle lanza cuando el `SELECT INTO` no encuentra ninguna fila. Ahí devolvemos 0.

### Código de prueba

```sql
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
```

**Resultado esperado** (si todavía no ejecutas el Ejercicio 3):

| NRO_PROPIEDAD | DIRECCION_PROPIEDAD | VALOR_ARRIENDO | VALOR_GASTO_COMUN | TOTAL_MENSUAL |
|---|---|---|---|---|
| 1002 | Luis Matte 1477 | 240000 | 40000 | 280000 |
| 1005 | Vicuña Mackena 285 | 600000 | 50000 | 650000 |
| 1015 | Pablo Burchard 566 Depto. 1002 | 280000 | 35000 | 315000 |
| 1017 | Domeyko 2109 | 600000 | 90000 | 690000 |
| 1020 | San Pablo 6828 Depto. 201 BlocK. 5 | 342000 | 49000 | 391000 |

`fn_total_mensual(9999)` → **0**

---

## Ejercicio 2 — Función `FN_CANT_PROPIEDADES`

**Qué hace:** recibe el RUT de un empleado y devuelve cuántas propiedades tiene a su cargo.

### Código de creación

```sql
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
```

**Explicación:**

- `COUNT(*)` siempre devuelve una fila: si no hay propiedades, devuelve **0**. Por eso aquí **no** se produce `NO_DATA_FOUND`, y el requisito de "si no tiene propiedades, retorna 0" se cumple solo.

### Código de prueba

```sql
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
```

**Explicación:**

- La función se usa dos veces: en el `SELECT` para mostrar la cantidad y en el `WHERE` para dejar solo a quienes tienen al menos 1.
- `ORDER BY cant_propiedades DESC, e.numrut_emp`: de mayor a menor cantidad, y si hay empate, por RUT.

**Resultado esperado:**

| NUMRUT_EMP | NOMBRE_EMP | APPATERNO_EMP | CANT_PROPIEDADES |
|---|---|---|---|
| 12811094 | PAULA | MOLINA | 6 |
| 11630572 | GUSTAVO | ARAVENA | 4 |
| 11745244 | KARINA | VENEGAS | 4 |
| 12466553 | TERESA | VIDAL | 4 |
| 11649964 | MARTA | GALVEZ | 3 |
| 12456905 | JORGE | CANALES | 3 |
| 12113369 | NANCY | ROMERO | 2 |
| 12888868 | JOSE | PAEZ | 2 |

---

## Ejercicio 3 — Procedimiento `SP_REAJUSTAR_ARRIENDO`

**Qué hace:** sube el arriendo de una propiedad en un porcentaje, guarda el cambio y muestra el valor anterior y el nuevo. Si la propiedad no existe, avisa.

### Código de creación

```sql
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
```

**Explicación:**

- `1 + p_porcentaje / 100`: con 10 queda `1.10`, o sea, el valor sube un 10%.
- `ROUND(...)`: deja el resultado como número entero, sin decimales.
- Si la propiedad no existe, el `SELECT INTO` lanza `NO_DATA_FOUND` **antes** de llegar al `UPDATE`, así que no se modifica nada y se muestra el mensaje.
- `||` sirve para unir textos con números en el mensaje.

### Código de prueba

```sql
SET SERVEROUTPUT ON;

-- Reajuste de 10% a la propiedad 1002
EXEC sp_reajustar_arriendo(1002, 10);

-- Propiedad que no existe
EXEC sp_reajustar_arriendo(9999, 10);
```

**Resultado esperado:**

```
Propiedad: 1002
Valor anterior: 240000
Valor nuevo: 264000

La propiedad 9999 no existe.
```

> ⚠️ Cada vez que ejecutas el `EXEC` con la 1002, el arriendo sube otro 10% (264000 → 290400 → …), porque hay `COMMIT`. Si necesitas volver al valor original, vuelve a correr el script de carga.

---

## Ejercicio 4 — Procedimiento `SP_RESUMEN_PROPIETARIO`

**Qué hace:** con el RUT del propietario, muestra su nombre, cada una de sus propiedades con el costo mensual (usando la función del Ejercicio 1) y, al final, la cantidad de propiedades y el total.

### Código de creación

```sql
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
```

**Explicación:**

- Primero se busca el nombre del propietario. Si el RUT no existe, `NO_DATA_FOUND` salta directo al mensaje de error.
- `CURSOR c_propiedades`: es la consulta con todas sus propiedades. El `FOR r_prop IN c_propiedades LOOP` lo abre, recorre fila por fila y lo cierra automáticamente (no hace falta `OPEN`, `FETCH` ni `CLOSE`).
- En cada vuelta se llama a `fn_total_mensual`, que es la reutilización que pide la guía, y se van sumando el contador y el total.
- `v_nombre_completo VARCHAR2(60)`: alcanza para nombre (25) + apellidos (15 + 15) + espacios.

### Código de prueba

```sql
SET SERVEROUTPUT ON;

-- Propietario que existe
EXEC sp_resumen_propietario(12878526);

-- Propietario que no existe
EXEC sp_resumen_propietario(11111111);
```

**Resultado esperado:**

```
Propietario: JOHN RIQUELME CORREA
----------------------------------------
1023 | Las Acacias S/N | 800000
1024 | Los Duraznos 89 | 750000
1025 | Totoral S/N | 1340000
1026 | Bandera 458 | 300000
----------------------------------------
Cantidad de propiedades: 4
Total mensual cartera: 3190000

El propietario 11111111 no existe.
```

---

## Errores comunes

| Error | Causa | Solución |
|---|---|---|
| No aparece nada en la salida | Falta `SET SERVEROUTPUT ON` | Ejecútalo antes del `EXEC` |
| `PLS-00201: identifier 'FN_TOTAL_MENSUAL' must be declared` | Creaste el Ej. 4 antes que el Ej. 1 | Crea primero la función del Ej. 1 |
| "Compilado con errores" | Error de sintaxis | Ejecuta `SHOW ERRORS;` justo después para ver la línea |
| El total sale vacío (NULL) | No se usó `NVL` en el gasto común | Revisa el `NVL(valor_gasto_comun, 0)` |
