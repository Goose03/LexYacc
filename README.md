# Intérprete de Calificaciones Escolares (Lex/Yacc)

Lenguaje (`.cal`) para calcular promedios, ponderaciones y reportes de alumnos.
Implementado con **Flex** (Lex) y **Bison** (Yacc) en C.

## Compilar y ejecutar (local)

```bash
sudo apt install -y build-essential flex bison make
make
./interprete ejemplos/ejemplo1.cal
echo 'imprimir promedio(80, 90);' | ./interprete
```

## Docker

### Imagen en Docker Hub

- Repositorio: https://hub.docker.com/r/goose03/calificaciones
- Imagen: `goose03/calificaciones:1.0`

Descargar y ejecutar sin compilar nada:

```bash
docker pull goose03/calificaciones:1.0
docker run --rm goose03/calificaciones:1.0
```

Con un archivo propio (`mi_archivo.cal` en el directorio actual):

```bash
docker run --rm -v "$PWD":/datos goose03/calificaciones:1.0 /datos/mi_archivo.cal
```

Modo interactivo por entrada estándar:

```bash
echo 'imprimir promedio(80, 90);' | docker run --rm -i goose03/calificaciones:1.0 /dev/stdin
```

### Construir la imagen desde el código

```bash
docker build -t goose03/calificaciones:1.0 .
docker run --rm goose03/calificaciones:1.0
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

## Estructura del proyecto

```
.
├── Dockerfile
├── Makefile
├── README.md
├── ejemplos/   (ejemplo1.cal, ejemplo2.cal)
└── src/        (lexer.l, parser.y, ast.h)
```