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

### 6) FASTTypeScript entities and their slots: query the image

The entity classes and their slots change with the metamodel; the running image is the
source of truth, so do not rely on a list. Parse a snippet and inspect what comes out
(`node children collect: #class`, `node class allSlots collect: #name`), or read the Fame
description (`aClass metadescription allAttributes`). Slot names are the property names a
`% { ... }` pattern can constrain.
