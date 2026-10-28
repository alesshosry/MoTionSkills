# FASTTypeScript + MoTion Playbook (Pharo)

This document is dedicated for writing MoTion patterns to match a FASTTypeScript model. Some may want to find the if/else clause in a TypeScript file, others may need the switch case, others want specifc search... This is why you can benefit from MoTion to express the patterns you want, and use FASTTypeScript metamodel which allows representing the AST of TypeScript in Pharo. The combination of both tools, will allow you to apply any search. 

## 1) Requirements / Packages
- [FASTTypescript (metamodel + parser)](https://github.com/moosetechnology/FASTTypescript)
- [MoTion](https://github.com/alesshosry/Motion)

## 2) Parse TypeScript and get the Program node

```smalltalk
string := '// some TypeScript code'.
res := FASTTypeScriptParser new parse: string.
"res will be a FASTTypeScriptModel; we need to access the #entities inside👇🏻"

"Program entity: is the top entity of every TypeScript AST"
prog := (res entities detect: [ :ent | ent class = FASTTypeScriptProgram ]) first
"first because a collection will be returned containing only one entity of type FASTTypeScriptProgram which is the top entity".
```

## 3) Core MoTion traversal idioms

### 3.1) Recursive descent (find a node anywhere)
Use `#'children*'` from `FASTTypeScriptProgram` to search anywhere in the AST subtree.

```smalltalk
pattern := FASTTypeScriptProgram % {
  #'children*' <=> SomeNodeClass % { } as: #aNode
}.
results := pattern collectBindings: { #aNode } for: prog.
```

### 3.2) Immediate child constraint (avoid cross-product matches)
Use `#genericChildren` (no `*`) with list patterns when you need **direct** structural relationships.

```smalltalk
pattern := SomeNodeClass % {
  #genericChildren <=> { #'*_'. ChildNodeClass % { } as: #child. #'*_' }
}.
"this means you are looking for a SomeNodeClass that has direct children ChildNodeClass and possibly other children #'*_' "
```

## 4) Example patterns

### 4.1) Switch: exactly 2 cases + 1 default (via SwitchBody children)
```smalltalk
pattern := FASTTypeScriptProgram % {
  #'children*' <=> FASTTypeScriptSwitchBody % {
    #'children' <=> {
      FASTTypeScriptSwitchCase % { } as: #case1.
      FASTTypeScriptSwitchCase % { } as: #case2.
      FASTTypeScriptSwitchDefault % { } as: #default
    }
  } as: #switchStmt
}.
results := pattern collectBindings: { #switchStmt. #case1. #case2. #default } for: prog.
```

### 4.2) If/Else: direct else clause (avoids descendant cross-products)
```smalltalk
pattern := FASTTypeScriptProgram % {
  #'children*' <=> FASTTypeScriptIfStatement % {
    #genericChildren <=> {
      #'*_'.
      FASTTypeScriptElseClause % { } as: #elseClause.
      #'*_'
    }
  } as: #ifStmt
}.
results := pattern collectBindings: { #ifStmt. #elseClause } for: prog.
```

### 4.3) Try/catch: checking nested try/catch
```smalltalk
pattern := FASTTypeScriptProgram % {
  #'children*' <=> FASTTypeScriptTryStatement % {
    #'children*' <=> FASTTypeScriptTryStatement % { } as: #innerTry
  } as: #outerTry
}.

results := pattern collectBindings: { #outerTry. #innerTry } for: prog. 
```

### 4.4) Counting 3 methods in class
```smalltalk
string := 'class Example {
  methodWithInt() {
    let x: int = 10;
    console.log(x);
  }
  methodWithoutInt() {
    let name: string = "hello";
    console.log(name);
  }
}'.

res := FASTTypeScriptParser new parse: string.
prog := (res entities select: [ :ent | ent class = FASTTypeScriptProgram ]) first.
 
pattern :=  FASTTypeScriptProgram % {
	#'children*' <=> FASTTypeScriptClassBody % {
  		#'children' <=>  {  
			FASTTypeScriptMethodDefinition % {} as: #m1.
			FASTTypeScriptMethodDefinition % {} as: #m2.      
  		}.
	}. 
}.
```

### 4.5) Check if method is empty
```smalltalk
typescriptCode := '
function emptyFunction() {}

function nonEmptyFunction() {
    console.log("Hello, world!");
}

class Example {
    emptyMethod() {}
    nonEmptyMethod() {
        return 42;
    }
}
'.

parsedModel := FASTTypeScriptParser new parse: typescriptCode.
prog := (parsedModel entities select: [ :ent | ent class = FASTTypeScriptProgram ]) first.

pattern := FASTTypeScriptProgram % {
	 #'children*' <=> FASTTypeScriptMethodDefinition % {
    	#'body' <=> FASTTypeScriptStatementBlock % {
        #'children' <=> {}
		}
	}as: #emptyFunction.
}.

bindings := pattern collectBindings: { #emptyFunction } for: prog. 
```

### 4.6) Check if any function or method contain empty else and retrieve the owner
```smalltalk
str := 'function processValue(a: number) {
    if (a > 10) {
        console.log("big");
    } else { 
    }
}

class Calculator {
    compute(x: number) {
        if (x === 0) {
            return 0;
        } else {
            console.log("not zero");
        }
    }

    check(y: number) {
        if (y < 5) {
            console.log("small");
        } else { 
        }
    }
}'.

res := FASTTypeScriptParser new parse: str.
prog := (res entities select: [ :ent | ent class = FASTTypeScriptProgram ]) first.

emptyElsePattern :=
FASTTypeScriptElseClause % {        
    #children <=> FASTTypeScriptStatementBlock % { 
        #children <=> {}
    }     
} as: #emptyElse.


functionOwnerPattern :=
FASTTypeScriptProgram % {
    #'children*' <=> FASTTypeScriptFunctionDeclaration %% {
        #name <=> #'@ownerName'.
        #'body>children*' <=> emptyElsePattern
    }
}.

methodOwnerPattern :=
FASTTypeScriptProgram % {
    #'children*' <=> FASTTypeScriptMethodDefinition %% {
        #name <=> #'@ownerName'.
        #'body>children*' <=> emptyElsePattern
    }
}.

(functionOwnerPattern collectBindings: { #ownerName } for: prog).
(methodOwnerPattern collectBindings: { #ownerName } for: prog).
```

## 5) Debugging tips

### 5.1) Inspect children to learn structure
```smalltalk
node genericChildren collect: #class.
node genericChildren.
```

### 5.2) Why you got too many matches
- Using `#'genericChildren*'` matches *descendants*, producing cross-products when nested structures exist.
- Prefer `#genericChildren` when you mean “direct child”.

### 6) FASTTypeScript entities
To express a pattern efficiently, MoTion needs to know the names of the classes that represent TypeScript entities. This is why we list them here, along with the slots that can be used when writing a MoTion pattern:
```
# Metamodel: FAST-TypeScript-Model

## FASTTypeScriptAbstractClassDeclaration

- **Superclass:** `FASTTypeScriptClassDeclaration`
- **Slots:** none

## FASTTypeScriptAbstractMethodSignature

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `name`
  - `parameters`
  - `return_type`
  - `type_parameters`

## FASTTypeScriptAccessibilityModifier

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:** none

## FASTTypeScriptAddingTypeAnnotation

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `childrenNode`

## FASTTypeScriptAmbientDeclaration

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTypeScriptTDeclaration`
- **Slots:**
  - `childrenNodes`
  - `exportStatementDeclarationOwner`
  - `tWithDeclarationsDeclarationsOwner`
  - `parentLoopStatement`
  - `statementContainer`

## FASTTypeScriptArguments

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `newExpressionArgumentsOwner`

## FASTTypeScriptArray

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTypeScriptTPrimaryExpression`
- **Slots:**
  - `childrenNodes`
  - `importSpecifierNameOwner`
  - `typePredicateNameOwner`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptArrayPattern

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression + FASTTypeScriptTPattern`
- **Slots:**
  - `childrenNodes`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`
  - `assignmentPatternLeftOwner`

## FASTTypeScriptArrayType

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression + FASTTypeScriptTPrimaryType`
- **Slots:**
  - `childrenNode`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptArrowFunction

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTypeScriptTPrimaryExpression`
- **Slots:**
  - `parameter`
  - `parameters`
  - `return_type`
  - `type_parameters`
  - `importSpecifierNameOwner`
  - `typePredicateNameOwner`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptAsExpression

- **Superclass:** `FASTTypeScriptExpression`
- **Slots:**
  - `childrenNodes`

## FASTTypeScriptAsserts

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression`
- **Slots:**
  - `childrenNode`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptAssertsAnnotation

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression + FASTTypeScriptTReturnType`
- **Slots:**
  - `childrenNode`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`
  - `functionDeclarationReturnTypeOwner`

## FASTTypeScriptAssignmentExpression

- **Superclass:** `FASTTypeScriptExpression`
- **Slots:** none

## FASTTypeScriptAssignmentPattern

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `left`

## FASTTypeScriptAugmentedAssignmentExpression

- **Superclass:** `FASTTypeScriptExpression`
- **Slots:**
  - `operator`

## FASTTypeScriptAwaitExpression

- **Superclass:** `FASTTypeScriptExpression`
- **Slots:**
  - `childrenNode`

## FASTTypeScriptBinaryExpression

- **Superclass:** `FASTTypeScriptExpression`
- **Slots:**
  - `operator`

## FASTTypeScriptBoolean

- **Superclass:** `FASTTypeScriptLiteral`
- **Traits:** `FASTTBooleanLiteral`
- **Slots:** none

## FASTTypeScriptBreakStatement

- **Superclass:** `FASTTypeScriptStatement`
- **Slots:**
  - `label`

## FASTTypeScriptCallExpression

- **Superclass:** `FASTTypeScriptExpression`
- **Traits:** `FASTTypeScriptTPrimaryExpression + FASTTypeScriptTType`
- **Slots:**
  - `arguments`
  - `function`
  - `type_arguments`
  - `importSpecifierNameOwner`
  - `typePredicateNameOwner`

## FASTTypeScriptCallSignature

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `parameters`
  - `return_type`
  - `type_parameters`

## FASTTypeScriptCatchClause

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `body`
  - `parameter`
  - `tryStatementHandlerOwner`
  - `type`

## FASTTypeScriptClass

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTypeScriptTPrimaryExpression`
- **Slots:**
  - `body`
  - `decorator`
  - `name`
  - `type_parameters`
  - `importSpecifierNameOwner`
  - `typePredicateNameOwner`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptClassBody

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `classBodyOwner`
  - `classDeclarationBodyOwner`
  - `decorator`

## FASTTypeScriptClassDeclaration

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTypeScriptTDeclaration + FASTTypeScriptTWithDeclarations + FASTTypeScriptTWithModifiers`
- **Slots:**
  - `body`
  - `decorator`
  - `name`
  - `programClassDeclarationOwner`
  - `type_parameters`
  - `exportStatementDeclarationOwner`
  - `tWithDeclarationsDeclarationsOwner`
  - `parentLoopStatement`
  - `statementContainer`
  - `declarations`
  - `modifiers`

## FASTTypeScriptClassHeritage

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `childrenNodes`

## FASTTypeScriptClassStaticBlock

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `body`

## FASTTypeScriptComment

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:** none

## FASTTypeScriptCompilationUnit

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:** none

## FASTTypeScriptComputedPropertyName

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `childrenNode`

## FASTTypeScriptConditionalType

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression + FASTTypeScriptTPrimaryType`
- **Slots:**
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptConstraint

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `childrenNode`
  - `typeParameterConstraintOwner`

## FASTTypeScriptConstructSignature

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `parameters`
  - `type`
  - `type_parameters`

## FASTTypeScriptConstructorType

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression + FASTTypeScriptTType`
- **Slots:**
  - `parameters`
  - `type_parameters`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptContinueStatement

- **Superclass:** `FASTTypeScriptStatement`
- **Slots:**
  - `label`

## FASTTypeScriptDebuggerStatement

- **Superclass:** `FASTTypeScriptStatement`
- **Slots:** none

## FASTTypeScriptDecorator

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `childrenNode`
  - `classBodyDecoratorOwner`
  - `classDeclarationDecoratorOwner`
  - `classDecoratorOwner`
  - `exportStatementDecoratorOwner`
  - `optionalParameterDecoratorOwner`
  - `publicFieldDefinitionDecoratorOwner`
  - `requiredParameterDecoratorOwner`

## FASTTypeScriptDefaultType

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `childrenNode`
  - `typeParameterValueOwner`

## FASTTypeScriptDoStatement

- **Superclass:** `FASTTypeScriptStatement`
- **Slots:**
  - `condition`

## FASTTypeScriptERROR

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FamixTHasImmediateSource`
- **Slots:**
  - `source`
  - `element`

## FASTTypeScriptElseClause

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `childrenNode`
  - `ifStatementAlternativeOwner`

## FASTTypeScriptEmptyStatement

- **Superclass:** `FASTTypeScriptStatement`
- **Slots:** none

## FASTTypeScriptEntity

- **Superclass:** `MooseEntity`
- **Traits:** `FASTTEntity + FASTTWithComments + TEntityMetaLevelDependency`
- **Slots:**
  - `abstractMethodSignatureNameOwner`
  - `abstractMethodSignatureReturnTypeOwner`
  - `addingTypeAnnotationOwner`
  - `ambientDeclarationOwner`
  - `arrayOwner`
  - `arrayPatternOwner`
  - `arrayTypeOwner`
  - `arrowFunctionReturnTypeOwner`
  - `asExpressionOwner`
  - `assertsAnnotationOwner`
  - `assertsOwner`
  - `augmentedAssignmentExpressionOperatorOwner`
  - `awaitExpressionOwner`
  - `binaryExpressionOperatorOwner`
  - `callExpressionArgumentsOwner`
  - `callExpressionFunctionOwner`
  - `callSignatureReturnTypeOwner`
  - `catchClauseParameterOwner`
  - `classHeritageOwner`
  - `computedPropertyNameOwner`
  - `constraintOwner`
  - `decoratorOwner`
  - `defaultTypeOwner`
  - `elseClauseOwner`
  - `enumAssignmentNameOwner`
  - `enumBodyNameOwner`
  - `exportClauseOwner`
  - `expressionStatementOwner`
  - `flowMaybeTypeOwner`
  - `forInStatementKindOwner`
  - `forInStatementOperatorOwner`
  - `forStatementConditionOwner`
  - `forStatementIncrementOwner`
  - `forStatementInitializerOwner`
  - `functionExpressionReturnTypeOwner`
  - `functionSignatureReturnTypeOwner`
  - `generatorFunctionDeclarationReturnTypeOwner`
  - `generatorFunctionReturnTypeOwner`
  - `genericChildren`
  - `genericParent`
  - `implementsClauseOwner`
  - `importAliasOwner`
  - `importAttributeOwner`
  - `importClauseOwner`
  - `indexSignatureSignOwner`
  - `indexTypeQueryOwner`
  - `inferTypeOwner`
  - `instantiationExpressionFunctionOwner`
  - `interfaceBodyOwner`
  - `internalModuleNameOwner`
  - `intersectionTypeOwner`
  - `lexicalDeclarationKindOwner`
  - `literalTypeOwner`
  - `lookupTypeOwner`
  - `methodSignatureNameOwner`
  - `methodSignatureReturnTypeOwner`
  - `moduleNameOwner`
  - `namedImportsOwner`
  - `namespaceExportOwner`
  - `namespaceImportOwner`
  - `nestedTypeIdentifierModuleOwner`
  - `nonNullExpressionOwner`
  - `objectAssignmentPatternLeftOwner`
  - `objectOwner`
  - `objectPatternOwner`
  - `objectTypeOwner`
  - `omittingTypeAnnotationOwner`
  - `optingTypeAnnotationOwner`
  - `optionalTypeOwner`
  - `pairKeyOwner`
  - `pairPatternKeyOwner`
  - `pairPatternValueOwner`
  - `parenthesizedTypeOwner`
  - `programOwner`
  - `propertySignatureNameOwner`
  - `publicFieldDefinitionNameOwner`
  - `readonlyTypeOwner`
  - `requiredParameterNameOwner`
  - `restPatternOwner`
  - `restTypeOwner`
  - `returnStatementOwner`
  - `satisfiesExpressionOwner`
  - `sequenceExpressionOwner`
  - `spreadElementOwner`
  - `statementBlockOwner`
  - `stringOwner`
  - `switchBodyOwner`
  - `switchCaseValueOwner`
  - `templateLiteralTypeOwner`
  - `templateStringOwner`
  - `templateSubstitutionOwner`
  - `templateTypeOwner`
  - `throwStatementOwner`
  - `tupleTypeOwner`
  - `typeAnnotationOwner`
  - `typeArgumentsOwner`
  - `typeAssertionOwner`
  - `typeParametersOwner`
  - `typeQueryOwner`
  - `unaryExpressionOperatorOwner`
  - `unionTypeOwner`
  - `updateExpressionOperatorOwner`
  - `variableDeclarationOwner`
  - `variableDeclaratorNameOwner`
  - `yieldExpressionOwner`
  - `endPos`
  - `startPos`
  - `comments`

## FASTTypeScriptEnumAssignment

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `name`

## FASTTypeScriptEnumBody

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `enumDeclarationBodyOwner`
  - `name`

## FASTTypeScriptEnumDeclaration

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTypeScriptTDeclaration + FASTTypeScriptTWithDeclarations + FASTTypeScriptTWithModifiers`
- **Slots:**
  - `body`
  - `name`
  - `programEnumDeclarationOwner`
  - `exportStatementDeclarationOwner`
  - `tWithDeclarationsDeclarationsOwner`
  - `parentLoopStatement`
  - `statementContainer`
  - `declarations`
  - `modifiers`

## FASTTypeScriptEscapeSequence

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:** none

## FASTTypeScriptExistentialType

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression + FASTTypeScriptTPrimaryType`
- **Slots:**
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptExportClause

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `childrenNodes`

## FASTTypeScriptExportSpecifier

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `alias`
  - `name`

## FASTTypeScriptExportStatement

- **Superclass:** `FASTTypeScriptStatement`
- **Slots:**
  - `declaration`
  - `decorator`
  - `source`

## FASTTypeScriptExpression

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression`
- **Slots:**
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptExpressionStatement

- **Superclass:** `FASTTypeScriptStatement`
- **Traits:** `FASTTExpressionStatement`
- **Slots:**
  - `expression`

## FASTTypeScriptExtendsClause

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `type_arguments`

## FASTTypeScriptExtendsTypeClause

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:** none

## FASTTypeScriptFalse

- **Superclass:** `FASTTypeScriptBoolean`
- **Traits:** `FASTTypeScriptTPrimaryExpression`
- **Slots:**
  - `importSpecifierNameOwner`
  - `typePredicateNameOwner`

## FASTTypeScriptFinallyClause

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `body`
  - `tryStatementFinalizerOwner`

## FASTTypeScriptFlowMaybeType

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression + FASTTypeScriptTPrimaryType`
- **Slots:**
  - `childrenNode`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptForInStatement

- **Superclass:** `FASTTypeScriptStatement`
- **Slots:**
  - `body`
  - `kind`
  - `operator`

## FASTTypeScriptForStatement

- **Superclass:** `FASTTypeScriptStatement`
- **Slots:**
  - `condition`
  - `increment`
  - `initializer`

## FASTTypeScriptFormalParameters

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `abstractMethodSignatureParametersOwner`
  - `arrowFunctionParametersOwner`
  - `callSignatureParametersOwner`
  - `constructSignatureParametersOwner`
  - `constructorTypeParametersOwner`
  - `functionDeclarationParametersOwner`
  - `functionExpressionParametersOwner`
  - `functionSignatureParametersOwner`
  - `functionTypeParametersOwner`
  - `generatorFunctionDeclarationParametersOwner`
  - `generatorFunctionParametersOwner`
  - `methodDefinitionParametersOwner`
  - `methodSignatureParametersOwner`

## FASTTypeScriptFunctionDeclaration

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTypeScriptTDeclaration`
- **Slots:**
  - `body`
  - `name`
  - `parameters`
  - `return_type`
  - `type_parameters`
  - `exportStatementDeclarationOwner`
  - `tWithDeclarationsDeclarationsOwner`
  - `parentLoopStatement`
  - `statementContainer`

## FASTTypeScriptFunctionExpression

- **Superclass:** `FASTTypeScriptExpression`
- **Traits:** `FASTTypeScriptTPrimaryExpression`
- **Slots:**
  - `body`
  - `name`
  - `parameters`
  - `return_type`
  - `type_parameters`
  - `importSpecifierNameOwner`
  - `typePredicateNameOwner`

## FASTTypeScriptFunctionSignature

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTypeScriptTDeclaration`
- **Slots:**
  - `name`
  - `parameters`
  - `return_type`
  - `type_parameters`
  - `exportStatementDeclarationOwner`
  - `tWithDeclarationsDeclarationsOwner`
  - `parentLoopStatement`
  - `statementContainer`

## FASTTypeScriptFunctionType

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression + FASTTypeScriptTType`
- **Slots:**
  - `parameters`
  - `type_parameters`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptGeneratorFunction

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTypeScriptTPrimaryExpression`
- **Slots:**
  - `body`
  - `name`
  - `parameters`
  - `return_type`
  - `type_parameters`
  - `importSpecifierNameOwner`
  - `typePredicateNameOwner`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptGeneratorFunctionDeclaration

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTypeScriptTDeclaration`
- **Slots:**
  - `body`
  - `name`
  - `parameters`
  - `return_type`
  - `type_parameters`
  - `exportStatementDeclarationOwner`
  - `tWithDeclarationsDeclarationsOwner`
  - `parentLoopStatement`
  - `statementContainer`

## FASTTypeScriptGenericType

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression + FASTTypeScriptTPrimaryType`
- **Slots:**
  - `type_arguments`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptHashBangLine

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:** none

## FASTTypeScriptHtmlComment

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:** none

## FASTTypeScriptIdentifier

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression + FASTTypeScriptTOptionalField + FASTTypeScriptTPattern + FASTTypeScriptTPrimaryExpression`
- **Slots:**
  - `arrowFunctionParameterOwner`
  - `enumDeclarationNameOwner`
  - `exportSpecifierNameOwner`
  - `functionDeclarationNameOwner`
  - `functionExpressionNameOwner`
  - `functionSignatureNameOwner`
  - `generatorFunctionDeclarationNameOwner`
  - `generatorFunctionNameOwner`
  - `importSpecifierAliasOwner`
  - `indexSignatureNameOwner`
  - `nestedIdentifierObjectOwner`
  - `optionalParameterNameOwner`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`
  - `exportSpecifierAliasOwner`
  - `methodDefinitionReturnTypeOwner`
  - `requiredParameterTypeOwner`
  - `assignmentPatternLeftOwner`
  - `importSpecifierNameOwner`
  - `typePredicateNameOwner`

## FASTTypeScriptIfStatement

- **Superclass:** `FASTTypeScriptStatement`
- **Slots:**
  - `alternative`
  - `condition`
  - `consequence`

## FASTTypeScriptImplementsClause

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `childrenNodes`

## FASTTypeScriptImport

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:** none

## FASTTypeScriptImportAlias

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTypeScriptTDeclaration`
- **Slots:**
  - `childrenNodes`
  - `exportStatementDeclarationOwner`
  - `tWithDeclarationsDeclarationsOwner`
  - `parentLoopStatement`
  - `statementContainer`

## FASTTypeScriptImportAttribute

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `childrenNode`

## FASTTypeScriptImportClause

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `childrenNodes`

## FASTTypeScriptImportRequireClause

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `source`

## FASTTypeScriptImportSpecifier

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `alias`
  - `name`

## FASTTypeScriptImportStatement

- **Superclass:** `FASTTypeScriptStatement`
- **Slots:**
  - `source`

## FASTTypeScriptIndexSignature

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `name`
  - `sign`

## FASTTypeScriptIndexTypeQuery

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression + FASTTypeScriptTPrimaryType`
- **Slots:**
  - `childrenNode`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptInferType

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression + FASTTypeScriptTType`
- **Slots:**
  - `childrenNodes`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptInstantiationExpression

- **Superclass:** `FASTTypeScriptExpression`
- **Slots:**
  - `function`
  - `type_arguments`

## FASTTypeScriptInterfaceBody

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `childrenNodes`
  - `interfaceDeclarationBodyOwner`

## FASTTypeScriptInterfaceDeclaration

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTypeScriptTDeclaration + FASTTypeScriptTWithDeclarations + FASTTypeScriptTWithModifiers`
- **Slots:**
  - `body`
  - `name`
  - `programInterfaceDeclarationOwner`
  - `type_parameters`
  - `exportStatementDeclarationOwner`
  - `tWithDeclarationsDeclarationsOwner`
  - `parentLoopStatement`
  - `statementContainer`
  - `declarations`
  - `modifiers`

## FASTTypeScriptInternalModule

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression + FASTTypeScriptTDeclaration`
- **Slots:**
  - `body`
  - `name`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`
  - `exportStatementDeclarationOwner`
  - `tWithDeclarationsDeclarationsOwner`
  - `parentLoopStatement`
  - `statementContainer`

## FASTTypeScriptIntersectionType

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression + FASTTypeScriptTPrimaryType`
- **Slots:**
  - `childrenNodes`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptJsxText

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:** none

## FASTTypeScriptLabeledStatement

- **Superclass:** `FASTTypeScriptStatement`
- **Slots:**
  - `label`

## FASTTypeScriptLexicalDeclaration

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTypeScriptTDeclaration`
- **Slots:**
  - `kind`
  - `exportStatementDeclarationOwner`
  - `tWithDeclarationsDeclarationsOwner`
  - `parentLoopStatement`
  - `statementContainer`

## FASTTypeScriptLiteral

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTLiteral`
- **Slots:**
  - `primitiveValue`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptLiteralType

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression + FASTTypeScriptTPrimaryType`
- **Slots:**
  - `childrenNode`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptLookupType

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression + FASTTypeScriptTPrimaryType`
- **Slots:**
  - `childrenNodes`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptMappedTypeClause

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `name`

## FASTTypeScriptMemberExpression

- **Superclass:** `FASTTypeScriptExpression`
- **Traits:** `FASTTypeScriptTPattern + FASTTypeScriptTPrimaryExpression + FASTTypeScriptTType`
- **Slots:**
  - `optionalChain`
  - `assignmentPatternLeftOwner`
  - `importSpecifierNameOwner`
  - `typePredicateNameOwner`

## FASTTypeScriptMetaProperty

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTypeScriptTPrimaryExpression`
- **Slots:**
  - `importSpecifierNameOwner`
  - `typePredicateNameOwner`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptMethodDefinition

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `body`
  - `name`
  - `parameters`
  - `return_type`
  - `type_parameters`

## FASTTypeScriptMethodSignature

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `name`
  - `parameters`
  - `return_type`
  - `type_parameters`

## FASTTypeScriptModel

- **Superclass:** `MooseModel`
- **Traits:** `FASTTEntityCreator + FASTTypeScriptTEntityCreator`
- **Slots:** none

## FASTTypeScriptModule

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTypeScriptTDeclaration`
- **Slots:**
  - `body`
  - `name`
  - `exportStatementDeclarationOwner`
  - `tWithDeclarationsDeclarationsOwner`
  - `parentLoopStatement`
  - `statementContainer`

## FASTTypeScriptNamedImports

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `childrenNodes`

## FASTTypeScriptNamespaceExport

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `childrenNode`

## FASTTypeScriptNamespaceImport

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `childrenNode`

## FASTTypeScriptNestedIdentifier

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `object`
  - `property`

## FASTTypeScriptNestedTypeIdentifier

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression + FASTTypeScriptTPrimaryType`
- **Slots:**
  - `module`
  - `name`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptNewExpression

- **Superclass:** `FASTTypeScriptExpression`
- **Slots:**
  - `arguments`
  - `type_arguments`

## FASTTypeScriptNonNullExpression

- **Superclass:** `FASTTypeScriptExpression`
- **Traits:** `FASTTypeScriptTPattern + FASTTypeScriptTPrimaryExpression`
- **Slots:**
  - `childrenNode`
  - `assignmentPatternLeftOwner`
  - `importSpecifierNameOwner`
  - `typePredicateNameOwner`

## FASTTypeScriptNull

- **Superclass:** `FASTTypeScriptLiteral`
- **Traits:** `FASTTNullPointerLiteral + FASTTypeScriptTPrimaryExpression`
- **Slots:**
  - `importSpecifierNameOwner`
  - `typePredicateNameOwner`

## FASTTypeScriptNumber

- **Superclass:** `FASTTypeScriptLiteral`
- **Traits:** `FASTTypeScriptTPrimaryExpression`
- **Slots:**
  - `importSpecifierNameOwner`
  - `typePredicateNameOwner`

## FASTTypeScriptObject

- **Superclass:** `FASTTypeScriptExpression`
- **Traits:** `FASTTypeScriptTPrimaryExpression`
- **Slots:**
  - `childrenNodes`
  - `importSpecifierNameOwner`
  - `typePredicateNameOwner`

## FASTTypeScriptObjectAssignmentPattern

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `left`

## FASTTypeScriptObjectPattern

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression + FASTTypeScriptTPattern`
- **Slots:**
  - `childrenNodes`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`
  - `assignmentPatternLeftOwner`

## FASTTypeScriptObjectType

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression + FASTTypeScriptTPrimaryType`
- **Slots:**
  - `childrenNodes`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptOmittingTypeAnnotation

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression`
- **Slots:**
  - `childrenNode`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptOptingTypeAnnotation

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression`
- **Slots:**
  - `childrenNode`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptOptionalChain

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `memberExpressionOptionalChainOwner`
  - `subscriptExpressionOptionalChainOwner`

## FASTTypeScriptOptionalParameter

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `decorator`
  - `name`
  - `type`

## FASTTypeScriptOptionalType

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression`
- **Slots:**
  - `childrenNode`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptOverrideModifier

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:** none

## FASTTypeScriptPair

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `key`

## FASTTypeScriptPairPattern

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `key`
  - `value`

## FASTTypeScriptParenthesizedExpression

- **Superclass:** `FASTTypeScriptExpression`
- **Traits:** `FASTTypeScriptTPrimaryExpression`
- **Slots:**
  - `doStatementConditionOwner`
  - `ifStatementConditionOwner`
  - `switchStatementValueOwner`
  - `type`
  - `whileStatementConditionOwner`
  - `withStatementObjectOwner`
  - `importSpecifierNameOwner`
  - `typePredicateNameOwner`

## FASTTypeScriptParenthesizedType

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression + FASTTypeScriptTPrimaryType`
- **Slots:**
  - `childrenNode`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptPredefinedType

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression + FASTTypeScriptTPrimaryType`
- **Slots:**
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptPrivatePropertyIdentifier

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression`
- **Slots:**
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptProgram

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `(FASTTEntity + FamixTHasImmediateSource withPrecedenceOf: FamixTHasImmediateSource)`
- **Slots:**
  - `childrenNodes`
  - `classDeclarations`
  - `enumDeclarations`
  - `interfaceDeclarations`
  - `source`
  - `element`

## FASTTypeScriptPropertyIdentifier

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression`
- **Slots:**
  - `methodDefinitionNameOwner`
  - `nestedIdentifierPropertyOwner`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptPropertySignature

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `name`
  - `type`

## FASTTypeScriptPublicFieldDefinition

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `decorator`
  - `name`
  - `type`

## FASTTypeScriptReadonlyType

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression + FASTTypeScriptTType`
- **Slots:**
  - `childrenNode`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptRegex

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTypeScriptTPrimaryExpression`
- **Slots:**
  - `flags`
  - `pattern`
  - `importSpecifierNameOwner`
  - `typePredicateNameOwner`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptRegexFlags

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `regexFlagsOwner`

## FASTTypeScriptRegexPattern

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `regexPatternOwner`

## FASTTypeScriptRequiredParameter

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `decorator`
  - `name`
  - `type`

## FASTTypeScriptRestPattern

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression + FASTTypeScriptTPattern`
- **Slots:**
  - `childrenNode`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`
  - `assignmentPatternLeftOwner`

## FASTTypeScriptRestType

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression`
- **Slots:**
  - `childrenNode`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptReturnStatement

- **Superclass:** `FASTTypeScriptStatement`
- **Slots:**
  - `childrenNode`

## FASTTypeScriptSatisfiesExpression

- **Superclass:** `FASTTypeScriptExpression`
- **Slots:**
  - `childrenNodes`

## FASTTypeScriptSequenceExpression

- **Superclass:** `FASTTypeScriptExpression`
- **Slots:**
  - `childrenNodes`

## FASTTypeScriptShorthandPropertyIdentifier

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:** none

## FASTTypeScriptShorthandPropertyIdentifierPattern

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:** none

## FASTTypeScriptSpreadElement

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `childrenNode`

## FASTTypeScriptStatement

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTStatement`
- **Slots:**
  - `parentLoopStatement`
  - `statementContainer`

## FASTTypeScriptStatementBlock

- **Superclass:** `FASTTypeScriptStatement`
- **Slots:**
  - `catchClauseBodyOwner`
  - `childrenNodes`
  - `classStaticBlockBodyOwner`
  - `finallyClauseBodyOwner`
  - `forInStatementBodyOwner`
  - `functionDeclarationBodyOwner`
  - `functionExpressionBodyOwner`
  - `generatorFunctionBodyOwner`
  - `generatorFunctionDeclarationBodyOwner`
  - `ifStatementConsequenceOwner`
  - `internalModuleBodyOwner`
  - `methodDefinitionBodyOwner`
  - `moduleBodyOwner`
  - `tryStatementBodyOwner`
  - `withStatementBodyOwner`

## FASTTypeScriptStatementIdentifier

- **Superclass:** `FASTTypeScriptStatement`
- **Slots:**
  - `breakStatementLabelOwner`
  - `continueStatementLabelOwner`
  - `labeledStatementLabelOwner`

## FASTTypeScriptString

- **Superclass:** `FASTTypeScriptLiteral`
- **Traits:** `FASTTStringLiteral + FASTTypeScriptTPrimaryExpression`
- **Slots:**
  - `childrenNodes`
  - `exportStatementSourceOwner`
  - `importRequireClauseSourceOwner`
  - `importStatementSourceOwner`
  - `importSpecifierNameOwner`
  - `typePredicateNameOwner`

## FASTTypeScriptStringFragment

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:** none

## FASTTypeScriptSubscriptExpression

- **Superclass:** `FASTTypeScriptExpression`
- **Traits:** `FASTTypeScriptTPattern + FASTTypeScriptTPrimaryExpression`
- **Slots:**
  - `optionalChain`
  - `assignmentPatternLeftOwner`
  - `importSpecifierNameOwner`
  - `typePredicateNameOwner`

## FASTTypeScriptSuper

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTypeScriptTPrimaryExpression`
- **Slots:**
  - `importSpecifierNameOwner`
  - `typePredicateNameOwner`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptSwitchBody

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `childrenNodes`
  - `switchStatementBodyOwner`

## FASTTypeScriptSwitchCase

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `value`

## FASTTypeScriptSwitchDefault

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:** none

## FASTTypeScriptSwitchStatement

- **Superclass:** `FASTTypeScriptStatement`
- **Slots:**
  - `body`
  - `value`

## FASTTypeScriptTDeclaration (Trait)

- **Traits:** `FASTTStatement`
- **Slots:**
  - `exportStatementDeclarationOwner`
  - `tWithDeclarationsDeclarationsOwner`
  - `parentLoopStatement`
  - `statementContainer`
  - `endPos`
  - `startPos`

## FASTTypeScriptTEntityCreator (Trait)

- **Slots:** none

## FASTTypeScriptTModifier (Trait)

- **Slots:**
  - `tWithModifiersModifiersOwner`

## FASTTypeScriptTOptionalField (Trait)

- **Slots:**
  - `exportSpecifierAliasOwner`
  - `methodDefinitionReturnTypeOwner`
  - `requiredParameterTypeOwner`

## FASTTypeScriptTPattern (Trait)

- **Slots:**
  - `assignmentPatternLeftOwner`

## FASTTypeScriptTPrimaryExpression (Trait)

- **Traits:** `FASTTExpression`
- **Slots:**
  - `importSpecifierNameOwner`
  - `typePredicateNameOwner`
  - `argumentOwner`
  - `assignedIn`
  - `expressionStatementOwner`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`
  - `endPos`
  - `startPos`

## FASTTypeScriptTPrimaryType (Trait)

- **Traits:** `FASTTypeScriptTType`
- **Slots:** none

## FASTTypeScriptTReturnType (Trait)

- **Slots:**
  - `functionDeclarationReturnTypeOwner`

## FASTTypeScriptTType (Trait)

- **Slots:** none

## FASTTypeScriptTWithDeclarations (Trait)

- **Slots:**
  - `declarations`

## FASTTypeScriptTWithModifiers (Trait)

- **Slots:**
  - `modifiers`

## FASTTypeScriptTemplateLiteralType

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression + FASTTypeScriptTPrimaryType`
- **Slots:**
  - `childrenNodes`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptTemplateString

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTypeScriptTPrimaryExpression`
- **Slots:**
  - `childrenNodes`
  - `importSpecifierNameOwner`
  - `typePredicateNameOwner`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptTemplateSubstitution

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `childrenNode`

## FASTTypeScriptTemplateType

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression`
- **Slots:**
  - `childrenNode`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptTernaryExpression

- **Superclass:** `FASTTypeScriptExpression`
- **Slots:** none

## FASTTypeScriptThis

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTypeScriptTPrimaryExpression`
- **Slots:**
  - `importSpecifierNameOwner`
  - `typePredicateNameOwner`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptThisType

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression + FASTTypeScriptTPrimaryType`
- **Slots:**
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptThrowStatement

- **Superclass:** `FASTTypeScriptStatement`
- **Slots:**
  - `childrenNode`

## FASTTypeScriptTrue

- **Superclass:** `FASTTypeScriptBoolean`
- **Traits:** `FASTTypeScriptTPrimaryExpression`
- **Slots:**
  - `importSpecifierNameOwner`
  - `typePredicateNameOwner`

## FASTTypeScriptTryStatement

- **Superclass:** `FASTTypeScriptStatement`
- **Slots:**
  - `body`
  - `finalizer`
  - `handler`

## FASTTypeScriptTupleType

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression + FASTTypeScriptTPrimaryType`
- **Slots:**
  - `childrenNodes`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptTypeAliasDeclaration

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTypeScriptTDeclaration`
- **Slots:**
  - `name`
  - `type_parameters`
  - `exportStatementDeclarationOwner`
  - `tWithDeclarationsDeclarationsOwner`
  - `parentLoopStatement`
  - `statementContainer`

## FASTTypeScriptTypeAnnotation

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression + FASTTypeScriptTOptionalField + FASTTypeScriptTReturnType`
- **Slots:**
  - `catchClauseTypeOwner`
  - `childrenNode`
  - `constructSignatureTypeOwner`
  - `optionalParameterTypeOwner`
  - `parenthesizedExpressionTypeOwner`
  - `propertySignatureTypeOwner`
  - `publicFieldDefinitionTypeOwner`
  - `variableDeclaratorTypeOwner`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`
  - `exportSpecifierAliasOwner`
  - `methodDefinitionReturnTypeOwner`
  - `requiredParameterTypeOwner`
  - `functionDeclarationReturnTypeOwner`

## FASTTypeScriptTypeArguments

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression + FASTTypeScriptTOptionalField`
- **Slots:**
  - `callExpressionTypeArgumentsOwner`
  - `childrenNodes`
  - `extendsClauseTypeArgumentsOwner`
  - `genericTypeTypeArgumentsOwner`
  - `instantiationExpressionTypeArgumentsOwner`
  - `newExpressionTypeArgumentsOwner`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`
  - `exportSpecifierAliasOwner`
  - `methodDefinitionReturnTypeOwner`
  - `requiredParameterTypeOwner`

## FASTTypeScriptTypeAssertion

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression`
- **Slots:**
  - `childrenNodes`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptTypeIdentifier

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression + FASTTypeScriptTPrimaryType`
- **Slots:**
  - `classDeclarationNameOwner`
  - `classNameOwner`
  - `interfaceDeclarationNameOwner`
  - `mappedTypeClauseNameOwner`
  - `nestedTypeIdentifierNameOwner`
  - `typeAliasDeclarationNameOwner`
  - `typeParameterNameOwner`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptTypeParameter

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression`
- **Slots:**
  - `constraint`
  - `name`
  - `value`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptTypeParameters

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression`
- **Slots:**
  - `abstractMethodSignatureTypeParametersOwner`
  - `arrowFunctionTypeParametersOwner`
  - `callSignatureTypeParametersOwner`
  - `childrenNodes`
  - `classDeclarationTypeParametersOwner`
  - `classTypeParametersOwner`
  - `constructSignatureTypeParametersOwner`
  - `constructorTypeTypeParametersOwner`
  - `functionDeclarationTypeParametersOwner`
  - `functionExpressionTypeParametersOwner`
  - `functionSignatureTypeParametersOwner`
  - `functionTypeTypeParametersOwner`
  - `generatorFunctionDeclarationTypeParametersOwner`
  - `generatorFunctionTypeParametersOwner`
  - `interfaceDeclarationTypeParametersOwner`
  - `methodDefinitionTypeParametersOwner`
  - `methodSignatureTypeParametersOwner`
  - `typeAliasDeclarationTypeParametersOwner`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptTypePredicate

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression`
- **Slots:**
  - `name`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptTypePredicateAnnotation

- **Superclass:** `FASTTypeScriptTypeAnnotation`
- **Traits:** `FASTTExpression`
- **Slots:** none

## FASTTypeScriptTypeQuery

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression + FASTTypeScriptTPrimaryType`
- **Slots:**
  - `childrenNode`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptUnaryExpression

- **Superclass:** `FASTTypeScriptExpression`
- **Slots:**
  - `operator`

## FASTTypeScriptUndefined

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTypeScriptTPattern + FASTTypeScriptTPrimaryExpression`
- **Slots:**
  - `assignmentPatternLeftOwner`
  - `importSpecifierNameOwner`
  - `typePredicateNameOwner`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptUnionType

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTExpression + FASTTypeScriptTPrimaryType`
- **Slots:**
  - `childrenNodes`
  - `argumentOwner`
  - `assignedIn`
  - `parentConditional`
  - `parentExpression`
  - `parentExpressionLeft`
  - `parentExpressionRight`
  - `returnOwner`

## FASTTypeScriptUpdateExpression

- **Superclass:** `FASTTypeScriptExpression`
- **Slots:**
  - `operator`

## FASTTypeScriptVariableDeclaration

- **Superclass:** `FASTTypeScriptEntity`
- **Traits:** `FASTTypeScriptTDeclaration`
- **Slots:**
  - `childrenNodes`
  - `exportStatementDeclarationOwner`
  - `tWithDeclarationsDeclarationsOwner`
  - `parentLoopStatement`
  - `statementContainer`

## FASTTypeScriptVariableDeclarator

- **Superclass:** `FASTTypeScriptEntity`
- **Slots:**
  - `name`
  - `type`

## FASTTypeScriptWhileStatement

- **Superclass:** `FASTTypeScriptStatement`
- **Slots:**
  - `condition`

## FASTTypeScriptWithStatement

- **Superclass:** `FASTTypeScriptStatement`
- **Slots:**
  - `body`
  - `object`

## FASTTypeScriptYieldExpression

- **Superclass:** `FASTTypeScriptExpression`
- **Slots:**
  - `childrenNode`
```
