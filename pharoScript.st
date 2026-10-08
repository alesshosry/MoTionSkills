| packageName md |
packageName := 'FAST-XML-Model'. "<- change this to your metamodel package"

md := String streamContents: [ :s |
	s nextPutAll: '# Metamodel: '; nextPutAll: packageName; cr; cr.
	(packageName asPackage definedClasses asSortedCollection: [ :a :b | a name < b name ])
		do: [ :cls |
			s nextPutAll: '## '; nextPutAll: cls name.
			cls isTrait ifTrue: [ s nextPutAll: ' (Trait)' ].
			s cr; cr.
			cls isTrait ifFalse: [
				s nextPutAll: '- **Superclass:** `'; nextPutAll: cls superclass name; nextPutAll: '`'; cr ].
			cls traitComposition isEmpty ifFalse: [
				s nextPutAll: '- **Traits:** `'; nextPutAll: cls traitComposition printString; nextPutAll: '`'; cr ].
			cls slots
				ifEmpty: [ s nextPutAll: '- **Slots:** none'; cr ]
				ifNotEmpty: [ :slots |
					s nextPutAll: '- **Slots:**'; cr.
					slots do: [ :slot |
						s nextPutAll: '  - `'; nextPutAll: slot name; nextPutAll: '`'; cr ] ].
			s cr ] ].

Transcript open; clear; show: md.
Clipboard clipboardText: md.