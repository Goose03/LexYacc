#ifndef AST_H
#define AST_H

typedef enum {
    N_NUM, N_STR, N_VAR, N_BIN, N_NEG, N_NOT, N_CALL,
    N_ASIGNA, N_PRINT, N_IF, N_WHILE, N_REPORTE
} Tipo;

typedef struct Nodo {
    Tipo tipo;
    int op;                 /* operador (para N_BIN) */
    double num;
    char *str;              /* nombre de variable/función o cadena */
    int linea;
    struct Nodo *a, *b, *c; /* hijos */
    struct Nodo *sig;       /* siguiente en una lista (sentencias, argumentos) */
} Nodo;

#endif
