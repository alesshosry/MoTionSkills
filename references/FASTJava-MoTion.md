# FASTJava + MoTion Playbook (Pharo)

This document is dedicated for writing MoTion patterns to match a FASTJava model. Some may want to find the if/else clause in a Java file, others may need the switch case, others want specific search... This is why you can benefit from MoTion to express the patterns you want, and use FASTJava metamodel which allows representing the AST of Java in Pharo. The combination of both tools, will allow you to apply any search. 

## 1) Requirements / Packages
- [FASTJava (metamodel + parser)](https://github.com/moosetechnology/FAST-Java)
- [MoTion](https://github.com/alesshosry/Motion)

## 2) Parse Java and get the top node

Well, FAST-Java is not based on treesitter as other FAST metamodels (FASTXML, FASTTypeScript ...). So dealing with FAST-Java parsing will be a bit different. The main difference is that there is no specific top node common for all the ASTs that are generated. This will result a difficulty in knowing which node should be selected and what i sthe top type in MoTion pattern ready for the match.

There are two ways to parse Java code: one using #parseCodeMethodString: to parse Java methods and another one using #parseCodeString: to parse any encapsulated Java code (in methods, classes, interfaces ...). 

For example:

```smalltalk
parsedClass := JavaSmaCCProgramNodeImporterVisitor new parseCodeString: 'public class Account {
    private int customerNumber;
}'.
"parsedClass will be a FASTJavaModel containing list of entities, each one of them representing a node of the code;" 

"Another example to parse a method:"
parsedMethod := JavaSmaCCProgramNodeImporterVisitor new parseCodeMethodString: 'public void check() {
        System.out.println("Checking Account Balance"); 
}'.

"parsedMethod will be a FASTJavaModel containing list of entities, each one of them representing a node of the code;"
``` 

Since the result of parsing is a FASTJavaModel, and since FAST-Java does not contain a top entity (like document for Typescript AST), then we recommend that any MoTion pattern to be matched is a FASTJavaModel pattern, and the entities will be accessed using #allModelEntities.
So mainly patterns for FASTJava will take this shape:

```smalltalk
pattern := FASTJavaModel % {    
		#'allModelEntities' <=> FASTJavaTheEntityIamLookingFor % { 
			....
		} as: #myEntity.
	}.
```

## 3) Example patterns

### 3.1) Switch: exactly 2 cases + 1 default (via SwitchBody children)
```smalltalk
string := 'public String getDayType(int day) {
    switch (day) {
        case 1:
            return "Weekday";
        case 2:
            return "Weekend";
        default:
            return "Invalid day";
    }
}'.


pattern := FASTJavaModel % {    
		#'allModelEntities' <=> FASTJavaSwitchStatement % { 
			#cases  <=> { 
				FASTJavaLabeledCaseStatement % {} as:#case1. 
				FASTJavaLabeledCaseStatement % {} as:#case2.  
				FASTJavaDefaultCaseStatement % {} as:#default. }
		} as: #amethod.
	}.

parsedCode := JavaSmaCCProgramNodeImporterVisitor new parseCodeMethodString: string.
  
results := pattern collectBindings: {  #amethod. #case1. #case2. #default } for: parsedCode. 
```

### 3.2) If/Else: get the else that is not followed by if
```smalltalk
string := 'public class NumberUtils
{
    public string ClassifyNumber(int number)
    {
        if (number < 0)
        {
            return "Negative number";
        }
        else if (number == 0)
        {
            return "Zero";
        }
        else if (number > 0 && number <= 10)
        {
            return "Small positive number";
        }
        else
        {
            return "Large positive number";
        }
    }

    public string GradeResult(int score)
    {
        if (score < 50)
        {
            return "Fail";
        }
        else if (score < 65)
        {
            return "Pass";
        }
        else if (score < 80)
        {
            return "Good";
        }
        else if (score <= 100)
        {
            return "Excellent";
        }
        else
        {
            return "Invalid score";
        }
    }
}'.

parsedCode := JavaSmaCCProgramNodeImporterVisitor new parseCodeString: string.

pattern := FASTJavaModel % {    
		#'allModelEntities' <=> FASTJavaIfStatement % { 
			#'elsePart'  <~=> FASTJavaIfStatement % { } .
		} as: #amethod
	}.

results := pattern collectBindings: { #amethod.} for: parsedCode.
```


## 4) Debugging tips

### 4.1) Inspect children to learn structure
```smalltalk
node children collect: #class.
node children.
```

### 4.2) Why you got too many matches
- Using `#'children*'` matches *descendants*, producing cross-products when nested structures exist.
- Prefer `#children` when you mean “direct child”.

## 5) FASTJava entities and their slots: query the image, do not memorize

The FAST-Java metamodel moves (new traits, renamed relations, new slots), so any
list written here goes stale. The running image is the source of truth. Before
writing a pattern, look the entity up there:

- Which class represents a construct? Parse a snippet and look at what comes out:
  ```smalltalk
  model := JavaSmaCCProgramNodeImporterVisitor new parseCodeString: 'class T { void m(java.util.List<String> l) { l.size(); } }'.
  (model allModelEntities collect: [ :e | e class name -> (e startPos -> e endPos) ]) asArray.
  ```
  The `startPos`/`endPos` pairs tell which entity covers which text; `FASTJavaMethodInvocation`
  spans receiver and arguments, its `type` or `typeName` sub-entities span the type text
  including any `<...>` type arguments.
- Which slots can a pattern name? Ask the class:
  ```smalltalk
  (FASTJavaMethodInvocation allSlots collect: #name) asArray.
  ```
  Slot names are the property names usable in `% { #slot <=> ... }` and in paths such as
  `#'receiver>startPos'`.
- Which relations exist, with their opposites and types? Read the Fame description:
  ```smalltalk
  (FASTJavaMethodInvocation metadescription allAttributes collect: [ :a | a name -> a type name ]) asArray.
  ```
- Which concrete classes stand behind an abstract one (e.g. the literals)? Ask for subclasses:
  `FASTJavaLiteral allSubclasses`.

Parsing a method body is enough for most probes; a class-level field such as
`class T { String x = ...; }` needs the full `parseCodeString:` form, not `parseCodeMethodString:`.

## 6) Useful idioms

- There is no top node: start from `FASTJavaModel % { #allModelEntities <=> (Entity % { ... } as: #x) }`
  and read the bindings with `pattern collectBinding: #x for: model` (answers a plain
  collection, possibly empty; `collectBindings:for:` answers dictionaries for several names).
- Locate an entity by its position in the source: `(#startPos <=> start). (#endPos <=> end)`
  for an exact range, or `(#startPos lessOrEqualTo: start). (#endPos higherOrEqualTo: end)`
  for an enclosing one; when several enclose it, keep the innermost with
  `detectMin: [ :e | e endPos - e startPos ]`.
- A constraint on a part: `(#receiver <=> (FASTJavaEntity %% { (#startPos lessOrEqualTo: s) }))`;
  `%%` accepts subclasses, `%` only the exact class. A nil receiver simply does not match.
- A list with exactly one element: `(#arguments <=> { #'@argument' })`; an empty list:
  `(#arguments <=> {  })`. Both are exact-length constraints, unlike the shortcut
  `#arguments <=> aValue`, which means "contains".
- Several accepted names: `(#name <=> (('exists' orMatches: 'notExists') orMatches: 'isDirectory'))`.
- `model allWithType: FASTJavaX` answers a MooseGroup (no `detectMin:`); MoTion bindings are
  ordinary collections. Source text of an entity: slice the original string with
  `startPos`/`endPos` rather than relying on `sourceCode`, which needs the model's source to be set.
