%code requires { #include "ast.h" }

%{
#include "ast.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <math.h>

int yylex(void);
void yyerror(const char *s);
extern int yylineno;
extern FILE *yyin;

int errores = 0;

/* ---------- Tabla de símbolos ---------- */
typedef struct Simbolo { char *nombre; double valor; struct Simbolo *sig; } Simbolo;
static Simbolo *tabla = NULL;

static Simbolo *buscar(const char *nombre, int crear) {
    for (Simbolo *s = tabla; s; s = s->sig)
        if (strcmp(s->nombre, nombre) == 0) return s;
    if (!crear) return NULL;
    Simbolo *s = calloc(1, sizeof *s);
    s->nombre = strdup(nombre);
    s->sig = tabla;
    tabla = s;
    return s;
}

/* ---------- Utilidades del AST ---------- */
static Nodo *nuevo(Tipo t, int op, Nodo *a, Nodo *b) {
    Nodo *n = calloc(1, sizeof *n);
    n->tipo = t; n->op = op; n->a = a; n->b = b; n->linea = yylineno;
    return n;
}

static Nodo *agregar(Nodo *lista, Nodo *n) {
    if (!n) return lista;
    if (!lista) return n;
    Nodo *p = lista;
    while (p->sig) p = p->sig;
    p->sig = n;
    return lista;
}

static void ejecutar(Nodo *n);
static double evaluar(Nodo *n);
%}

%union { double num; char *str; Nodo *nodo; }

%token <num> NUM
%token <str> ID CADENA
%token IMPRIMIR SI SINO MIENTRAS REPORTE AND OR NO EQ NE LE GE

%type <nodo> sentencia sentencias bloque expr item lista_imp lista_args

%define parse.error verbose

%left OR
%left AND
%right NO
%left EQ NE
%left '<' '>' LE GE
%left '+' '-'
%left '*' '/' '%'
%right UMENOS

%%

programa
    : /* vacío */
    | programa sentencia { if ($2) ejecutar($2); }
    ;

sentencia
    : ID '=' expr ';'                       { $$ = nuevo(N_ASIGNA, 0, $3, NULL); $$->str = $1; }
    | IMPRIMIR lista_imp ';'                { $$ = nuevo(N_PRINT, 0, $2, NULL); }
    | SI '(' expr ')' bloque                { $$ = nuevo(N_IF, 0, $3, $5); }
    | SI '(' expr ')' bloque SINO bloque    { $$ = nuevo(N_IF, 0, $3, $5); $$->c = $7; }
    | MIENTRAS '(' expr ')' bloque          { $$ = nuevo(N_WHILE, 0, $3, $5); }
    | REPORTE CADENA ':' lista_args ';'     { $$ = nuevo(N_REPORTE, 0, $4, NULL); $$->str = $2; }
    | error ';'                             { yyerrok; $$ = NULL; }
    ;

bloque
    : '{' sentencias '}'                    { $$ = $2; }
    ;

sentencias
    : /* vacío */                           { $$ = NULL; }
    | sentencias sentencia                  { $$ = agregar($1, $2); }
    ;

lista_imp
    : item
    | lista_imp ',' item                    { $$ = agregar($1, $3); }
    ;

item
    : expr
    | CADENA                                { $$ = nuevo(N_STR, 0, NULL, NULL); $$->str = $1; }
    ;

lista_args
    : expr
    | lista_args ',' expr                   { $$ = agregar($1, $3); }
    ;

expr
    : NUM                                   { $$ = nuevo(N_NUM, 0, NULL, NULL); $$->num = $1; }
    | ID                                    { $$ = nuevo(N_VAR, 0, NULL, NULL); $$->str = $1; }
    | ID '(' lista_args ')'                 { $$ = nuevo(N_CALL, 0, $3, NULL); $$->str = $1; }
    | expr '+' expr                         { $$ = nuevo(N_BIN, '+', $1, $3); }
    | expr '-' expr                         { $$ = nuevo(N_BIN, '-', $1, $3); }
    | expr '*' expr                         { $$ = nuevo(N_BIN, '*', $1, $3); }
    | expr '/' expr                         { $$ = nuevo(N_BIN, '/', $1, $3); }
    | expr '%' expr                         { $$ = nuevo(N_BIN, '%', $1, $3); }
    | expr '<' expr                         { $$ = nuevo(N_BIN, '<', $1, $3); }
    | expr '>' expr                         { $$ = nuevo(N_BIN, '>', $1, $3); }
    | expr LE expr                          { $$ = nuevo(N_BIN, LE, $1, $3); }
    | expr GE expr                          { $$ = nuevo(N_BIN, GE, $1, $3); }
    | expr EQ expr                          { $$ = nuevo(N_BIN, EQ, $1, $3); }
    | expr NE expr                          { $$ = nuevo(N_BIN, NE, $1, $3); }
    | expr AND expr                         { $$ = nuevo(N_BIN, AND, $1, $3); }
    | expr OR expr                          { $$ = nuevo(N_BIN, OR, $1, $3); }
    | NO expr                               { $$ = nuevo(N_NOT, 0, $2, NULL); }
    | '-' expr %prec UMENOS                 { $$ = nuevo(N_NEG, 0, $2, NULL); }
    | '(' expr ')'                          { $$ = $2; }
    ;

%%

/* ---------- Evaluación ---------- */

static void error_rt(int linea, const char *fmt, ...) {
    va_list ap;
    fprintf(stderr, "Error de ejecución (línea %d): ", linea);
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);
    fputc('\n', stderr);
    errores++;
}

static void imprimir_num(double x) {
    if (fabs(x - round(x)) < 1e-9) printf("%.0f", x);
    else printf("%.2f", x);
}

static const char *letra(double pct) {
    return pct >= 90 ? "A" : pct >= 80 ? "B" : pct >= 70 ? "C" : pct >= 60 ? "D" : "F";
}

#define MAX_ARGS 64

static int evaluar_args(Nodo *l, double *v) {
    int k = 0;
    for (; l; l = l->sig) {
        if (k >= MAX_ARGS) { error_rt(l->linea, "demasiados argumentos (máx. %d)", MAX_ARGS); break; }
        v[k++] = evaluar(l);
    }
    return k;
}

static double llamar(Nodo *n) {
    double v[MAX_ARGS];
    int k = evaluar_args(n->a, v);
    const char *f = n->str;

    if (strcmp(f, "promedio") == 0 || strcmp(f, "mayor") == 0 || strcmp(f, "menor") == 0) {
        double suma = 0, mx = v[0], mn = v[0];
        for (int i = 0; i < k; i++) {
            suma += v[i];
            if (v[i] > mx) mx = v[i];
            if (v[i] < mn) mn = v[i];
        }
        if (strcmp(f, "promedio") == 0) return suma / k;
        return strcmp(f, "mayor") == 0 ? mx : mn;
    }
    if (strcmp(f, "redondear") == 0) {
        if (k < 1 || k > 2) { error_rt(n->linea, "redondear(x) o redondear(x, decimales)"); return 0; }
        double p = pow(10, k == 2 ? v[1] : 0);
        return round(v[0] * p) / p;
    }
    if (strcmp(f, "ponderado") == 0) {
        /* ponderado(cal1, %1, cal2, %2, ...) */
        if (k < 2 || k % 2 != 0) { error_rt(n->linea, "ponderado(cal, peso, cal, peso, ...) requiere pares"); return 0; }
        double suma = 0, pesos = 0;
        for (int i = 0; i < k; i += 2) { suma += v[i] * v[i + 1]; pesos += v[i + 1]; }
        if (fabs(pesos - 100) > 1e-9)
            fprintf(stderr, "Aviso (línea %d): los pesos suman %g, no 100\n", n->linea, pesos);
        return suma / 100.0;
    }
    error_rt(n->linea, "función '%s' desconocida", f);
    return 0;
}

static double evaluar(Nodo *n) {
    switch (n->tipo) {
    case N_NUM: return n->num;
    case N_VAR: {
        Simbolo *s = buscar(n->str, 0);
        if (!s) { error_rt(n->linea, "variable '%s' no definida", n->str); return 0; }
        return s->valor;
    }
    case N_NEG: return -evaluar(n->a);
    case N_NOT: return !evaluar(n->a);
    case N_CALL: return llamar(n);
    case N_BIN: {
        if (n->op == AND) return evaluar(n->a) && evaluar(n->b);
        if (n->op == OR)  return evaluar(n->a) || evaluar(n->b);
        double x = evaluar(n->a), y = evaluar(n->b);
        switch (n->op) {
        case '+': return x + y;
        case '-': return x - y;
        case '*': return x * y;
        case '/': if (y == 0) { error_rt(n->linea, "división entre cero"); return 0; } return x / y;
        case '%': if (y == 0) { error_rt(n->linea, "módulo entre cero"); return 0; } return fmod(x, y);
        case '<': return x < y;
        case '>': return x > y;
        case LE:  return x <= y;
        case GE:  return x >= y;
        case EQ:  return x == y;
        case NE:  return x != y;
        }
        return 0;
    }
    default: return 0;
    }
}

static void ejecutar_lista(Nodo *l) {
    for (; l; l = l->sig) ejecutar(l);
}

static void ejecutar(Nodo *n) {
    switch (n->tipo) {
    case N_ASIGNA:
        buscar(n->str, 1)->valor = evaluar(n->a);
        break;
    case N_PRINT:
        for (Nodo *i = n->a; i; i = i->sig) {
            if (i->tipo == N_STR) printf("%s", i->str);
            else imprimir_num(evaluar(i));
            if (i->sig) putchar(' ');
        }
        putchar('\n');
        break;
    case N_IF:
        if (evaluar(n->a)) ejecutar_lista(n->b);
        else ejecutar_lista(n->c);
        break;
    case N_WHILE: {
        long it = 0;
        while (evaluar(n->a)) {
            if (++it > 1000000) { error_rt(n->linea, "ciclo excede 1,000,000 de iteraciones"); break; }
            ejecutar_lista(n->b);
        }
        break;
    }
    case N_REPORTE: {
        double v[MAX_ARGS];
        int k = evaluar_args(n->a, v);
        Simbolo *sc = buscar("escala", 0), *sm = buscar("minimo", 0);
        double escala = sc ? sc->valor : 100, minimo = sm ? sm->valor : 60;
        double suma = 0;
        printf("=== Reporte: %s ===\nCalificaciones:", n->str);
        for (int i = 0; i < k; i++) {
            if (v[i] < 0 || v[i] > escala)
                fprintf(stderr, "Aviso (línea %d): calificación %g fuera de rango 0-%g\n", n->linea, v[i], escala);
            printf(" "); imprimir_num(v[i]);
            suma += v[i];
        }
        double prom = suma / k;
        printf("\nPromedio: %.2f | Letra: %s | Estado: %s\n\n",
               prom, letra(prom * 100.0 / escala), prom >= minimo ? "APROBADO" : "REPROBADO");
        break;
    }
    default: break;
    }
}

void yyerror(const char *s) {
    fprintf(stderr, "Error de sintaxis (línea %d): %s\n", yylineno, s);
    errores++;
}

int main(int argc, char **argv) {
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) { perror(argv[1]); return 1; }
    }
    buscar("minimo", 1)->valor = 60;   /* calificación mínima aprobatoria */
    buscar("escala", 1)->valor = 100;  /* calificación máxima */
    yyparse();
    return errores ? 1 : 0;
}
