[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.22662698.svg)](https://doi.org/10.5281/zenodo.22662698)

# MoTionSkills
If you're here, this means you know Pharo and you're trying to use MoTion, but you need some help. Well, you're on the right track :)

Don't know how to use MoTion? Complicated DSL? No worries!
We have a solution for you. A way to benefit from Artificial Intelligence so it will create patterns for you.
This is a repo for a "skill" that helps you to create MoTion patterns using AI;
If you don't know the concept of skills, I recommend you to check this [article](https://support.claude.com/en/articles/12512176-what-are-skills). 

## Skill
The skill file includes a description of the skill, links to references, and other supporting material.
Most importantly, the skill has been tested, and the results were published in a [2026 paper](https://doi.org/10.5281/zenodo.22662698). The paper covers the testing process, the models evaluated, and the full set of findings.

Currently, the skill helps developers create patterns in MoTion, match them, and apply refactorings. Refactoring is the newest feature, added in 2026, and works by using bindings to transform the matched part. At the moment, the skill supports matching following metamodels:

- FASTTypeScript
- FASTJava
- FASTXML

Keep in mind that MoTion is not tied to a specific metamodel. It is dynamic and can perform pattern matching on any defined metamodel. Refactoring, however, is currently supported only for FAST metamodels.

<!-- ## MoTion
If you want the AI to know how to use MoTion you can refer to [this page](https://github.com/alesshosry/MoTionSkills/blob/main/references/MoTion.md).

## FASTTypeScript(TypeScript AST) + MoTion
If you want to let the AI create patterns that match TypeScript AST using MoTion, you can ask it to refer to [this page](https://github.com/alesshosry/MoTionSkills/blob/main/references/FASTTypeScript-MoTion.md).

## FASTJava(Java AST) + MoTion
If you want to let the AI create patterns that match Java AST using MoTion, you can ask it to refer to [this page](https://github.com/alesshosry/MoTionSkills/blob/main/references/FASTJava-MoTion.md).

## FASTXML(XML AST) + MoTion
If you want to let the AI create patterns that match XML using MoTion, you can ask it to refer to [this page](https://github.com/alesshosry/MoTionSkills/blob/WorkOfTrainee/references/FASTXML-MoTion.md). -->

# Usage

## Manually

You can use any platform such as ChatGPT, provide it with the md files (better if you download the repo and upload the convenient files) and write a prompt like this one:

_Ok i Will give you 2 files to read: one that describe MoTion, which allows you to create a pattern to do pattern matching in Pharo over models. And another one that describes how to use MoTion with FASTTypeScript, which is a metamodel that allows you to represent the AST of TypeScript in Pharo. Inside this documentation, all FASTTypeScript classes that represent TypeScript entities are listed. Given these two documentations, I want you to create an example of Typescript, that contains 3 methods in a class: one with switch case, one with if else, and one with other statements. Then you create a pattern in MoTion to match the parsed typescript code that contain switch case_

This example was tested on Mistral AI (Without License), ChatGPT(Without license) and Copilot (with License). All three LLMs given provided with the same files, were able to generate the example and the pattern correctly except for one, with mini mini error in a property name.

## Using Skills

The repository also provides a reusable `SKILL.md` that can be used by agents such as Codex and Claude Code.

Once the skill is called in the prompt _/skillName_, it is analyzed with the given prompt, and the appropriate references are fetched to reply to the user. For the moment, the available references are:

- `MoTion.md` for general MoTion syntax and matching features
- `FASTTypeScript-MoTion.md` for TypeScript AST patterns
- `FASTJava-MoTion.md` for Java AST patterns
- `FASTXML-MoTion.md` for XML AST patterns
- `MoTion-Transformation.md` for refactoring with MoTion

After installing the skill in an agent, the referenced documentation can be used automatically without uploading files for every request.

# For the future:
- I will try to adapt it to be used in Pharo directly ... we are ambitious but will give it a try :)
- More documentations will be added for other FAST metamodels, and why not Famix also :)

Feel free to contribute :) 