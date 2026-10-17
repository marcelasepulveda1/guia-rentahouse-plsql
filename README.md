# Guía: Funciones y Procedimientos Almacenados en PL/SQL — Caso Renta House

**Taller de Base de Datos · BDY1103 · Duoc UC**

Solución de la guía de ejercicios sobre funciones (`FUNCTION`) y procedimientos almacenados (`PROCEDURE`) en Oracle PL/SQL, usando el modelo de datos del caso **Renta House**.

## Archivos

| Archivo | Contenido |
|---|---|
| `Guia_RentaHouse_Funciones_Procedimientos.sql` | Código de creación y de prueba de los 4 ejercicios, listo para ejecutar en SQL Developer |
| `Guia_Funciones_Procedimientos_RentaHouse.md` | Explicación paso a paso de cada ejercicio con los resultados esperados |

## Ejercicios

| # | Objeto | Tipo | Qué hace |
|---|---|---|---|
| 1 | `FN_TOTAL_MENSUAL` | Función | Arriendo + gasto común de una propiedad (NULL = 0; si no existe, retorna 0) |
| 2 | `FN_CANT_PROPIEDADES` | Función | Cantidad de propiedades a cargo de un empleado |
| 3 | `SP_REAJUSTAR_ARRIENDO` | Procedimiento | Reajusta el arriendo en un % y muestra el valor anterior y el nuevo |
| 4 | `SP_RESUMEN_PROPIETARIO` | Procedimiento | Lista las propiedades de un propietario y el total mensual de su cartera (reutiliza `FN_TOTAL_MENSUAL`) |

## Cómo ejecutar

1. Ejecutar el **Script de Carga Renta House.sql** (entregado por el docente).
2. Abrir `Guia_RentaHouse_Funciones_Procedimientos.sql` en SQL Developer y asignar la conexión.
3. Ejecutar en orden: `SET SERVEROUTPUT ON;` y luego cada bloque de creación (F5) y su prueba.
