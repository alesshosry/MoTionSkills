# FASTXML + MoTion Playbook (Pharo)

This document is dedicated for writing MoTion patterns to match a FASTXML model. Some may want to analyse XML files and search for specific nodes... This is why you can benefit from MoTion to express the patterns you want, and use FASTXML metamodel which allows representing XML nodes in Pharo. The combination of both tools, will allow you to apply any search. 

## 1) Requirements / Packages
- [FASTXML (metamodel + parser)](https://github.com/Evref-BL/FASTXML)
- [MoTion](https://github.com/alesshosry/Motion)

## 2) Parse XML and get the Document node

```smalltalk
string := '// XML'.
res := FASTXMLImporter new parse: string.
"res will be a FASTXMLModel; we need to access the #entities inside👇🏻"

"Document entity: is the top entity of every xml model"
prog := (res entities detect: [ :ent | ent class = FASTXMLDocument ])
```

## 3) Core MoTion traversal idioms

### 3.1) Recursive descent (find a node anywhere)
Use `#'children*'` from `FASTXMLDocument` to search anywhere in the subtree.

```smalltalk
pattern := FASTXMLDocument % {
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

### 4.1) Retrieve empty xml tags

```smalltalk
str := '<data>
  <name>Tanmay Patil</name>
  <company></company>
  <phone></phone> 
</data>'.

tree := FASTXMLImporter new parse: str.
doc := (tree select: [ :e | e class =  FASTXMLDocument ]) first.

"Extract data of the address"

pattern := FASTXMLDocument % {	 
				#'children*' <=> FASTXMLElement % { 
					#'children' <=> {
						FASTXMLSTag % {}  .  
						FASTXMLETag % {} . 
					}.
				} as: #xmlElement
			}.  

pattern collectBindings: {#xmlElement. } for: doc.   
```

### 4.1) The most complex pattern: retrieve address data from xml tag

```smalltalk
str := '<address>
  <name>Tanmay Patil</name>
  <company>TutorialsPoint</company>
  <phone>(011) 123-4567</phone>
</address>'.

tree := FASTXMLImporter new parse: str.
doc := (tree select: [ :e | e class =  FASTXMLDocument ]) first.

"Extract data of the address"

pattern := FASTXMLDocument % {	
	#'children' <=> FASTXMLElement % { 
		#'children' <=> { 
			#'*_'.	 
			FASTXMLSTag % { 
				#'children>sourceCode' <=> 'address'
			}.
			#'*_'.	 
			FASTXMLContent % { 
				#'children' <=> FASTXMLElement % { 
					#'children' <=> {    
						#'*_'.	 
						FASTXMLSTag % { 
							#'children>sourceCode' <=> #'@tag'
						}. 
						#'*_'.	
						FASTXMLContent % { 
							#'children>sourceCode' <=> #'@content'
						}.
						#'*_'.	 
					}
				}
			}.
			#'*_'.	 
		}	
	} 
}.

pattern match: doc. 
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

### 6) FASTXML entities and their slots: query the image

The entity classes and their slots change with the metamodel; the running image is the
source of truth, so do not rely on a list. Parse a snippet and inspect what comes out
(`node genericChildren collect: #class`, `node class allSlots collect: #name`), or read the Fame
description (`aClass metadescription allAttributes`). Slot names are the property names a
`% { ... }` pattern can constrain.
