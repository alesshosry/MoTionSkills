# MoTionSkills
Don't know how to use MoTion? Complicated DSL? No worries!
We have a solution for you. A way to benefit from AI so it will create patterns for you.
This is a book that helps you to create MoTion patterns using AI;

## MoTion
If you want the AI to know how to use MoTion you can refer to [this page](https://github.com/alesshosry/MoTionPatternsBook/blob/main/MoTion.md).

## FASTTypeScript(TypeScript AST) + MoTion
If you want to let the AI create patterns that match TypeScript AST using MoTion, you can ask it to refer to [this page](https://github.com/alesshosry/MoTionSkills/blob/main/references/FASTTypeScript-MoTion.md).

## FASTJava(Java AST) + MoTion
If you want to let the AI create patterns that match Java AST using MoTion, you can ask it to refer to [this page](https://github.com/alesshosry/MoTionSkills/blob/main/references/FASTJava-MoTion.md).

# Usage

## Manually

You can open any AI agent, provide it with the md files (better if you download the repo and upload the convinient files) and paste something like this message:

_Ok i Will give you 2 files to read: one that describe MoTion, which allows you to create a pattern to do pattern matching in Pharo over models. And another one that describes how to use MoTion with FASTTypeScript, which is a metamodel that allows you to represent the AST of TypeScript in Pharo. Inside this documentation, all FASTTypeScript classes that represent TypeScript entities are listed.
Given these two documentations, I want you to create an example of Typescript, that contains 3 methods in a class: one with switch case, one with if else, and one with other statements.
Then you create a pattern in MoTion to match the parsed typescript code that contain switch case_

This example was tested on Mistral AI (Without License), ChatGPT(Without license) and Copilot (with License). All three agents were able to generate the example and the pattern correctly except for one, with mini mini error in a property name.

## Using Skills

The repository also provides a reusable `SKILL.md` that can be used by AI coding agents such as Codex and Claude Code.

The skill automatically routes requests to the appropriate MoTion and FAST documentation:

- `MoTion.md` for general MoTion syntax and matching
- `FASTTypeScript-MoTion.md` for TypeScript AST patterns
- `FASTJava-MoTion.md` for Java AST patterns
- `FASTXML-MoTion.md` for XML AST patterns
- `MoTion-Transformation.md` for source code transformations

After installing the skill in an AI coding agent, the referenced documentation can be used automatically without uploading the files for every request.

# For the future:
- I will try to adapt it to be used in Pharo directly ... we are ambitious but will give it a try :)
- More documentations will be added for other FAST metamodels, and why not Famix also :)

Feel free to contribute :) 
