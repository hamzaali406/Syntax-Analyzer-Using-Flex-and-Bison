%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern FILE* yyin;
extern char* yytext;
extern int line_num;

void yyerror(const char* s);

int error_count = 0;
FILE* error_file = NULL;

%}

%union {
    char* strval;
}

/* TOKEN DECLARATIONS - MUST MATCH LEXER */
%token START END SHOW IFX ELSEX LOOP INTX FLOATX STRX
%token <strval> IDENTIFIER NUMBER STRING
%token ASSIGN PLUS MINUS MULT DIVIDE EQ NE LT GT LE GE AND OR
%token LBRACE RBRACE LPAREN RPAREN SEMICOLON

%type <strval> expr

%left OR
%left AND
%left EQ NE LT GT LE GE
%left PLUS MINUS
%left MULT DIVIDE

%%

program: START stmts END 
    { 
        printf("Program parsed successfully.\n"); 
    }
    ;

stmts: /* empty */
    | stmts stmt
    ;

stmt: var_decl SEMICOLON 
    { printf("Declaration\n"); }
    | assign SEMICOLON 
    { printf("Assignment\n"); }
    | if_stmt 
    { printf("Conditional\n"); }
    | output SEMICOLON 
    { printf("Output\n"); }
    | LBRACE stmts RBRACE 
    { printf("Block\n"); }
    | error SEMICOLON 
    { yyerrok; }
    ;

var_decl: INTX IDENTIFIER 
    { printf("  int %s\n", $2); free($2); }
    | FLOATX IDENTIFIER 
    { printf("  float %s\n", $2); free($2); }
    | STRX IDENTIFIER 
    { printf("  string %s\n", $2); free($2); }
    | INTX IDENTIFIER ASSIGN expr 
    { printf("  int %s = ...\n", $2); free($2); if($4) free($4); }
    | FLOATX IDENTIFIER ASSIGN expr 
    { printf("  float %s = ...\n", $2); free($2); if($4) free($4); }
    | STRX IDENTIFIER ASSIGN expr 
    { printf("  string %s = ...\n", $2); free($2); if($4) free($4); }
    ;

assign: IDENTIFIER ASSIGN expr 
    { printf("  %s = ...\n", $1); free($1); if($3) free($3); }
    ;

if_stmt: IFX LPAREN expr RPAREN stmt 
    { printf("  If statement\n"); }
    | IFX LPAREN expr RPAREN stmt ELSEX stmt 
    { printf("  If-else statement\n"); }
    ;

output: SHOW LPAREN expr RPAREN
    { printf("  Output expression\n"); if($3) free($3); }
    | SHOW LPAREN STRING RPAREN 
    { printf("  Print: %s\n", $3); free($3); }
    ;

expr: IDENTIFIER { $$ = $1; }
    | NUMBER { $$ = $1; }
    | STRING { $$ = $1; }
    | expr PLUS expr { printf("  Expression: +\n"); free($1); free($3); $$ = NULL; }
    | expr MINUS expr { printf("  Expression: -\n"); free($1); free($3); $$ = NULL; }
    | expr MULT expr { printf("  Expression: *\n"); free($1); free($3); $$ = NULL; }
    | expr DIVIDE expr { printf("  Expression: /\n"); free($1); free($3); $$ = NULL; }
    | expr EQ expr { printf("  Expression: ==\n"); free($1); free($3); $$ = NULL; }
    | expr LT expr { printf("  Expression: <\n"); free($1); free($3); $$ = NULL; }
    | LPAREN expr RPAREN { $$ = $2; }
    ;

%%

void yyerror(const char* s) {
    error_count++;
    
    if (!error_file) {
        error_file = fopen("errors.txt", "w");
        if (error_file) {
            fprintf(error_file, "================================\n");
            fprintf(error_file, "MiniX++ Error Report\n");
            fprintf(error_file, "================================\n");
        }
    }
    
    if (error_file) {
        fprintf(error_file, "✗ Line %d: %s\n", line_num, s);
        fprintf(error_file, "   Token: '%s'\n", yytext);
        fprintf(error_file, "\n");
    }
    
    fprintf(stderr, "Error at line %d: %s\n", line_num, s);
    fprintf(stderr, "  Token: '%s'\n", yytext);
}

int main(int argc, char** argv) {
    FILE* output_file = fopen("output.txt", "w");
    
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            printf("Cannot open file: %s\n", argv[1]);
            return 1;
        }
    } else {
        printf("Usage: %s <file.mxpp>\n", argv[0]);
        return 1;
    }
    
    printf("MiniX++ Parser\n");
    printf("==============\n");
    
    if (yyparse() == 0) {
        printf("\nParsing completed.\n");
    }
    
    if (error_file) {
        fprintf(error_file, "\n================================\n");
        fprintf(error_file, "Total Errors: %d\n", error_count);
        fprintf(error_file, "================================\n");
        fclose(error_file);
    } else if (error_count == 0) {
        error_file = fopen("errors.txt", "w");
        if (error_file) {
            fprintf(error_file, "No errors found.\n");
            fclose(error_file);
        }
    }
    
    if (output_file) {
        fprintf(output_file, "Parsing completed with %d errors.\n", error_count);
        fclose(output_file);
    }
    
    fclose(yyin);
    return (error_count > 0);
}