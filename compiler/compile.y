%{
# include <stdio.h>
# include <stdlib.h>
# include <string.h>
# include "compile.h"
extern int yylineno;
extern char *yytext;
int exitStatus = 0;

int tempNum = 1;
int aligned = 1;
int dotData = 0;
int paramCount = 0;

symTabNode *gloTable;
symTabNode *locTable;

%}

%union {
   int iVal;
   char* idName;
   int type;
   int op;
   exprNode *expr;
   paramNode *par;
   funcNode *func;
   stmtNode *stmt;
}

 /* won't report conflicts unless != 1 */
%expect 1

 /* tokens */
%token EXT <idName>ID VOID
%token CHAR INT
%token IF ELSE
%token WHILE FOR RETURN
%token INTCON CHARCON
%token INC DEC AND OR
%token EQU NEQ LTE GTE 

%left OR
%left AND
%left EQU NEQ
%left '<' LTE '>' GTE
%left '+' '-'
%left '*' '/'
%right '!'
%nonassoc INC DEC

%type <iVal>INTCON CHARCON
%type <type>type
%type <op> arithop relop logical_op
%type <expr> expr incdec_expr expr_list opt_expr
%type <par> parm_list parm_types var_dcl
%type <func> func_dcl
%type <stmt> stmt stmtS loop_stmt opt_update callret_stmt update_stmt
%%

prog		:
		| prog dcl
		| prog func
		| prog error
		;

dcl		: type var_dcl ';'		{ addVarListToTable($1,$2,GLOBAL); } 
		| EXT type func_dcl ';'		{ addFuncListToTable(1,$2,$3); }
		| type func_dcl ';'		{ addFuncListToTable(0,$1,$2); }
		| EXT VOID func_dcl ';'		{ addFuncListToTable(1,VOID2,$3); }
		| VOID func_dcl ';'		{ addFuncListToTable(0,VOID2,$2); }
		;

var_dcl		: ID			{ $$ = makeParamNode(NA,$1); }
		| var_dcl ',' ID	{ $$ = $1; findLastParam($1)->next = makeParamNode(NA,$3); }
		;

func_dcl	: ID '(' parm_types ')'				{ $$ = makeFuncNode($1, $3); }
		| func_dcl ',' ID '(' parm_types ')'		{ $$ = $1; findLastFunc($1)->next = makeFuncNode($3, $5); }

type		: CHAR		{ $$ = CHARACTER; }
		| INT		{ $$ = INTEGER; }
		;

parm_list	: type ID			{ $$ = makeParamNode($1, $2); }
		| parm_list ',' type ID		{ $$ = $1; findLastParam($1)->next = makeParamNode($3,$4); }

parm_types	: VOID				{ $$ = NULL; }
		| parm_list			{ $$ = $1; }
		;

func		: type ID '(' parm_types ')' '{' { protoTC($1, $2, $4);
						   addFuncToTable(0, $1, makeFuncNode($2, $4),DEFINED);
						   paramCount = 0; 
						   addParamListToTable($4); } func_var_dcls 
										{ //printf("\n%s locals:\n", $2);
                                                                                  //printTable(locTable); printf("\n"); 
										} 
									      stmtS '}' 
										{ tcReturns($10, $1, findSymbol(gloTable,$2));
										  if ( findSymbol(gloTable,$2)->hasRet == 0 ){
      										     fprintf(stderr,"Line %d: Function must return a value.\n", yylineno);
      										     exitStatus = 1; }
										  codeGen($2, $10);
										  freeTable(locTable); locTable = NULL; 
										}
		| VOID ID '(' parm_types ')' '{' { protoTC(VOID2, $2, $4);
						   addFuncToTable(0, VOID2, makeFuncNode($2, $4),DEFINED);
						   paramCount = 0;
						   addParamListToTable($4); } func_var_dcls 
										{ //printf("\n%s locals:\n", $2);
                                                                                  //printTable(locTable); printf("\n"); 
										}
									      stmtS '}'	
										{ tcReturns($10, VOID2, findSymbol(gloTable,$2));
										  codeGen($2, $10);
										  freeTable(locTable); locTable = NULL; 
										}
		;

func_var_dcls	:					
		| func_var_dcls type var_dcl ';'		{ addVarListToTable($2,$3,LOCAL); }

stmtS		:						{ $$ = NULL; }
		| stmtS stmt					{ if ($1 == NULL){ $$ = $2; } else { $$ = $1; findLastStmt($1)->next = $2; } }
		| stmtS error
		;

stmt		: IF '(' expr ')' stmt				{ $$ = makeStmtNode(IFELSE, $3, NULL, $5, NULL); tcCond($3); }
		| IF '(' expr ')' stmt ELSE stmt		{ $$ = makeStmtNode(IFELSE, $3, NULL, $5, $7); tcCond($3); }
		| loop_stmt					{ $$ = $1; }
		| update_stmt ';'				{ $$ = $1; }
		| callret_stmt ';'				{ $$ = $1; }
		| '{' stmtS '}'					{ $$ = $2; }
		| ';'						{ $$ = NULL; }
		;

loop_stmt	: WHILE '(' expr ')' stmt					{ $$ = makeStmtNode(wLOOP, $3, NULL, $5, NULL); tcCond($3); }
		| WHILE error stmt						{ ; }
		| FOR '(' opt_update ';' opt_expr ';' opt_update ')' stmt	{ $$ = makeStmtNode(fLOOP, NULL, NULL, makeStmtNode(fCOND,$5, NULL, $3, $7), $9); 
										  tcCond($5); }
		| FOR error stmt						{ ; }
		;

opt_update	:						{ $$ = NULL; }
		| update_stmt					{ $$ = $1; }
		| error						{ $$ = NULL;; }
		;

update_stmt	: ID '=' expr					{ $$ = makeStmtNode(ASSIGN, idToExpr($1),$3, NULL, NULL); tcAssg($1, $3); }
		| incdec_expr					{ $$ = makeStmtNode(ASSIGN, $1->left, $1, NULL, NULL); }
		;

callret_stmt	: ID '(' expr_list ')'				{ $$ = makeStmtNode(CALL,callToExpr($1,$3),NULL,NULL,NULL); tcCall($1, $3, VOID2); }
		| RETURN opt_expr				{ $$ = makeStmtNode(RET,$2,NULL,NULL,NULL); }

opt_expr	:						{ $$ = NULL; }
		| expr						{ $$ = $1; }
		;

expr		: '-' expr 			%prec '!'	{ $$ = makeExpr($2,UMINUS,NULL); }
		| '!' expr			%prec '!'	{ $$ = makeExpr($2,NOT,NULL); }
		| expr arithop expr		%prec '+'	{ $$ = makeExpr($1, $2, $3); }
		| expr relop expr		%prec EQU	{ $$ = makeExpr($1, $2, $3); }
		| expr logical_op expr		%prec AND	{ $$ = makeExpr($1, $2, $3); }
		| incdec_expr					{ $$ = $1; }
		| ID						{ $$ = idToExpr($1); }
		| ID '(' expr_list ')'				{ $$ = callToExpr($1,$3); tcCall($1,$3,INTEGER); }
		| '(' expr ')'					{ $$ = $2; }
		| INTCON					{ $$ = basicExprNode(INTEGER, $1); }
		| CHARCON					{ $$ = basicExprNode(CHARACTER, $1); }
		| error						{ $$ = NULL; }
		;

expr_list	: 						{ $$ = NULL; }
		| expr						{ $$ = $1; }
		| expr_list ',' expr				{ $$ = $1; findLastExpr($1)->next = $3; }
		;

incdec_expr	: ID INC					{ $$ = makeExpr(idToExpr($1),ADD,basicExprNode(INTEGER,1)); }
		| ID DEC					{ $$ = makeExpr(idToExpr($1),SUB,basicExprNode(INTEGER,1)); }
		;

arithop		: '+'		{ $$ = ADD; }
		| '-'		{ $$ = SUB; }
		| '*'		{ $$ = MUL; }
		| '/'		{ $$ = DIV; }
		;

relop		: EQU		{ $$ = EQUAL; }
		| NEQ		{ $$ = NEQUAL; }
		| LTE		{ $$ = LTEQ; }
		| '<'		{ $$ = LT; }
		| GTE		{ $$ = GTEQ; }
		| '>'		{ $$ = GT; }
		;

logical_op	: AND		{ $$ = LAND; }
		| OR		{ $$ = LOR; }
		;

%%
 /* Andrew Boring       */
 /* CSc 453             */
 /* Prof. Saumya Debray */
 /* Program  4a	   	*/

main(int argc, char **argv){
   yydebug = 0;
   introToMips();
   yyparse();
/*
   printf("Global table:\n");
   printTable(gloTable);
   printf("\n"); */
   freeTable(gloTable);
/*
   printf("Local table:\n");
   printTable(locTable);
   printf("\n");
*/
   return exitStatus;
}

yyerror(){
   if (yytext[0] == 0){
      fprintf( stderr, "Line %d: End of File found too early\n", yylineno);
   } else {
      fprintf( stderr, "Line %d: Syntax error at %s\n", yylineno, yytext);
   }
   exitStatus = 1;
}

symTabNode* makeSymTabNode(Type type, char *id){
   symTabNode *newNode;
   newNode = malloc( sizeof( symTabNode));
   if (id != NULL)
      newNode->id = strdup(id);
   newNode->type = type;
   newNode->next = NULL;
   newNode->isFunc = 0;
   newNode->hasRet = 0;
   newNode->def = UNDEFINED;
   newNode->params = NULL;
   newNode->isExtern = 0;
   newNode->isParam = 0;
   return newNode;
}

/* SYMBOL TABLE LOOKUP */
symTabNode* findSymbol(symTabNode *table, char *id){
   if (table == NULL)
      return NULL;
   if (strcmp(table->id,id) == 0)
      return table;
   return findSymbol( table->next, id);
}

// searches both local and global symbol tables.
symTabNode* symbolLookup(char *id){
   symTabNode *temp = findSymbol(locTable, id); // lookup symbol in local ST
   if (temp != NULL)
      return temp; 			// return if found
   temp = findSymbol(gloTable, id); 	// if NULL, look up in global ST
   return temp; 			// return no matter what
}

/* NODE CREATION and NODE LIST TRAVERSAL */
funcNode* makeFuncNode(char *id, paramNode *params){
   funcNode *new = malloc( sizeof( funcNode));
   new->id = strdup(id);
   new->params = params;
   new->next = NULL;
   return new;
}

funcNode* findLastFunc(funcNode *func){
   funcNode *temp = func;
   while (temp->next != NULL)
      temp = temp->next;
   return temp;
}

paramNode* makeParamNode(Type type, char *id){
   paramNode *temp = malloc( sizeof( paramNode));
   temp->id = strdup(id);
   temp->type = type;
   temp->next = NULL;
   return temp;
}

paramNode* findLastParam(paramNode *par){
   paramNode *temp = par;
   while (temp->next != NULL)
      temp = temp->next;
   return temp;
}

exprNode* makeExprNode(){
   exprNode *temp = malloc( sizeof( exprNode));
   temp->type = NA;
   temp->op = CONST;
   temp->val = 0;
   temp->left = NULL;
   temp->right = NULL;
   temp->sym = NULL;
   temp->next = NULL;

   temp->code = NULL;
   temp->place = NULL;
   return temp;
}

exprNode* findLastExpr(exprNode *ex){
   exprNode *temp = ex;
   while (temp->next != NULL)
      temp = temp->next;
   return temp;
}

exprNode* basicExprNode(Type type, int val){
   exprNode *temp = makeExprNode();
   // op defaults to CONST
   temp->type = type;
   temp->val = val;
   return temp;
}

exprNode* idToExpr(char *id){
   exprNode *new = makeExprNode();
   symTabNode *temp = symbolLookup(id);

   if (temp == NULL){
      fprintf(stderr, "Symbol \'%s\' was not declared.\n", id);
      exitStatus = 1; return new;
   }
   if (temp->isFunc){
      fprintf(stderr, "Symbol \'%s\' is not a variable.\n", id);
      exitStatus = 1; return new;
   }

   new->op = ID2;
   new->type = temp->type;      // expr has identifier's type
   new->sym = temp;		// expr has pointer to symbol table node
   return new;
}

exprNode* callToExpr(char *id, exprNode *exprList){
   symTabNode *temp = findSymbol(gloTable, id);
   exprNode *new = makeExprNode();
   new->left = exprList;

   if (temp == NULL){
      fprintf(stderr, "Identifier '%s' is undeclared\n", id);
      exitStatus = 1; return new;
   }
   
   if (!temp->isFunc){
      fprintf(stderr, "Identifier '%s' is not a function.\n", id);
      exitStatus = 1; return new;
   }
   
   new->type = temp->type;
   new->op = CALL;
   new->sym = temp;
   return new;
}

exprNode* makeExpr(exprNode *left, Op op, exprNode *right){
   exprNode *new = makeExprNode();
   new->left = left;
   new->op = op;
   new->right = right;
  
   switch (op) {
      case ADD:
      case SUB:
      case MUL:
      case DIV:
      case UMINUS:
         new->type = INTEGER;
         if ( !intOrCharComp(left->type) || !intOrCharComp(right->type) ){
            fprintf(stderr, "Line %d: subexpressions '%s' must be compatible with int.\n", yylineno, opToString(op));
            exitStatus = 1;
         }
         break;
      case EQUAL:
      case NEQUAL:
      case LTEQ:
      case LT:
      case GTEQ:
      case GT:
         new->type = BOOL;
         if ( !intOrCharComp(left->type) || !intOrCharComp(right->type) ){
            fprintf(stderr, "Line %d: subexpressions for '%s' must be compatile with int.\n", yylineno, opToString(op));
            exitStatus = 1;
         }
         break;
      case LAND:
      case LOR:
      case NOT:
         new->type = BOOL;
         if ( left->type != BOOL || ( right != NULL && right->type != BOOL) ){
            fprintf(stderr, "Line %d: subexpression for '%s' must be compatible with bool.\n", yylineno, opToString(op));
            exitStatus = 1;
         }
         break;
      default:
         break; 
   } 


   // figure out type
   return new;
}

stmtNode* makeStmtNode(Op op, exprNode *ex1, exprNode *ex2, stmtNode *st1, stmtNode *st2){
   stmtNode *temp = malloc( sizeof( stmtNode));
   temp->op = op;
   temp->expr1 = ex1;
   temp->expr2 = ex2;
   temp->st1 = st1;
   temp->st2 = st2;
   temp->next = NULL;
   return temp;
}

stmtNode* findLastStmt(stmtNode *st){
   stmtNode *temp = st;
   while (temp->next != NULL)
      temp = temp->next;
   return temp;
}

/* TYPE CHECKING FUNCTIONS */

int intOrCharComp(Type type){
   switch (type){
      case INTEGER:
      case CHARACTER:
      case NA:
         return 1;
      case BOOL:
      case VOID2:
         return 0;
   }
}

void protoTC(Type type, char *id, paramNode *par){
   symTabNode *temp = findSymbol(gloTable, id);
   if (temp == NULL || !temp->isFunc || temp->def == DEFINED)
      return;

   if (temp->type != type){
      fprintf(stderr, "Function '%s's return type must match it's prototype.\n", id);
      exitStatus = 1;
   }
   compareFormalParams(id, temp->params, par, 1);
}

void compareFormalParams(char *id, paramNode *proto, paramNode *dec, int count){
   if ((proto == NULL && dec != NULL) || (proto != NULL && dec == NULL)){
      fprintf(stderr, "Function '%s' has a different amount of args than it's prototype.\n", id);
      exitStatus = 1; return;
   }

   if (proto == NULL && dec == NULL)
      return;

   if (proto->type != dec->type) {
      fprintf(stderr, "Arg %d's type in function '%s' does not match it's prototype.\n", count, id);
      exitStatus = 1;
   }
   compareFormalParams(id, proto->next, dec->next, count + 1);
}

void tcAssg(char *id, exprNode *ex){
   symTabNode *temp = symbolLookup(id);
   if (temp == NULL){
      fprintf(stderr, "Identifier '%s' is undeclared\n", id);
      exitStatus = 1; return;
   }
   
   if (temp->isFunc){
      fprintf(stderr, "Identifier '%s' is a function and cannot be assigned to.\n", id);
      exitStatus = 1; return;
   }

   if ( !intOrCharComp(ex->type) ){
      fprintf(stderr, "Expression is incompatible with 'int' / 'char'.\n");
      exitStatus = 1;
   }
}

void compareLiteralParams(char *id, paramNode *par, exprNode *ex, int count){
   if ((par == NULL && ex != NULL) || (par != NULL && ex == NULL)){
      fprintf(stderr,"Function call for '%s' has a different amount of args than it's definition.\n",id);
      return;
   }

   if ( par == NULL && ex == NULL)
      return;

   if ( !intOrCharComp(ex->type) ){
      if (par->type == INTEGER)
         fprintf(stderr, "Line %d: '%s' arg %d is incompatible with 'int'.\n", yylineno, id, count);
      else if (par->type == CHARACTER)
         fprintf(stderr, "Line %d: '%s' arg %d is incompatible with 'char'.\n", yylineno, id, count);
      exitStatus = 1;
   }

   compareLiteralParams(id, par->next, ex->next, count + 1);
}

void tcCall(char *id, exprNode *exList, Type ret){
   symTabNode *temp = symbolLookup(id);
   if (temp == NULL){
      fprintf(stderr, "Identifier '%s' is undeclared\n", id);
      exitStatus = 1; return;
   }

   if (!temp->isFunc){
      fprintf(stderr, "Identifier '%s' is NOT a function and cannot be called.\n", id);
      exitStatus = 1; return;
   }
   
   compareLiteralParams(id, temp->params, exList, 1); // checks param types and amount

   tcCallReturns(temp, ret); // makes sure that statment calls return void, and expr calls return something to use
}

void tcCallReturns(symTabNode *func, Type ret){
   if (func->type == NA)
      return;

   if (ret == VOID2 && func->type != VOID2){
      fprintf(stderr, "Line %d: function '%s' should return 'void'.\n", yylineno, func->id);
      exitStatus = 1;
   } else if (ret == INTEGER && !intOrCharComp(func->type) ) {
      fprintf(stderr, "Line %d: function '%s' should return an 'int' or 'char'.\n",yylineno, func->id);
      exitStatus = 1; 
   }

}

void tcReturns(stmtNode *st, Type ret, symTabNode *func){
   if (st == NULL)
      return;

   tcReturn(st, ret, func); 	// tc this statement
   tcReturns(st->st1, ret, func);
   tcReturns(st->st2, ret, func);
   tcReturns(st->next, ret, func); // recursive calls on next statement
}

void tcReturn(stmtNode *retStmt, Type ret, symTabNode *func){
   if (retStmt == NULL || retStmt->op != RET) // if there is no return statement
      return;

   if (ret == VOID2){
      if (retStmt->expr1 != NULL){ // if the return statement has no associated expression
         fprintf(stderr, "Line %d: Function shouldn't return a value.\n", yylineno);
         exitStatus = 1;
      }
      return;
   }
   else { // if return type is int or char
      if (retStmt->expr1 == NULL){ // but doesn't return a value
         fprintf(stderr, "Line %d: function must return something.\n", yylineno);
         exitStatus = 1;
      }
      else if (!intOrCharComp(retStmt->expr1->type)){ // but returns an incompatible type
         fprintf(stderr, "Line %d: return statment doesn't match return type.\n", yylineno);
         exitStatus = 1;
      }
   }
   func->hasRet = 1;
   return;
}

void tcCond(exprNode *cond){
   if (cond == NULL || cond->type == BOOL)
      return;
   fprintf(stderr, "Line %d: conditional must have type 'bool'.\n", yylineno);
   exitStatus = 1;
}

/* SYMBOL TABLE MANAGEMENT */
void addParamListToTable(paramNode *par){
   if (par == NULL)
      return;
   
   addIdToLocal(par->type, par, 1);
   paramCount++;
   addParamListToTable(par->next);
}

void addVarListToTable(Type type, paramNode *current, Scope scope){
   if (current == NULL)
      return;

   if (scope == GLOBAL)
      addIdToGlobal(type, current);
   else
      addIdToLocal(type,current, 0);
   addVarListToTable(type, current->next, scope);
}

void addIdToLocal(Type type, paramNode *var, int isParam){
   symTabNode *temp = findSymbol(locTable, var->id);
   if (temp != NULL){
      fprintf(stderr, "Identifier '%s' has already been declared locally.\n", var->id);
      exitStatus = 1; return;
   }
   temp = makeSymTabNode( type, var->id);
   if (locTable == NULL)
      temp->depth = 1;
   else
      temp->depth = locTable->depth + 1;
   temp->scope = LOCAL;
   temp->isParam = isParam;
   temp->next = locTable;
   locTable = temp;
}

void addIdToGlobal(Type type, paramNode *var){
   symTabNode *temp = findSymbol(gloTable, var->id);
   if (temp != NULL){
      fprintf(stderr, "Identifier '%s' has already been declared globally.\n", var->id);
      exitStatus = 1; return;
   }
   temp = makeSymTabNode( type, var->id);
   temp->scope = GLOBAL;
   temp->next = gloTable;
   gloTable = temp;
   globalToMips(type, var->id);
}

void addFuncListToTable(int isExtern, int type, funcNode *current){
   if (current == NULL)
      return;
   addFuncToTable(isExtern, type, current, UNDEFINED);
   addFuncListToTable(isExtern, type, current->next);
}

void addFuncToTable(int isExtern, int type, funcNode *func, Def def){
   symTabNode *temp = findSymbol(gloTable, func->id);

   /* VARIOUS TYPE CHECKS */
   if (temp != NULL){ // if ID is found in symbol table
      if ( !temp->isFunc ){ // but isn't a function
         fprintf(stderr, "Identifier '%s' is already a global variable.\n", func->id);
         exitStatus = 1;
      } 
      else if ( temp->isExtern ) { // but is EXTERN
         fprintf(stderr, "Identifier '%s' is already an externally defined function.\n", func->id);
         exitStatus = 1;
      } 
      else if ( temp->def == DEFINED ) { // but is already defined
         if ( def == UNDEFINED ) { // and trying to add via prototype
            fprintf(stderr, "Prototype for '%s' must precede its definition.\n", func->id);
         }
         else { // trying to add via definition
            fprintf(stderr, "Identifier '%s' is an already defined function.\n", func->id);
         }
         exitStatus = 1;
      }
      // here is temp->def == UNDEFINED
      else if ( def == UNDEFINED) { // in symbol table + UNDEFINED add = second prototype
         fprintf(stderr, "Identifier '%s' already has a prototype.\n", func->id);
         exitStatus = 1;
      }
      // ( def == DEFINED ) 
      else {    // just needs to be defined, add formal params
         temp->def = DEFINED;
         freeParams(temp->params);
         temp->params = func->params;
      }
      return;
   }

   /* ADD TO TABLE */
   temp = makeSymTabNode( type, func->id);
   temp->scope = GLOBAL;
   temp->next = gloTable;
   temp->isFunc = 1;
   temp->def = def;
   temp->params = func->params;
   temp->isExtern = isExtern;
   gloTable = temp;
}

/* PRINT FUNCTIONS */
void printTable(symTabNode *table){
   if (table == NULL)
      return;

   printTable(table->next);

   if (table->isFunc == 1)
      printf("function: ");

   if (table->type == CHARACTER)
      printf("char ");
   else if (table->type == INTEGER)
      printf("int ");
   else
      printf("void ");
   
   printf("%s\n", table->id);
}

char* opToString(Op op){
   switch (op){
      case ADD: return "+";
      case SUB: return "SUB";
      case UMINUS: return "UMINUS";
      case MUL: return "MUL";
      case DIV: return "DIV";
      case CONST: return "CONST";
      case ID2: return "ID2";
      case CALL: return "CALL";
      case LAND: return "LAND";
      case LOR: return "LOR";
      case NOT: return "NOT";
      case EQUAL: return "EQUAL";
      case NEQUAL: return "NEQUAL";
      case LTEQ: return "LTEQ";
      case LT: return "LT";
      case GTEQ: return "GTEQ";
      case GT: return "GT";
      case PARAM: return "PARAM";
      case ENTER: return "ENTER";
      case ASSIGN: return "ASSIGN";
      case IFELSE: return "IFELSE";
      case fLOOP: return "fLOOP";
      case fCOND: return "fCOND";
      case wLOOP: return "wLOOP";
      case RET: return "RET";
   }
   return "OP NOT FOUND";
}

/* MEMORY FREEING FUNCTIONS */
void freeTable(symTabNode *tab){
   if (tab == NULL){
      return;
   }

   freeTable(tab->next);
   free(tab->id);
   freeParams(tab->params);
   free(tab);
}

void freeParams(paramNode *par){
   if (par == NULL)
      return;

   freeParams(par->next);
   free(par);
}


/* CODE GEN FUNCTIONS */


symTabNode* newTemp(Type t){
   symTabNode *new = makeSymTabNode(t, NULL);
   new->scope = LOCAL;
   if (locTable == NULL)
      new->depth = 1;
   else
      new->depth = locTable->depth + 1;


   char buffer[15];
   char buffer2[20] = "$temp";
   sprintf(buffer, "%d", tempNum);
   tempNum++;
   strcat(buffer2, buffer);
   new->id = strdup(buffer2);

   new->next = locTable;
   locTable = new;

   return new;
}

instrNode* newInstr( Op op, symTabNode *dest ,symTabNode *src1, symTabNode *src2){
   instrNode *new = malloc( sizeof( instrNode));
   new->op = op;
   new->src1 = src1;
   new->src2 = src2;
   new->dest = dest;
   new->prev = NULL;
   new->next = NULL;
   return new;
}

instrNode* findLastInstr(instrNode* n){
   if (n == NULL)
      return NULL;

   while (n->next != NULL)
      n = n->next;
   return n; 
}

void codeGen( char *id, stmtNode *stmt){
   symTabNode *func = findSymbol(gloTable, id);
   instrNode *enterInstr = newInstr(ENTER, func, NULL, NULL);
   paramNode *par = func->params;
   while (par != NULL){
      enterInstr->val++;
      par = par->next;
   }

   instrNode *leaveInstr = newInstr(LEAVE, func, NULL, NULL);

   if (stmt == NULL){
      enterInstr->next = leaveInstr;
      intermediateToMips(enterInstr);
      return;
   }

   codeGen_stmt(stmt);

   stitchCode(stmt, stmt->next);

   if (stmt->code == NULL)
      stmt->code = leaveInstr;
   else 
      linkCode(stmt->code, leaveInstr);

   linkCode(enterInstr, stmt->code);
   stmt->code = enterInstr;

   intermediateToMips(stmt->code);
}

void codeGen_stmt(stmtNode *stmt){
   if (stmt == NULL)
      return;

   codeGen_stmt_helper(stmt);
   codeGen_stmt( stmt->next);
}

void codeGen_stmt_helper(stmtNode *stmt){
   if (stmt == NULL)
      return;

   //printf("stmt: %s\n", opToString(stmt->op));

   switch (stmt->op){
      case ASSIGN:
         codeGen_expr( stmt->expr1);
         codeGen_expr( stmt->expr2);
         codeGen_stmt_helper( stmt->st1);
         codeGen_stmt_helper( stmt->st2);
         if (stmt->expr2->code != NULL){
            stmt->code = stmt->expr2->code;
            linkCode(stmt->code, newInstr(ASSIGN, stmt->expr1->place, stmt->expr2->place, NULL));
         } else {
            stmt->code = newInstr(ASSIGN, stmt->expr1->place, stmt->expr2->place, NULL);
         }
         break;
      case IFELSE:
         break; 
      case fLOOP:
         break;
      case fCOND:
         break;
      case wLOOP:
         break;
      case RET:
         //codeGen_stmt_helper(stmt->expr1);
         break;
      case CALL:
         codeGen_expr( stmt->expr1);
         stmt->code = stmt->expr1->code;
         break;
   }   
   //printf("end stmt: %s\n", opToString(stmt->op));
}

void codeGen_expr( exprNode *ex){
   if (ex == NULL)
      return;

   codeGen_expr_helper(ex);
   codeGen_expr(ex->next);
}

void codeGen_expr_helper( exprNode *ex){
   if (ex == NULL)
      return;

   //printf("expr: %s\n", opToString(ex->op));
 
   switch (ex->op){
      case ADD:
         codeGen_expr_helper( ex->left);
         codeGen_expr_helper( ex->right);
         ex->place = newTemp(ex->type);
         ex->code = ex->left->code;
         linkCode(ex->left->code, ex->right->code);
         linkCode(ex->right->code, newInstr(ADD, ex->place, ex->left->place, ex->right->place));
         break;
      case SUB:
         codeGen_expr_helper( ex->left);
         codeGen_expr_helper( ex->right);
         ex->place = newTemp(ex->type);
         ex->code = ex->left->code;
         linkCode(ex->left->code, ex->right->code);
         linkCode(ex->right->code, newInstr(SUB, ex->place, ex->left->place, ex->right->place));
         break;
      case MUL:
         codeGen_expr_helper( ex->left);
         codeGen_expr_helper( ex->right);
         ex->place = newTemp(ex->type);
         ex->code = ex->left->code;
         linkCode(ex->left->code, ex->right->code);
         linkCode(ex->right->code, newInstr(MUL, ex->place, ex->left->place, ex->right->place));
         break;
      case DIV:
         codeGen_expr_helper( ex->left);
         codeGen_expr_helper( ex->right);
         ex->place = newTemp(ex->type);
         ex->code = ex->left->code;
         linkCode(ex->left->code, ex->right->code);
         linkCode(ex->right->code, newInstr(DIV, ex->place, ex->left->place, ex->right->place));
         break;
      case UMINUS:
         codeGen_expr_helper( ex->left);
         ex->place = newTemp(ex->type);
         ex->code = ex->left->code;
         linkCode(ex->code, newInstr(UMINUS, ex->place, ex->left->place, NULL));
         break;
      case CONST:
         //printf("%d\n", ex->val);
         ex->place = newTemp(ex->type);
         ex->code = newInstr(CONST, ex->place, NULL, NULL);
         ex->code->val = ex->val;
         break;
      case ID2:
         ex->place = ex->sym;
         ex->code = NULL;
         break;
      case CALL:
         codeGen_params(ex->left, 1);
         //linkParamCode(ex->left);
         if (ex->left != NULL){
            instrNode *new = newInstr(CALL, ex->sym, NULL, NULL);
            exprNode *left = ex->left;
            while (left != NULL){
               new->val++;
               left = left->next;
            }
            ex->code = ex->left->code;
            linkCode(ex->code, new);
         } else {
            ex->code = newInstr(CALL, ex->sym, NULL, NULL);
         }
         break;
      case LAND:
         break;
      case LOR:
         break;
      case NOT:
         break;
      case EQUAL:
         break;
      case NEQUAL:
         break;
      case LTEQ:
         break;
      case LT:
         break;
      case GTEQ:
         break;
      case GT:
         break; 
   }
   //printf("end expr: %s\n", opToString(ex->op));
}

void codeGen_params(exprNode *ex, int count){
   if (ex == NULL)
      return;
   //printf("param: %s, val =  %d\n", opToString(ex->op), ex->val);

   // generate code for each expression
   codeGen_expr_helper(ex);
   codeGen_params(ex->next, count + 1);

   instrNode *new = newInstr(PARAM, ex->place, NULL, NULL);
   new->val = count;

   if (ex->code == NULL){
      if (ex->next == NULL)
         ex->code = new;
      else {
         ex->code = ex->next->code;
         linkCode(ex->code, new);
      }
   } else {
      if (ex->next == NULL)
         linkCode(ex->code, new);
      else {
         linkCode(ex->code, ex->next->code);
         linkCode(ex->code, new);
      }
   }
   //printf("end param: %s, val =  %d\n", opToString(ex->op), ex->val);
}

void linkCode( instrNode *left, instrNode *right){
   if (left == NULL || right == NULL)
      return;
   instrNode *temp = findLastInstr(left);
   temp->next = right;
   right->prev = temp;
}

void stitchCode( stmtNode *st1, stmtNode *st2){
   if (st1 == NULL || st2 == NULL)
      return;

   linkCode(st1->code, st2->code);
   stitchCode(st2, st2->next);
}

void introToMips(){
   printf("#####################################################\n");
   printf(".data\n\n\t__newline:\t.asciiz \"\\n\"\n\t.align 2\n\n");
   printf(".text\n\n");
   printf("_println:\n");
   printf("\tli $v0, 1\n");
   printf("\tlw $a0, 0($sp)\n");
   printf("\tsyscall\n");
   printf("\tli $v0, 4\n");
   printf("\tla $a0, __newline\n");
   printf("\tsyscall\n");
   printf("\tjr $ra\n");
   printf("#####################################################\n\n");
}

void globalToMips(Type type, char *id){
   if (dotData == 0){
      printf(".data\n");
      dotData = 1;
   }
   if (type == CHARACTER){
      if (aligned == 1){
         printf("\n");
         aligned = 0;
      }
      printf("_%s:\t.space 1\n", id);
   } else { // type == INTEGER
      if (aligned == 0){
         printf("\n\t.align 2\n");
         aligned = 1;
      }
      printf("_%s:\t.space 4\n", id);
   }
}

int localStackSize(){
   symTabNode *temp = locTable;
   int n;
   while (temp != NULL){
      //printf("%s\n", temp->id);
      n++;
      temp = temp->next;
   }
   return n;
}

void intermediateToMips( instrNode *in){
   if (in == NULL)
      return;

   switch(in->op){
      case ENTER:
         if (aligned == 0){
            printf(".align 2\n");
            aligned = 1;
         }
         printf("\n");
         if (dotData == 1){
            printf(".text\n");
            dotData = 0;
         }
         printf("# enter %s\n", in->dest->id);
         int isMain = strcmp(in->dest->id, "main");
         if (isMain == 0){
            printf("%s:\n", in->dest->id);
         } else {
            printf("_%s:\n", in->dest->id);
         }
         printf("# START PROLOGUE ###########################################\n");
         printf("la $sp, -8($sp)  # Allocate space for old $fp and $ra\n");
         printf("sw $fp, 4($sp)   # Save old frame pointer\n");
         printf("sw $ra, 0($sp)   # Save return Address\n");
         printf("la $fp, 0($sp)   # Set up frame pointer\n");
         printf("la $sp, %d($sp)  # Allocate stack frame\n", (localStackSize() - in->val) * -4);
         printf("# END PROLOGUE #############################################\n\n");
         break;
      case ADD:
         printf("\n# %s = %s + %s\n", in->dest->id, in->src1->id, in->src2->id);
         break;
      case SUB:
         printf("\n# %s = %s - %s\n", in->dest->id, in->src1->id, in->src2->id);
         break;
      case MUL:
         printf("\n# %s = %s * %s\n", in->dest->id, in->src1->id, in->src2->id);
         break;
      case DIV:
         printf("\n# %s = %s / %s\n", in->dest->id, in->src1->id, in->src2->id);
         break;
      case UMINUS:
         printf("\n# %s = - %s\n", in->dest->id, in->src1->id);
         break;
      case PARAM:
         printf("\n# param %s, %d\n", in->dest->id, in->val);

         if (in->dest->scope == GLOBAL){
            printf("la $t1, _%s\n", in->dest->id);
            if (in->dest->type == INTEGER)
               printf("lw $t0, 0($t1)\n");
            else
               printf("lb $t0, 0($t1)\n");
         } else if (in->dest->type == INTEGER){
            if (in->dest->isParam)
               printf("lw $t0, %d($fp)\n", 4 * in->dest->depth + 4);
            else
               printf("lw $t0, %d($sp)\n", 4 * (in->dest->depth - paramCount) - 4);
         } else
            if (in->dest->isParam)
               printf("lb $t0, %d($fp)\n", 4 * in->dest->depth + 4);
            else
               printf("lb $t0, %d($sp)\n", 4 * (in->dest->depth - paramCount) - 4);

         printf("la $sp, -4($sp)\n");

         //if (in->dest->type == INTEGER)
            printf("sw $t0, 0($sp)\n");
         //else
           // printf("sb $t0, 0($sp)\n");

         break;
      case CONST:
         if (in->dest->type == INTEGER)
            printf("\n# %s = %d\n", in->dest->id, in->val);
         else
            printf("\n# %s = %c\n", in->dest->id, in->val);

         printf("li $t2, %d\n", in->val);

         if (in->dest->type == INTEGER)
            printf("sw $t2, %d($sp)\n", 4 * (in->dest->depth - paramCount) - 4 );
         else
            printf("sb $t2, %d($sp)\n", 4 * (in->dest->depth - paramCount) - 4 );
         break;

      case ASSIGN:
         printf("\n# %s = %s\n", in->dest->id, in->src1->id);

         if (in->src1->scope == GLOBAL && in->src1->type == INTEGER)
            printf("lw $t0, _%s\n", in->src1->id);
         else if (in->src1->scope == GLOBAL && in->src1->type == CHARACTER)
            printf("lb $t0, _%s\n", in->src1->id);
         else if (in->src1->type == INTEGER && in->src1->isParam)
            printf("lw $t0, %d($fp)\n", 4 * (in->src1->depth) + 4);
         else if (in->src1->type == INTEGER)
            printf("lw $t0, %d($sp)\n", 4 * (in->src1->depth - paramCount) - 4);
         else if (in->src1->type == CHARACTER && in->src1->isParam)
            printf("lb $t0, %d($fp)\n", 4 * (in->src1->depth) + 4);
         else
            printf("lb $t0, %d($sp)\n", 4 * (in->src1->depth - paramCount) - 4);

	 if (in->dest->scope == GLOBAL){
            printf("la $t2, _%s\n", in->dest->id);
            if (in->dest->type == INTEGER)
               printf("sw $t0, 0($t2)\n");
            else
               printf("sb $t0, 0($t2)\n");
         } else if (in->dest->type == INTEGER)
            if (in->dest->isParam)
               printf("sw $t0, %d($fp)\n", 4 * in->dest->depth + 4);
            else
               printf("sw $t0, %d($sp)\n", 4 * (in->dest->depth - paramCount) - 4);
         else
            if (in->dest->isParam)
               printf("sb $t0, %d($fp)\n", 4 * (in->dest->depth) + 4);
            else
               printf("sb $t0, %d($sp)\n", 4 * (in->dest->depth - paramCount) - 4);

         break;
      case CALL:
         printf("\n# call %s, %d\n", in->dest->id, in->val);
         printf("jal _%s\n", in->dest->id);
	 printf("la $sp, %d($sp)\n", in->val * 4);
         break;
      case LEAVE:
         printf("\n# leave %s\n", in->dest->id);
         printf("# Start EPILOGUE\n");
         printf("##############################################\n");
         printf("la $sp, 0($fp)    # Deallocate locals\n");
         printf("lw $ra, 0($sp)    # Restore return address\n");
         printf("lw $fp, 4($sp)    # Restore frame pointer\n");
         printf("la $sp, 8($sp)    # Restore stack pointer\n");
         printf("jr $ra            # Return to caller\n");
         printf("# END EPILOGUE\n");
         printf("#################################################\n\n");
         printf("# return\n");
         break;
   }
   intermediateToMips(in->next);
}
