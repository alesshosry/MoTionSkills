---
name: motion-pharo-ast-patterns
description: Create MoTion patterns in Pharo to match models or apply refactorings over FAST models. Use when a user asks to write or adapt MoTion patterns for TypeScript AST, Java AST or XML AST. Route TypeScript work to MoTion.md + FASTTypeScript-MoTion.md, and XML work to MoTion.md + FASTXML-MoTion.md, and Java work to MoTion.md + FASTJava-MoTion.md. When the request includes refactoring, use additionally MoTion-Transformation.md.
---
---

# MoTion Pharo AST Patterns

## Workflow

1. Identify the target AST domain from the user request.
2. Load base MoTion guidance from `references/MoTion.md`.
3. Load exactly one domain guide:
  * TypeScript AST: `references/FASTTypeScript-MoTion.md`
  * XML AST: `references/FASTXML-MoTion.md`
  * Java AST: `references/FASTJava-MoTion.md`
4. If the request involves transforming the original source code, also load:
   `references/MoTion-Transformation.md`.
5. If the user does not know where to find or install the repositories needed for MoTion or the FAST libraries, direct them to the `Repositories.md` file, which explains how to obtain and install the correct repositories.
6. Build or revise the pattern using Pharo syntax.
7. For refactoring requests, build the corresponding `MoTionRule` and use the appropriate execution method.
8. Return the pattern and a short explanation of key selectors/operators used.
9. When possible, validate the generated source by reparsing the resulting text.

## Domain Routing

Use this routing consistently:

* If the request mentions TypeScript, JavaScript/TS source code, or FAST TypeScript nodes, use:
  `references/MoTion.md` and `references/FASTTypeScript-MoTion.md`.

* If the request mentions XML, tags/attributes, or FAST XML nodes, use:
  `references/MoTion.md` and `references/FASTXML-MoTion.md`.

* If the request mentions Java, tags/attributes, or FAST Java nodes, use:
  `references/MoTion.md` and `references/FASTJava-MoTion.md`.

* If the request asks for source code transformation/refactoring, use:
`references/MoTion-Transformation.md`.

* If the request is ambiguous, ask whether the target is TypeScript AST, Java AST or XML AST before writing the final pattern.
 
## Output Rules

1. Return valid Pharo/MoTion pattern code.
2. Keep the pattern minimal and composable.
3. Include assumptions when node types are inferred.
4. When asked to improve an existing pattern, preserve user intent and explain the delta briefly.
5. For transformation requests, include the `MoTionRule` configuration and the appropriate execution method.
6. Clearly distinguish replacement bindings from removal bindings.
7. Do not invent FAST node structures when the required structure is already documented.
8. Be careful not to add unnecessary parentheses in patterns.

## References

Always treat these files as source of truth:

* `references/MoTion.md`
* `references/FASTTypeScript-MoTion.md`
* `references/FASTXML-MoTion.md`
* `references/FASTJava-MoTion.md`
* `references/MoTion-Transformation.md`
* `references/Repositories.md` (for locating required repositories)
