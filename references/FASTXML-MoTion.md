# FASTXML + MoTion Playbook (Pharo)

This document is dedicated for writing MoTion patterns to match a FASTXML model. Some may want to analyse XML files and search for specific nodes... This is why you can benefit from MoTion to express the patterns you want, and use FASTXML metamodel which allows representing XML nodes in Pharo. The combination of both tools, will allow you to apply any search. 

## 1) Requirements / Packages
- [FASTXML (metamodel + parser)](https://github.com/Evref-BL/FASTXML)
- [MoTion](https://github.com/alesshosry/Motion)

## 2) Parse XML and get the Document node

```smalltalk
string := '// XML'.
res := FASTXMLParser new parse: string.
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

tree := FASTXMLParser new parse: str.
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

tree := FASTXMLParser new parse: str.
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

### 6) FASTXML entities
In order to express a pattern effitiently, MoTion needs to know the class names representing the entities of XML. This is why we are listing them here in accordance to there slots that can be used while expressing a MoTion pattern:

```smalltalk
# Metamodel: FAST-XML-Model

## FASTXMLAttDef

- **Superclass:** `FASTXMLEntity`
- **Slots:**
  - `childrenNodes`

## FASTXMLAttValue

- **Superclass:** `FASTXMLEntity`
- **Slots:**
  - `content`

## FASTXMLAttlistDecl

- **Superclass:** `FASTXMLEntity`
- **Traits:** `FASTXMLTMarkupdecl`
- **Slots:**
  - `childrenNodes`

## FASTXMLAttribute

- **Superclass:** `FASTXMLEntity`
- **Slots:**
  - `childrenNodes`

## FASTXMLCDSect

- **Superclass:** `FASTXMLEntity`
- **Slots:**
  - `childrenNodes`

## FASTXMLCDStart

- **Superclass:** `FASTXMLEntity`
- **Slots:** none

## FASTXMLCData

- **Superclass:** `FASTXMLEntity`
- **Slots:** none

## FASTXMLCharData

- **Superclass:** `FASTXMLEntity`
- **Slots:** none

## FASTXMLCharRef

- **Superclass:** `FASTXMLEntity`
- **Traits:** `FASTXMLTReference`
- **Slots:**
  - `attValueContentOwner`
  - `pseudoAttValueContentOwner`

## FASTXMLChildren

- **Superclass:** `FASTXMLEntity`
- **Slots:**
  - `childrenNodes`

## FASTXMLComment

- **Superclass:** `FASTXMLEntity`
- **Traits:** `FASTXMLTMarkupdecl`
- **Slots:** none

## FASTXMLContent

- **Superclass:** `FASTXMLEntity`
- **Slots:**
  - `childrenNodes`

## FASTXMLContentspec

- **Superclass:** `FASTXMLEntity`
- **Slots:**
  - `childrenNode`

## FASTXMLDefaultDecl

- **Superclass:** `FASTXMLEntity`
- **Slots:**
  - `childrenNode`

## FASTXMLDoctypedecl

- **Superclass:** `FASTXMLEntity`
- **Slots:**
  - `childrenNodes`

## FASTXMLDocument

- **Superclass:** `FASTXMLEntity`
- **Traits:** `(FASTTEntity + FamixTHasImmediateSource withPrecedenceOf: FamixTHasImmediateSource)`
- **Slots:**
  - `root`
  - `source`
  - `element`

## FASTXMLERROR

- **Superclass:** `FASTXMLEntity`
- **Traits:** `FamixTHasImmediateSource`
- **Slots:**
  - `source`
  - `element`

## FASTXMLETag

- **Superclass:** `FASTXMLEntity`
- **Slots:**
  - `childrenNode`

## FASTXMLElement

- **Superclass:** `FASTXMLEntity`
- **Slots:**
  - `childrenNodes`
  - `documentRootOwner`

## FASTXMLElementdecl

- **Superclass:** `FASTXMLEntity`
- **Traits:** `FASTXMLTMarkupdecl`
- **Slots:**
  - `childrenNodes`

## FASTXMLEmptyElemTag

- **Superclass:** `FASTXMLEntity`
- **Slots:**
  - `childrenNodes`

## FASTXMLEncName

- **Superclass:** `FASTXMLEntity`
- **Slots:** none

## FASTXMLEntity

- **Superclass:** `MooseEntity`
- **Traits:** `FASTTEntity + TEntityMetaLevelDependency`
- **Slots:**
  - `attDefOwner`
  - `attlistDeclOwner`
  - `attributeOwner`
  - `cDSectOwner`
  - `childrenOwner`
  - `contentOwner`
  - `contentspecOwner`
  - `defaultDeclOwner`
  - `doctypedeclOwner`
  - `eTagOwner`
  - `elementOwner`
  - `elementdeclOwner`
  - `emptyElemTagOwner`
  - `entityRefOwner`
  - `entityValueContentOwner`
  - `enumerationOwner`
  - `externalIDOwner`
  - `gEDeclOwner`
  - `genericChildren`
  - `genericParent`
  - `mixedOwner`
  - `nDataDeclOwner`
  - `notationDeclOwner`
  - `notationTypeOwner`
  - `pEDeclOwner`
  - `pEReferenceOwner`
  - `pIOwner`
  - `prologOwner`
  - `pseudoAttOwner`
  - `publicIDOwner`
  - `sTagOwner`
  - `styleSheetPIOwner`
  - `systemLiteralOwner`
  - `xMLDeclOwner`
  - `xmlModelPIOwner`
  - `endPos`
  - `startPos`

## FASTXMLEntityRef

- **Superclass:** `FASTXMLEntity`
- **Traits:** `FASTXMLTReference`
- **Slots:**
  - `childrenNode`
  - `attValueContentOwner`
  - `pseudoAttValueContentOwner`

## FASTXMLEntityValue

- **Superclass:** `FASTXMLEntity`
- **Slots:**
  - `content`

## FASTXMLEnumeration

- **Superclass:** `FASTXMLEntity`
- **Traits:** `FASTXMLTEnumeratedType`
- **Slots:**
  - `childrenNodes`

## FASTXMLExternalID

- **Superclass:** `FASTXMLEntity`
- **Slots:**
  - `childrenNodes`

## FASTXMLGEDecl

- **Superclass:** `FASTXMLEntity`
- **Traits:** `FASTXMLTEntityDecl`
- **Slots:**
  - `childrenNodes`

## FASTXMLMixed

- **Superclass:** `FASTXMLEntity`
- **Slots:**
  - `childrenNodes`

## FASTXMLModel

- **Superclass:** `MooseModel`
- **Traits:** `FASTTEntityCreator + FASTXMLTEntityCreator`
- **Slots:** none

## FASTXMLNDataDecl

- **Superclass:** `FASTXMLEntity`
- **Slots:**
  - `childrenNode`

## FASTXMLName

- **Superclass:** `FASTXMLEntity`
- **Slots:** none

## FASTXMLNmtoken

- **Superclass:** `FASTXMLEntity`
- **Slots:** none

## FASTXMLNotationDecl

- **Superclass:** `FASTXMLEntity`
- **Traits:** `FASTXMLTMarkupdecl`
- **Slots:**
  - `childrenNodes`

## FASTXMLNotationType

- **Superclass:** `FASTXMLEntity`
- **Traits:** `FASTXMLTEnumeratedType`
- **Slots:**
  - `childrenNodes`

## FASTXMLPEDecl

- **Superclass:** `FASTXMLEntity`
- **Traits:** `FASTXMLTEntityDecl`
- **Slots:**
  - `childrenNodes`

## FASTXMLPEReference

- **Superclass:** `FASTXMLEntity`
- **Traits:** `FASTXMLTAttType`
- **Slots:**
  - `childrenNode`

## FASTXMLPI

- **Superclass:** `FASTXMLEntity`
- **Traits:** `FASTXMLTMarkupdecl`
- **Slots:**
  - `childrenNode`

## FASTXMLPITarget

- **Superclass:** `FASTXMLEntity`
- **Slots:** none

## FASTXMLProlog

- **Superclass:** `FASTXMLEntity`
- **Slots:**
  - `childrenNodes`

## FASTXMLPseudoAtt

- **Superclass:** `FASTXMLEntity`
- **Slots:**
  - `childrenNodes`

## FASTXMLPseudoAttValue

- **Superclass:** `FASTXMLEntity`
- **Slots:**
  - `content`

## FASTXMLPubidLiteral

- **Superclass:** `FASTXMLEntity`
- **Slots:** none

## FASTXMLPublicID

- **Superclass:** `FASTXMLEntity`
- **Slots:**
  - `childrenNodes`

## FASTXMLSTag

- **Superclass:** `FASTXMLEntity`
- **Slots:**
  - `childrenNodes`

## FASTXMLStringType

- **Superclass:** `FASTXMLEntity`
- **Traits:** `FASTXMLTAttType`
- **Slots:** none

## FASTXMLStyleSheetPI

- **Superclass:** `FASTXMLEntity`
- **Slots:**
  - `childrenNodes`

## FASTXMLSystemLiteral

- **Superclass:** `FASTXMLEntity`
- **Slots:**
  - `childrenNode`

## FASTXMLTAttType (Trait)

- **Slots:** none

## FASTXMLTEntityCreator (Trait)

- **Slots:** none

## FASTXMLTEntityDecl (Trait)

- **Traits:** `FASTXMLTMarkupdecl`
- **Slots:** none

## FASTXMLTEnumeratedType (Trait)

- **Traits:** `FASTXMLTAttType`
- **Slots:** none

## FASTXMLTMarkupdecl (Trait)

- **Slots:** none

## FASTXMLTReference (Trait)

- **Slots:**
  - `attValueContentOwner`
  - `pseudoAttValueContentOwner`

## FASTXMLTokenizedType

- **Superclass:** `FASTXMLEntity`
- **Traits:** `FASTXMLTAttType`
- **Slots:** none

## FASTXMLURI

- **Superclass:** `FASTXMLEntity`
- **Slots:** none

## FASTXMLVersionNum

- **Superclass:** `FASTXMLEntity`
- **Slots:** none

## FASTXMLXMLDecl

- **Superclass:** `FASTXMLEntity`
- **Slots:**
  - `childrenNodes`

## FASTXMLXmlModelPI

- **Superclass:** `FASTXMLEntity`
- **Slots:**
  - `childrenNodes`
```

As you notice, no slots in this metamodel, yet ! 
Also slots are upcoming soon
