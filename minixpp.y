%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

extern int yylex(void);
extern FILE* yyin;
extern char* yytext;
extern int line_num;

void yyerror(const char* s);

FILE* output_file = NULL;
FILE* error_file = NULL;
int error_count = 0;
int warning_count = 0;

void open_output_files() {
    time_t now = time(NULL);
    struct tm* tm_info = localtime(&now);
    char time_str[20];
    strftime(time_str, 20, "%b %d %Y", tm_info);
    
    output_file = fopen("output.txt", "w");
    if (output_file) {
        fprintf(output_file, "================================\n");
        fprintf(output_file, "MiniX++ Parser Output\n");
        fprintf(output_file, "================================\n");
        fprintf(output_file, "Generated: %s\n", time_str);
        fprintf(output_file, "\n");
    }
    
    error_file = fopen("errors.txt", "w");
    if (error_file) {
        fprintf(error_file, "================================\n");
        fprintf(error_file, "MiniX++ Error Report\n");
        fprintf(error_file, "================================\n");
        fprintf(error_file, "Generated: %s\n", time_str);
        fprintf(error_file, "\n");
    }
}

void close_output_files() {
    if (output_file) {
        fprintf(output_file, "\n================================\n");
        fprintf(output_file, "Analysis Summary:\n");
        fprintf(output_file, "  - Total lines: %d\n", line_num);
        fprintf(output_file, "  - Errors: %d\n", error_count);
        fprintf(output_file, "  - Warnings: %d\n", warning_count);
        if (error_count == 0) {
            fprintf(output_file, "  - Status: SUCCESS\n");
        } else {
            fprintf(output_file, "  - Status: FAILED\n");
        }
        fprintf(output_file, "================================\n");
        fclose(output_file);
    }
    
    if (error_file) {
        fprintf(error_file, "\n================================\n");
        fprintf(error_file, "Total Errors: %d\n", error_count);
        fprintf(error_file, "Total Warnings: %d\n", warning_count);
        fprintf(error_file, "================================\n");
        fclose(error_file);
    }
}
%}

%union {
    char* strval;
}

/* Token declarations - MAKE SURE ASSIGN IS HERE */
%token START END SHOW IFX ELSEX LOOP 
%token INTX FLOATX STRX 
%token <strval> IDENTIFIER NUMBER STRING
%token PLUS MINUS MULT DIVIDE ASSIGN  /* THIS LINE IS CRITICAL */
%token EQ NE LT GT LE GE AND OR
%token LBRACE RBRACE LPAREN RPAREN SEMICOLON

/* Non-terminal type declarations */
%type <strval> expr

/* Operator precedence */
%nonassoc IFX
%left OR
%left AND
%left EQ NE
%left LT GT LE GE
%left PLUS MINUS
%left MULT DIVIDE

%%

program: 
    START stmt_list END 
    { 
        if (output_file) fprintf(output_file, "✓ Program parsed successfully\n");
        printf("\n✓ Program parsed successfully\n"); 
    }
    ;

stmt_list:
    /* empty */
    | stmt_list stmt
    ;

stmt:
    var_decl SEMICOLON
    { 
        if (output_file) fprintf(output_file, "  Declaration statement\n");
        printf("  Declaration\n"); 
    }
    | assign SEMICOLON
    { 
        if (output_file) fprintf(output_file, "  Assignment statement\n");
        printf("  Assignment\n"); 
    }
    | if_stmt
    { 
        if (output_file) fprintf(output_file, "  Conditional statement\n");
        printf("  Conditional\n"); 
    }
    | output SEMICOLON
    { 
        if (output_file) fprintf(output_file, "  Output statement\n");
        printf("  Output\n"); 
    }
    | LBRACE stmt_list RBRACE
    { 
        if (output_file) fprintf(output_file, "  Block statement\n");
        printf("  Block\n"); 
    }
    | error SEMICOLON
    { 
        warning_count++;
        if (output_file) fprintf(output_file, "  [Error recovered at line %d]\n", line_num);
        printf("  [Error recovered at line %d]\n", line_num);
        yyerrok; 
    }
    ;

var_decl:
    INTX IDENTIFIER
    { 
        if (output_file) fprintf(output_file, "    Declared integer: %s\n", $2);
        printf("    int %s\n", $2); 
        free($2); 
    }
    | FLOATX IDENTIFIER
    { 
        if (output_file) fprintf(output_file, "    Declared float: %s\n", $2);
        printf("    float %s\n", $2); 
        free($2); 
    }
    | STRX IDENTIFIER
    { 
        if (output_file) fprintf(output_file, "    Declared string: %s\n", $2);
        printf("    string %s\n", $2); 
        free($2); 
    }
    | INTX IDENTIFIER ASSIGN expr  /* USING ASSIGN TOKEN HERE */
    { 
        if (output_file) fprintf(output_file, "    Declared & initialized integer: %s = %s\n", $2, $4 ? $4 : "expr");
        printf("    int %s = ...\n", $2); 
        free($2); 
        if ($4) free($4);
    }
    | FLOATX IDENTIFIER ASSIGN expr  /* ADD THIS FOR FLOAT INITIALIZATION */
    { 
        if (output_file) fprintf(output_file, "    Declared & initialized float: %s = %s\n", $2, $4 ? $4 : "expr");
        printf("    float %s = ...\n", $2); 
        free($2); 
        if ($4) free($4);
    }
    | STRX IDENTIFIER ASSIGN expr  /* ADD THIS FOR STRING INITIALIZATION */
    { 
        if (output_file) fprintf(output_file, "    Declared & initialized string: %s = %s\n", $2, $4 ? $4 : "expr");
        printf("    string %s = ...\n", $2); 
        free($2); 
        if ($4) free($4);
    }
    ;

assign:
    IDENTIFIER ASSIGN expr  /* USING ASSIGN TOKEN HERE */
    { 
        if (output_file) fprintf(output_file, "    Assignment to: %s = %s\n", $1, $3 ? $3 : "expr");
        printf("    %s = ...\n", $1); 
        free($1); 
        if ($3) free($3);
    }
    ;

if_stmt:
    IFX LPAREN expr RPAREN stmt %prec IFX
    { 
        if (output_file) fprintf(output_file, "    If statement\n");
        printf("    If statement\n"); 
    }
    | IFX LPAREN expr RPAREN stmt ELSEX stmt %prec IFX
    { 
        if (output_file) fprintf(output_file, "    If-else statement\n");
        printf("    If-else statement\n"); 
    }
    ;

output:
    SHOW LPAREN expr RPAREN
    { 
        if (output_file) fprintf(output_file, "    Output expression: %s\n", $3 ? $3 : "expr");
        printf("    Output expression\n"); 
        if ($3) free($3);
    }
    | SHOW LPAREN STRING RPAREN
    { 
        if (output_file) fprintf(output_file, "    Output string: %s\n", $3);
        printf("    Print: %s\n", $3); 
        free($3); 
    }
    ;

expr:
    IDENTIFIER
    { $$ = $1; }
    | NUMBER
    { $$ = $1; }
    | STRING
    { $$ = $1; }
    | expr PLUS expr
    { 
        if (output_file) fprintf(output_file, "    Expression: addition\n");
        printf("    Expression: +\n"); 
        free($1); free($3); 
        $$ = NULL; 
    }
    | expr MINUS expr
    { 
        if (output_file) fprintf(output_file, "    Expression: subtraction\n");
        printf("    Expression: -\n"); 
        free($1); free($3); 
        $$ = NULL; 
    }
    | expr MULT expr
    { 
        if (output_file) fprintf(output_file, "    Expression: multiplication\n");
        printf("    Expression: *\n"); 
        free($1); free($3); 
        $$ = NULL; 
    }
    | expr DIVIDE expr
    { 
        if (output_file) fprintf(output_file, "    Expression: division\n");
        printf("    Expression: /\n"); 
        free($1); free($3); 
        $$ = NULL; 
    }
    | expr EQ expr
    { 
        if (output_file) fprintf(output_file, "    Expression: equality\n");
        printf("    Expression: ==\n"); 
        free($1); free($3); 
        $$ = NULL; 
    }
    | expr NE expr
    { 
        if (output_file) fprintf(output_file, "    Expression: inequality\n");
        printf("    Expression: !=\n"); 
        free($1); free($3); 
        $$ = NULL; 
    }
    | expr LT expr
    { 
        if (output_file) fprintf(output_file, "    Expression: less than\n");
        printf("    Expression: <\n"); 
        free($1); free($3); 
        $$ = NULL; 
    }
    | expr GT expr
    { 
        if (output_file) fprintf(output_file, "    Expression: greater than\n");
        printf("    Expression: >\n"); 
        free($1); free($3); 
        $$ = NULL; 
    }
    | expr LE expr
    { 
        if (output_file) fprintf(output_file, "    Expression: less or equal\n");
        printf("    Expression: <=\n"); 
        free($1); free($3); 
        $$ = NULL; 
    }
    | expr GE expr
    { 
        if (output_file) fprintf(output_file, "    Expression: greater or equal\n");
        printf("    Expression: >=\n"); 
        free($1); free($3); 
        $$ = NULL; 
    }
    | expr AND expr
    { 
        if (output_file) fprintf(output_file, "    Expression: logical AND\n");
        printf("    Expression: &&\n"); 
        free($1); free($3); 
        $$ = NULL; 
    }
    | expr OR expr
    { 
        if (output_file) fprintf(output_file, "    Expression: logical OR\n");
        printf("    Expression: ||\n"); 
        free($1); free($3); 
        $$ = NULL; 
    }
    | LPAREN expr RPAREN
    { $$ = $2; }
    ;

%%

void yyerror(const char* s) {
    error_count++;
    
    if (error_file) {
        fprintf(error_file, "✗ Line %d: %s\n", line_num, s);
        if (yytext) fprintf(error_file, "   Token: '%s'\n", yytext);
        fprintf(error_file, "   Expected: Valid MiniX++ syntax\n");
        fprintf(error_file, "\n");
    }
    
    fprintf(stderr, "\n✗ Syntax error at line %d: %s\n", line_num, s);
    if (yytext) fprintf(stderr, "  Token: '%s'\n", yytext);
}

int main(int argc, char** argv) {
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            printf("Error: Cannot open file '%s'\n", argv[1]);
            return 1;
        }
    } else {
        printf("Usage: minixpp.exe <filename.mxpp>\n");
        printf("Example: minixpp.exe test.mxpp\n");
        return 1;
    }
    
    open_output_files();
    
    printf("================================\n");
    printf("MiniX++ Syntax Analyzer\n");
    printf("================================\n");
    
    if (yyparse() == 0) {
        if (error_count == 0) {
            printf("\n✓ Syntax analysis completed successfully!\n");
        } else {
            printf("\n✗ Syntax analysis completed with %d error(s)\n", error_count);
        }
    } else {
        printf("\n✗ Syntax analysis failed!\n");
    }
    
    close_output_files();
    
    if (yyin) fclose(yyin);
    
    printf("\nOutput files generated:\n");
    printf("  - output.txt  (detailed parsing log)\n");
    printf("  - errors.txt  (error report)\n");
    
    return (error_count > 0) ? 1 : 0;
}