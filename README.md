# Intérprete de Calificaciones Escolares (Lex/Yacc)

Lenguaje (`.cal`) para calcular promedios, ponderaciones y reportes de alumnos.
Implementado con **Flex** (Lex) y **Bison** (Yacc) en C.

## Compilar y ejecutar

```bash
sudo apt install -y build-essential flex bison make
make
./interprete ejemplos/ejemplo1.cal
echo 'imprimir promedio(80, 90);' | ./interprete
```

## Docker

```bash
docker build -t USUARIO/calificaciones:1.0 .
docker run --rm USUARIO/calificaciones:1.0
# con un archivo propio:
docker run --rm -v "$PWD":/datos USUARIO/calificaciones:1.0 /datos/mi_archivo.cal
```

## Referencia del lenguaje

| Elemento | Sintaxis |
|---|---|
| Comentario | `# texto` |
| Variable | `mate = 90;` |
| Imprimir | `imprimir "texto", variable, 2 + 3;` |
| Condicional | `si (cond) { ... } sino { ... }` |
| Ciclo | `mientras (cond) { ... }` |
| Reporte | `reporte "Nombre": c1, c2, c3;` |
| Operadores | `+ - * / %`, `< > <= >= == !=`, `y`, `o`, `no` |

Funciones: `promedio(...)`, `mayor(...)`, `menor(...)`, `redondear(x[, dec])`,
`ponderado(cal1, peso1, cal2, peso2, ...)` (pesos en %, deben sumar 100).

Variables predefinidas: `minimo` (60, calificación aprobatoria) y `escala` (100, calificación máxima).
`reporte` calcula promedio, letra (A-F) y estado APROBADO/REPROBADO.

## Manejo de errores

Errores léxicos (carácter inválido, cadena sin cerrar), de sintaxis (con recuperación por `;`)
y de ejecución (variable no definida, división entre cero, función desconocida, ciclo infinito).
El programa devuelve código de salida 1 si hubo errores.
