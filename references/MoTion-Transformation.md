# MoTion Source Transformations

## Description

MoTion can be used not only to match objects in a model, but also to transform the original source code associated with matched model elements.

The transformation mechanism is provided by `MoTionRule` from the `MoTion-FAST-Transformation` package.

A transformation rule connects:

* a MoTion source pattern;
* a model containing the matched objects;
* the original source code;
* bindings identifying the elements to transform;
* replacement values or removal targets.

The transformation operates on the original source code using the source positions of the matched model elements.

## MoTionRule

A `MoTionRule` can be configured with the following properties:

* `sourcePattern`: the MoTion pattern used to find the elements to transform.
* `model`: the model on which the pattern is matched.
* `source`: the original source code.
* `bindings`: the bindings used for source replacements.
* `removalBindings`: the bindings identifying elements to remove.

A basic replacement rule has the following structure:

```Smalltalk
rule := MoTionRule new
    sourcePattern: pattern;
    model: model;
    source: sourceCode;
    bindings: {
        #bindingName -> newValue
    } asDictionary.

updatedSource := rule executeWithBindings.
```

For removal transformations, use `removalBindings` to identify the bindings to remove and then call `executeRemoval`:

```Smalltalk
rule := MoTionRule new
    sourcePattern: pattern;
    model: model;
    source: sourceCode;
    removalBindings: #( #nodeToRemove ).

updatedSource := rule executeRemoval.
```

## Examples

The following examples illustrate the main transformation mechanisms supported by `MoTionRule`.

### 1. Rename a method with `as:` and `bindings`

Use `as:` to capture the actual AST node that should be transformed.

```Smalltalk
sourceCode := 'class Calculator {
    add(a: number, b: number) {
        return a + b;
    }
}'.

model := FASTTypeScriptParser new parse: sourceCode.
prog := (model entities select: [ :each |
    each class = FASTTypeScriptProgram
]) first.

methodNamePattern := FASTTypeScriptPropertyIdentifier % {
    #sourceCode <=> 'add'
} as: #methodName.

pattern := FASTTypeScriptProgram % {
    #'children*' <=> FASTTypeScriptMethodDefinition % {
        #name <=> methodNamePattern
    }
}.

rule := MoTionRule new
    sourcePattern: pattern;
    model: prog;
    source: sourceCode;
    bindings: {
        #methodName -> 'sum'
    } asDictionary.

updatedSource := rule executeWithBindings.
```

The `#methodName` binding contains the matched AST node. Since the node responds to `startPos` and `endPos`, `MoTionRule` can use its source range directly.

### 2. Capture values with `@`

Use `@name` when the pattern needs to capture a value from the matched model.

For example:

```Smalltalk
parametersPattern := FASTTypeScriptFormalParameters % {
    #parameters <=> {
        #'@p1'.
        #'@p2'
    }
}.
```

The captured values can then be provided as replacement bindings:

```Smalltalk
rule := MoTionRule new
    sourcePattern: pattern;
    model: model;
    source: sourceCode;
    bindings: {
        #p1 -> 'a: string'.
        #p2 -> 'b: string'
    } asDictionary.

updatedSource := rule executeWithBindings.
```

When a captured value is not already an AST node, `MoTionRule` resolves it to the corresponding source node using:

```Smalltalk
findNodeWithSourceCode:inModel:
```

### 3. Capture a collection with `*rest`

Use `*rest` when the remaining elements of a list need to be captured as a collection.

```Smalltalk
parametersPattern := FASTTypeScriptFormalParameters % {
    #parameters <=> {
        #'@p1'.
        #'@p2'.
        #'*rest'
    }
}.
```

The `#rest` binding contains the remaining matched elements as a collection.

`MoTionRule` processes each element of the collection individually and resolves it to an AST node when necessary. This allows one transformation binding to operate on multiple source elements.

For example:

```Smalltalk
rule := MoTionRule new
    sourcePattern: pattern;
    model: model;
    source: sourceCode;
    bindings: {
        #rest -> 'ignored: unknown'
    } asDictionary.

updatedSource := rule executeWithBindings.
```

The same replacement value is applied to each element contained in `#rest`.

### 4. Remove a complete AST node

Use `as:` to capture the AST node to remove, specify that binding in `removalBindings`, and call `executeRemoval`.

```Smalltalk
pattern := FASTTypeScriptClassDeclaration % {
    (#'children*' <=> (FASTTypeScriptMethodDefinition % {
        #name <=> (FASTTypeScriptPropertyIdentifier % {
            #sourceCode <=> 'multiply'
        })
    } as: #methodToDelete))
}.

rule := MoTionRule new
    sourcePattern: pattern;
    model: model;
    source: sourceCode;
    removalBindings: #( #methodToDelete ).

updatedSource := rule executeRemoval.
```

The `#methodToDelete` binding contains the actual method AST node, allowing `executeRemoval` to remove its corresponding source range.

### 5. Remove an element from a list

For an element inside a list, capture the list elements with `@` bindings and specify the binding to remove in `removalBindings`.

```Smalltalk
method := (model allWithType: FASTTypeScriptMethodDefinition)
    detect: [ :m | m name sourceCode = 'add' ].

pattern := FASTTypeScriptMethodDefinition % {
    (#parameters <=> (FASTTypeScriptFormalParameters % {
        (#_ <=> {
            #'@p1'.
            #'@p2'.
            #'@p3'
        })
    }))
}.

rule := MoTionRule new.
rule sourcePattern: pattern.
rule model: method.
rule source: sourceCode.
rule removalBindings: #( #p3 ).

updatedSource := rule executeRemoval.
```

Here `#p3` identifies the parameter to remove.

When removing an element from a comma-separated list, `executeRemoval` also handles the surrounding comma when appropriate.

## Transformation rules

When generating a transformation, follow these rules:

* Use `as:` when the transformation targets the actual AST node.
* Use `@name` when a matched value needs to be captured.
* Use `*rest` when several remaining list elements need to be captured as a collection.
* Use `bindings` with `executeWithBindings` for replacements.
* Use `removalBindings` with `executeRemoval` for removals.
* Prefer existing documented FAST structures over inventing new property paths or AST relationships.
* When the exact FAST structure is uncertain, consult the relevant FAST domain guide before generating the pattern.
* When possible, reparse the transformed source to verify that the result remains valid.

## Replacement transformations

`executeWithBindings` applies replacements to the original source code based on the bindings collected from the source pattern.

The transformation follows these steps:

1. The source pattern is matched against the model.
2. The requested bindings are collected from the matches.
3. Matched values are resolved to source nodes when necessary.
4. The corresponding source ranges are identified using `startPos` and `endPos`.
5. Duplicate nodes are removed using their `startPos`.
6. Changes are sorted from right to left.
7. Each source range is replaced with the corresponding new value.

Applying changes from right to left is important because replacing a later source range does not modify the positions of earlier ranges.

The source replacement is performed using:

```Smalltalk
copyReplaceFrom:to:with:
```

## Binding matched AST nodes

A transformation can capture an AST node directly using `as:`.

For example:

```Smalltalk
nodePattern := SomeASTNode % {
    #someProperty <=> someValue
} as: #node.
```

The `#node` binding contains the matched AST node.

When the matched object responds to `startPos`, `MoTionRule` can use its source range directly for the transformation.

This is particularly useful when only a specific part of a source element has to be modified.

## Value bindings

A pattern can also capture a value rather than a direct AST node.

For example:

```Smalltalk
#someProperty <=> @value
```

When the resulting binding is not directly an AST node, `MoTionRule` can resolve the value to the corresponding node in the model using:

```Smalltalk
findNodeWithSourceCode:inModel:
```

This allows transformations to work with bindings that represent source values.

## Collection bindings

A collection of matched elements can also be transformed.

This can occur when using a repeated pattern such as `*rest`.

For each element of the collection, `MoTionRule`:

1. checks whether the element is already an AST node;
2. otherwise resolves it using `findNodeWithSourceCode:inModel:`;
3. identifies its source range;
4. adds the transformation if the node has not already been processed.

This allows one transformation rule to operate on multiple matched elements.

## Duplicate matches

The same source element can potentially be obtained through several matches.

To avoid applying the same transformation multiple times, matched nodes are deduplicated using their `startPos`.

Two matches referring to the same source position therefore produce only one transformation.

## Transformation order

When several source elements have to be transformed, changes are sorted by decreasing `startPos`.

In other words, transformations are applied from the end of the source toward the beginning.

For example, if three matched nodes start at positions:

```text
120
80
25
```

the transformations are applied in this order:

```text
120 → 80 → 25
```

This preserves the original positions of the elements that have not yet been modified.

## Removing source elements

`MoTionRule` also supports removing matched elements from the original source.

For this purpose:

1. capture the element to remove in a binding;
2. add that binding to `removalBindings`;
3. call `executeRemoval`.

For example:

```Smalltalk
rule := MoTionRule new
    sourcePattern: pattern;
    model: model;
    source: sourceCode;
    removalBindings: #( #nodeToRemove ).

updatedSource := rule executeRemoval.
```

The removal process follows the same general resolution strategy as replacements:

1. collect the requested removal bindings;
2. resolve values to AST nodes when necessary;
3. remove duplicate nodes;
4. sort nodes by decreasing `startPos`;
5. remove their corresponding source ranges.

The source range is determined from:

```Smalltalk
node startPos
node endPos
```

The removal is then performed using:

```Smalltalk
copyReplaceFrom:to:with:
```

with an empty replacement string.

## Removing elements from lists

When removing an element from a list, the transformation also handles the surrounding comma when appropriate.

If a comma and its surrounding spacing appear immediately before the node, the removal range can be extended to include them.

Otherwise, if a comma appears immediately after the node, the removal range can be extended to include that comma and its spacing.

This allows removal transformations to preserve valid source syntax when removing elements from comma-separated structures.

## Transformation and source preservation

MoTion transformations operate on the original source code rather than reconstructing the complete source from the model.

Only the source ranges corresponding to matched nodes are modified.

For example, if a pattern captures a TypeScript method name, the transformation can replace only the identifier while preserving:

* the method body;
* whitespace;
* indentation;
* comments;
* surrounding source code.

This makes source-position-based transformations suitable for precise source modifications.

## Domain-specific transformation guides

This document describes the general transformation mechanism.

Domain-specific transformation examples should be documented in the corresponding FAST domain guide:

* TypeScript AST transformations → `FASTTypeScript-MoTion.md`
* Java AST transformations → `FASTJava-MoTion.md`
* XML AST transformations → `FASTXML-MoTion.md`
