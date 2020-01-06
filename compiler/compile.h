 /* Andrew Boring       */
 /* CSc 453             */
 /* Prof. Saumya Debray */
 /* Program  4a         */

typedef enum {INTEGER, CHARACTER, NA, BOOL, VOID2} Type;

typedef enum {GLOBAL, LOCAL} Scope;

typedef enum {DEFINED, UNDEFINED} Def;

typedef enum {
   ADD,
   SUB,
   MUL,
   DIV,
   UMINUS,
   CONST,
   ID2,
   CALL,
   LAND,
   LOR,
   NOT,
   EQUAL,
   NEQUAL,
   LTEQ,
   LT,
   GTEQ,
   GT,
   PARAM,
   ENTER,
   LEAVE,
   ASSIGN,
   IFELSE,
   fLOOP,
   fCOND,
   wLOOP,
   RET
} Op;

               /* CALL is also allowed */
//typedef enum {ASSIGN, IFELSE, fLOOP, fCOND, wLOOP, RET} StmtOp;

typedef struct symTable {
   char *id;
   Type type;
   struct symTable *next;
   int isFunc;
   int hasRet;
   Def def;
   struct paramList *params;
   int isExtern;
   Scope scope;
   int depth;
   int isParam;
} symTabNode;

typedef struct paramList {
   char *id;
   Type type;
   struct paramList *next;
} paramNode;

typedef struct funcList {
   char *id;
   struct paramList *params;
   struct funcList *next;
} funcNode;

typedef struct expression {
   Type type;
   Op op;
   int val;	// should only have value in constants
   struct expression *left;
   struct expression *right;
   struct symTable *sym;
   struct expression *next;

   struct symTable *place;
   struct instruction *code;
} exprNode;

typedef struct statement {
   Op op;
   struct expression *expr1;
   struct expression *expr2;
   struct statement *st1;
   struct statement *st2;
   struct statement *next;

   struct symTable *place;
   struct instruction *code;
} stmtNode;

typedef struct instruction {
   Op op;
   struct symTable *dest;
   struct symTable *src1;
   struct symTable *src2;
   struct instruction *prev;
   struct instruction *next;
   int val;
} instrNode;


symTabNode* makeSymTabNode(Type type, char *id);
symTabNode* findSymbol(symTabNode *table, char *id);
symTabNode* symbolLookup(char *id);

funcNode* makeFuncNode(char *id, paramNode *params);
funcNode* findLastFunc(funcNode *func);

paramNode* makeParamNode(Type type, char *id);
paramNode* findLastParam(paramNode *par);

exprNode* makeExprNode();
exprNode* findLastExpr(exprNode *ex);

exprNode* basicExprNode(Type type, int val);
exprNode* idToExpr(char *id);
exprNode* funcCallToExpr(char *id, exprNode *exprList);
exprNode* makeExpr(exprNode *left, Op op, exprNode *right);
exprNode* negateExpr(exprNode *ex);
exprNode* notExpr(exprNode *ex);
exprNode* callToExpr(char *id, exprNode *exList);

stmtNode* makeStmtNode(Op op, exprNode *ex1, exprNode *ex2, stmtNode *st1, stmtNode *st2);
stmtNode* findLastStmt(stmtNode *st);

/* TYPE CHECKING FUNCTIONS */
int intOrCharComp(Type type);
void protoTC(Type type, char *id, paramNode *par);
void compareFormalParams(char *id, paramNode *proto, paramNode *dec, int count);
void tcAssg(char *id, exprNode *ex);
void tcLiterals(char *id, exprNode *exList);
void compareLiteralParams(char *id, paramNode *par, exprNode *ex, int count);
void tcCall(char *id, exprNode *ex, Type ret);
void tcCallReturns(symTabNode *func, Type ret);
void tcReturns(stmtNode *st, Type ret, symTabNode *func);
void tcReturn(stmtNode *retStmt, Type ret, symTabNode *func);
void tcCond(exprNode *cond);

/* SYMBOL TABLE MANAGEMENT */
void addParamListToTable(paramNode *par);
void addVarListToTable(Type type, paramNode *current, Scope scope);
void addIdToLocal(Type type, paramNode *var, int isParam);
void addIdToGlobal(Type type, paramNode *var);

void addFuncListToTable(int isExtern, int type, funcNode *current);
void addFuncToTable(int isExtern, int type, funcNode *func, Def def);

/* PRINT FUNCTIONS */
void printTable(symTabNode *table);
char* opToString(Op op);

/* FREEING FUNCTIONS */
void freeTable(symTabNode *tab);
void freeParams(paramNode *par);

/* CODE GEN FUNCTIONS */
symTabNode* newTemp(Type t);
instrNode* newInstr( Op op, symTabNode *dest, symTabNode *src1, symTabNode *src2);
instrNode* findLastInstr(instrNode *n);
void codeGen( char *id, stmtNode *stmt);
void codeGen_stmt(stmtNode *stmt);
void codeGen_stmt_helper(stmtNode *stmt);
void codeGen_expr(exprNode *ex);
void codeGen_expr_helper(exprNode *ex);
void codeGen_params(exprNode *ex, int count);
void linkCode( instrNode *first, instrNode *last);
void stitchCode( stmtNode *st1, stmtNode *st2);
void introToMips();
void globalToMips(Type type, char *id);
int localStackSize();
void intermediateToMips( instrNode *in);
