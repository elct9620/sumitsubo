# Changelog

## [0.1.0-preview7](https://github.com/elct9620/sumitsubo/compare/v0.1.0-preview6...v0.1.0-preview7) (2026-09-03)


### Features

* **language:** say what adding a language costs, and answer the question Rust left open ([2dbd778](https://github.com/elct9620/sumitsubo/commit/2dbd77869b0e0fc5688f8b50e82697b480bcb1a1))


### Bug Fixes

* **source:** declare the seam's constant with one keyword everywhere ([815e927](https://github.com/elct9620/sumitsubo/commit/815e92735b0c614092dc3c4eff0617dc4e0798c8))

## [0.1.0-preview6](https://github.com/elct9620/sumitsubo/compare/v0.1.0-preview5...v0.1.0-preview6) (2026-09-01)


### ⚠ BREAKING CHANGES

* **marker:** say where a claim stands in front of nothing
* **contract:** find what holds a contract by the byte the name ends on
* **patterns:** match a pattern by the characters it was written in
* **language:** stop a Rust block comment at its closing delimiter
* **marker:** read a keyword the comment is written against
* **config:** refuse a switch that turns no specification off
* **config:** refuse a key .sumi.json does not say
* **config:** refuse a value no key in .sumi.json takes
* **glossary:** refuse a line set aside a second time under one word
* **glossary:** refuse a word rejected a second time under one term
* **glossary:** refuse a term declared a second time in one section
* **glossary:** refuse a second section opened under one name

### Features

* **behavior:** say when a marker is written with nothing behind it ([02e755d](https://github.com/elct9620/sumitsubo/commit/02e755d9dd9eb62df2192da18ebc84d08df8f883))
* **config:** refuse a key .sumi.json does not say ([0916f2c](https://github.com/elct9620/sumitsubo/commit/0916f2cdf7970ebb145359476eea6dde83a825b7))
* **config:** refuse a switch that turns no specification off ([0fd24c4](https://github.com/elct9620/sumitsubo/commit/0fd24c440fa842a33fa2e31945b2f22ab7656f51))
* **glossary:** refuse a second section opened under one name ([e8da675](https://github.com/elct9620/sumitsubo/commit/e8da67569db3e4f952db79681d8a235fadf6a861))
* **release:** carry the checksums a download can be verified against ([4401f19](https://github.com/elct9620/sumitsubo/commit/4401f19f1b2ec4948807e44235d45722a31197df))


### Bug Fixes

* **config:** refuse a value no key in .sumi.json takes ([7320ff7](https://github.com/elct9620/sumitsubo/commit/7320ff741cdf346325608f19a9178829a33c854a))
* **contract:** find what holds a contract by the byte the name ends on ([794a34c](https://github.com/elct9620/sumitsubo/commit/794a34cfc6565252ccf3cf83c75cb60dc5d5b724))
* **glossary:** refuse a line set aside a second time under one word ([7f83196](https://github.com/elct9620/sumitsubo/commit/7f8319692821aac117dcb66429e17fff22938001))
* **glossary:** refuse a term declared a second time in one section ([3be5a4c](https://github.com/elct9620/sumitsubo/commit/3be5a4c4cf4aa8744da20b6b7acfd07167c08c80))
* **glossary:** refuse a word rejected a second time under one term ([aa844e9](https://github.com/elct9620/sumitsubo/commit/aa844e9b7a0e2ee2c5136a0159b949d7a765a633))
* **language:** stop a Rust block comment at its closing delimiter ([fc9882f](https://github.com/elct9620/sumitsubo/commit/fc9882f53bb12eb849cc80538c6b095db9a47aca))
* **marker:** read a keyword the comment is written against ([ff7c86d](https://github.com/elct9620/sumitsubo/commit/ff7c86dae72ab6c4fa6c2bf103a47c03922df7cb))
* **marker:** read a keyword written against more than ASCII ([775e6da](https://github.com/elct9620/sumitsubo/commit/775e6da85a45638e9d92723727931390fefc8299))
* **marker:** say where a claim stands in front of nothing ([b6eff18](https://github.com/elct9620/sumitsubo/commit/b6eff187894c5e9358d1d5fdb9bc28dae6f97c66))
* **patterns:** match a pattern by the characters it was written in ([aaa100a](https://github.com/elct9620/sumitsubo/commit/aaa100ad5c1573976d199287cae9f9a604fc0f46))

## [0.1.0-preview5](https://github.com/elct9620/sumitsubo/compare/v0.1.0-preview4...v0.1.0-preview5) (2026-08-31)


### ⚠ BREAKING CHANGES

* **contract:** state a contract's attributes in a table beside it
* keep this project's specification where its prose already is
* **source:** `Sumitsubo::Source::Language` is built with the readings it carries rather than holding them itself, and each reading is built with a grammar.
* **specification:** a parser answers `blocks(paths, kinds)` rather than one method per kind of specification. A build carrying a format of its own hands over what a document is made of and leaves what it means to the form.
* let the shapes a reading answers with sit where they are compared
* `.spec/contract/*.json` is no longer read. Rewrite each definition as `.spec/contract/*.md` — `sumi help contract` has the form. A definition left in JSON is passed over in silence, so a run that suddenly finds nothing to compare is one whose contracts have not been rewritten yet.
* **contract:** compare a shape against the signature that registered it
* **contract:** let each contract say which language spells it
* **markdown:** read a contract's signature instead of guessing its spelling
* **behavior:** a feature written as JSON is refused. Write it as Markdown; `sumi help behavior` has the form.
* **glossary:** a vocabulary is written as Markdown at .spec/glossary.md. JSON is no longer read for one; `sumi init` lays down a Markdown seed, and a vocabulary declaring no section is one that checks nothing rather than a file refused.
* **parser:** let each kind of specification ask for its own blocks
* **parser:** let each kind of specification be read by its own
* **parser:** let the query hold every block the format has
* **behavior:** a behavior specification is written as Markdown. JSON is still read, so a project moves one file at a time, but the two must not name one scenario twice.
* **grammar:** let the grammars sit where they answer from
* **parser:** hand a parser the grammar it puts its query to
* **spec:** call the specification's reader a parser
* **spec:** name the reserved heading for what it bounds
* let the specification be the document it already was

### Features

* **behavior:** let the parsers say which files are specifications ([7a54fa8](https://github.com/elct9620/sumitsubo/commit/7a54fa8bda59d875dcfdd9b6f85a19585650cccb))
* **behavior:** read a feature from the format a person reads it in ([45d6a4a](https://github.com/elct9620/sumitsubo/commit/45d6a4a2323b138af4f607aeec8d0f2c774555b1))
* **behavior:** write the behaviors as the document a person reads ([359ec83](https://github.com/elct9620/sumitsubo/commit/359ec83638189759fefa783a8f94490259792a28))
* **binding:** carry the extent a capture already had ([a87d90b](https://github.com/elct9620/sumitsubo/commit/a87d90b676c5094b2f681de933e92202b2ecec12))
* **contract:** compare a shape against the signature that registered it ([8878662](https://github.com/elct9620/sumitsubo/commit/8878662cfa8bc8e04ddbee9722e58b7e2125eb6e))
* **contract:** let each contract say which language spells it ([5738437](https://github.com/elct9620/sumitsubo/commit/5738437d6a9b8ce381b979196d8431ef46468985))
* **contract:** let the parsers say which files register contracts ([ef72921](https://github.com/elct9620/sumitsubo/commit/ef729213df5d76436f3c41a170a76b06be924499))
* **contract:** say which language a name was looked for as ([8ee6d86](https://github.com/elct9620/sumitsubo/commit/8ee6d86070da26fc89a242328c872b05225c52f0))
* **contract:** state a contract's attributes in a table beside it ([94c2391](https://github.com/elct9620/sumitsubo/commit/94c23918a1355252154763ff5566c63bb1a872b7))
* **glossary:** write the vocabulary as the document a person reads ([4dbc791](https://github.com/elct9620/sumitsubo/commit/4dbc79111c85437bdcb9f5ff36aa5d6f55ac5ab0))
* **language:** read what a piece of text declares ([fadf2a3](https://github.com/elct9620/sumitsubo/commit/fadf2a38de96cbfce9f1c3d52ac5ebefc4eeb6b5))
* **markdown:** read a contract's signature instead of guessing its spelling ([f00d385](https://github.com/elct9620/sumitsubo/commit/f00d385230a50a05dad86d98313586de35ff77e5))
* **parser:** let the query hold every block the format has ([6ae7cdb](https://github.com/elct9620/sumitsubo/commit/6ae7cdb0fa3141f9d4b7ebd025d515d3ab08948f))
* **parser:** read a definition written as Markdown ([e37b46c](https://github.com/elct9620/sumitsubo/commit/e37b46c78655b772660b0b45a27dfacc79fac574))
* **parser:** read a vocabulary written as Markdown ([d887358](https://github.com/elct9620/sumitsubo/commit/d88735878641b17711fc70e9e4f21600301974a4))
* read a specification only in the format a person reads it in ([ddf3222](https://github.com/elct9620/sumitsubo/commit/ddf3222d4834f5125f59e64363c5603922ff2f4b))
* **source:** read a constant assigned a call with a block as a scope ([30d0753](https://github.com/elct9620/sumitsubo/commit/30d0753005c364b04582d46fd96e63a51f20630a))
* **spec:** declare what reading a Markdown specification promises ([5203cdd](https://github.com/elct9620/sumitsubo/commit/5203cdd5ad7ad2c0daf16089944e66c2111f9a20))
* **specification:** read a document into blocks a form can read ([9a2d08c](https://github.com/elct9620/sumitsubo/commit/9a2d08c26beafb3a8e7a2268525ca066a1a768f5))
* **spec:** read a Markdown specification into the shape a mechanism judges ([606df4f](https://github.com/elct9620/sumitsubo/commit/606df4f3f25360afd590e8cf08ba6611576340e7))


### Performance Improvements

* **binding:** hold every query a program writes ([2521f04](https://github.com/elct9620/sumitsubo/commit/2521f04408fbc7fc919390f5a2d9bd2983278767))


### Code Refactoring

* **grammar:** let the grammars sit where they answer from ([c0e9df9](https://github.com/elct9620/sumitsubo/commit/c0e9df9cde95f886acbb3621d125f3b79444452f))
* keep this project's specification where its prose already is ([cf5e02e](https://github.com/elct9620/sumitsubo/commit/cf5e02e547d3eb2844a5012eec5ca1773911de77))
* let the shapes a reading answers with sit where they are compared ([c89eb7e](https://github.com/elct9620/sumitsubo/commit/c89eb7ef6000aebf946fbb7f1ebf3fd8ffdd4e4d))
* let the specification be the document it already was ([2f847be](https://github.com/elct9620/sumitsubo/commit/2f847be164c034dadc33f872265f0ff550dfb06c))
* **parser:** hand a parser the grammar it puts its query to ([6411222](https://github.com/elct9620/sumitsubo/commit/6411222c1b2fa857aa3532bc2b4e1865724ae105))
* **parser:** let each kind of specification ask for its own blocks ([0154130](https://github.com/elct9620/sumitsubo/commit/0154130631494cdf4f114b93df30809099f826f8))
* **parser:** let each kind of specification be read by its own ([dda365f](https://github.com/elct9620/sumitsubo/commit/dda365f91aa3aa59d243349c7059f04b49555cfe))
* **source:** hand a reading the grammar it puts its queries to ([70bbc62](https://github.com/elct9620/sumitsubo/commit/70bbc62a989f63995151d0b933401cc260f1d565))
* **spec:** call the specification's reader a parser ([1381979](https://github.com/elct9620/sumitsubo/commit/13819791ae9f347979fe983b53cd8d46bfcc8051))
* **spec:** name the reserved heading for what it bounds ([37632f2](https://github.com/elct9620/sumitsubo/commit/37632f2807373acb2cd1fa733e4182656de98e8d))

## [0.1.0-preview4](https://github.com/elct9620/sumitsubo/compare/v0.1.0-preview3...v0.1.0-preview4) (2026-08-24)


### ⚠ BREAKING CHANGES

* **contract:** let an include say which names a definition spells
* **contract:** let an include say what a definition answers for
* **behavior:** let an include say what a feature answers for

### Bug Fixes

* **behavior:** let an include say what a feature answers for ([9c41cfe](https://github.com/elct9620/sumitsubo/commit/9c41cfef806f492c147c0a7bad309d1c95fbf3fc))
* **contract:** let an include say what a definition answers for ([11d5ad2](https://github.com/elct9620/sumitsubo/commit/11d5ad26809bb4655c5f48a2511e906d4ef017e3))
* **contract:** let an include say which names a definition spells ([bcfa0d7](https://github.com/elct9620/sumitsubo/commit/bcfa0d76a0a02d615b0e2623680dd0ac730568e6))
* say a finding searched what the specification includes, not which globs ([cdbd142](https://github.com/elct9620/sumitsubo/commit/cdbd14207fe86ef69a60cc11e1d2a5db6420a957))

## [0.1.0-preview3](https://github.com/elct9620/sumitsubo/compare/v0.1.0-preview2...v0.1.0-preview3) (2026-08-23)


### Features

* **config:** let a project say which paths are not its source ([a23e9ae](https://github.com/elct9620/sumitsubo/commit/a23e9aec50a90019fb54c1131d8cd68ea2dd9612))
* **config:** take what the .gitignore already says as said ([1261e57](https://github.com/elct9620/sumitsubo/commit/1261e57ca80a6150b04eef6f8397f07ccd5285a4))
* **exclusion:** let the same rules say what a run reads ([05b7fcc](https://github.com/elct9620/sumitsubo/commit/05b7fcc65c30e5898d1192c6b0f084048ca10e0c))
* **scope:** walk for the files an include covers, rather than glob for them ([eeaa8f6](https://github.com/elct9620/sumitsubo/commit/eeaa8f610f6cf7c792d4e60136d74a3e023acf70))


### Bug Fixes

* refuse to certify an include that covers no file ([0a94023](https://github.com/elct9620/sumitsubo/commit/0a940232b68f06b2127045871a549a6f4adfd037))
* **scope:** refuse an excluded directory rather than walk it ([1dc960e](https://github.com/elct9620/sumitsubo/commit/1dc960eae5ac39863ebd4cc6e91cb5876185f3c1))

## [0.1.0-preview2](https://github.com/elct9620/sumitsubo/compare/v0.1.0-preview1...v0.1.0-preview2) (2026-08-23)


### Features

* **glossary:** let a rejection carry the places it is wrong ([5a90ad5](https://github.com/elct9620/sumitsubo/commit/5a90ad5b4146ace097bdf60014b412fa15ff2d80))
* **glossary:** let the vocabulary hold its own file to its words ([a1e6bae](https://github.com/elct9620/sumitsubo/commit/a1e6bae2582e7b05e5c7cfc38be58dbe58b0d083))
* **release:** publish the executables as an image ([2241557](https://github.com/elct9620/sumitsubo/commit/2241557c8be9a26cf4cc5612d721beb2e8d34f85))


### Bug Fixes

* **release:** hand back an executable that is still executable ([e797f9d](https://github.com/elct9620/sumitsubo/commit/e797f9df3f1a5ce7297d62a7a79b9823aa39202c))
* **release:** let the chain hand down the registry it needs ([2a89b4f](https://github.com/elct9620/sumitsubo/commit/2a89b4fc8b402d01b6f80bb9fdb92a4f37cc6a83))

## [0.1.0-preview1](https://github.com/elct9620/sumitsubo/compare/v0.1.0-preview0...v0.1.0-preview1) (2026-08-22)


### Features

* **behavior:** give a feature the same prose its contracts carry ([0653ecc](https://github.com/elct9620/sumitsubo/commit/0653eccf6e1ebd65510aa2704cc226eb5ed2ba99))
* **behavior:** read the scenarios a project declares, and where each sits ([746ac4c](https://github.com/elct9620/sumitsubo/commit/746ac4c02cc9779153abd154fdc341c9c79f30ac))
* **build:** stamp the executable with the revision it was built from ([4e49817](https://github.com/elct9620/sumitsubo/commit/4e49817321d5bc2affe4bc91908c0d1796487ec2))
* **cli:** answer -v with the version, everything else with help ([1c0ce38](https://github.com/elct9620/sumitsubo/commit/1c0ce3893807edec2dad504b388722322083eecc))
* **cli:** explain how to write a specification from the executable ([2b6c5e3](https://github.com/elct9620/sumitsubo/commit/2b6c5e33dfff15d4a170298614eee9612b02506f))
* **cli:** let the version line carry the revision it was built from ([04c6019](https://github.com/elct9620/sumitsubo/commit/04c601991c8cef1a45da10bbe0eef2298ad05b4b))
* **cli:** open with a command, and let init lay the reference line ([0959308](https://github.com/elct9620/sumitsubo/commit/095930884d66c4bf68391fac1482d6d4df6c1c56))
* **config:** read where a project keeps its specifications ([7fd517d](https://github.com/elct9620/sumitsubo/commit/7fd517d774eb713029323cad598aa9e11646cb1f))
* **config:** read where the rendered specification goes, and what to render ([66b6d1a](https://github.com/elct9620/sumitsubo/commit/66b6d1a996ce428b67acdcbf045a9cf1249503bf))
* **contract:** compare an interface against the shape it registers ([666a454](https://github.com/elct9620/sumitsubo/commit/666a45446941384ccd5273fca7d20ad40bd7ee14))
* **contract:** give each command the paragraph its usage needs ([f5ba75b](https://github.com/elct9620/sumitsubo/commit/f5ba75b211ed4e3f07e0510557478063f7f1eafe))
* **contract:** let a definition be read from the syntax tree ([fdca5c0](https://github.com/elct9620/sumitsubo/commit/fdca5c012a9253aec2ac9ba341a2b79b6685cdd1))
* **contract:** let a project keep an interface without publishing it ([7474053](https://github.com/elct9620/sumitsubo/commit/7474053e8eb464ea889377e9517224d3f70469e5))
* **contract:** let a specification carry the prose its document needs ([f958ff7](https://github.com/elct9620/sumitsubo/commit/f958ff7ffcab5b12b876b1d14cc0a28b5e6c57ad))
* **contract:** let the reading that spells names say which language spells them ([62b03b7](https://github.com/elct9620/sumitsubo/commit/62b03b7f0c94a96b9c745f0d72231d06af598aea))
* **contract:** read the interfaces a project registers ([4e2a45f](https://github.com/elct9620/sumitsubo/commit/4e2a45fd1455f81bd3c0f7623318ba818ec32d90))
* **declaration:** read the names a piece of source declares ([f5f2164](https://github.com/elct9620/sumitsubo/commit/f5f2164d7af6cbb9f430e64c910430afb7e125c5))
* **definitions:** read the parameters a method takes ([54a9674](https://github.com/elct9620/sumitsubo/commit/54a96740d55b572977175c1398a5105d21f8d49f))
* **glossary:** hold the tests to the words the library is held to ([769257c](https://github.com/elct9620/sumitsubo/commit/769257c48fb39e4ba84b2a549c8016aa679c9303))
* **glossary:** read the specification and resolve it per file ([bbc9f18](https://github.com/elct9620/sumitsubo/commit/bbc9f18731e9faaae7996e407d5cf59ee794994c))
* **glossary:** verify the source against the vocabulary it is scoped to ([603b334](https://github.com/elct9620/sumitsubo/commit/603b334791c96aee86139fd7f3951fd2de1b1e90))
* **glossary:** verify what a person wrote, not what the language spelled ([ae463f8](https://github.com/elct9620/sumitsubo/commit/ae463f8e8f2cf285d05cb511c0941d6fc56846de))
* **init:** lay down somewhere for the behaviour specifications to go ([a576d43](https://github.com/elct9620/sumitsubo/commit/a576d4376287a60da4253aaa68f5d320041e6b60))
* **language:** read Rust for its comments, its claims and what it declares ([bd19525](https://github.com/elct9620/sumitsubo/commit/bd19525bdf5f77fd74017a5d424c2181e7b60352))
* **marker:** read what a piece of source claims to implement ([7b848f2](https://github.com/elct9620/sumitsubo/commit/7b848f2873fa061ac831e872a69dd1a1d51cd93f))
* **render:** show the shape an interface is reached by ([397b658](https://github.com/elct9620/sumitsubo/commit/397b65883180b6b41815d6ecfef93086a33358e5))
* **render:** write the structured specification out as something to read ([fa938ba](https://github.com/elct9620/sumitsubo/commit/fa938ba2e1306269e97a77cb815032b4fb737b76))
* **spec:** hold the contract specifications to the vocabulary too ([378c9f4](https://github.com/elct9620/sumitsubo/commit/378c9f400b5f534f4d17455825b11cbed1a7560f))
* **spec:** let the vocabulary check its own definitions ([c2856d9](https://github.com/elct9620/sumitsubo/commit/c2856d9d61d4e6384771d9c6830ebbfbc3168a2c))
* **spec:** move the vocabulary to where the tool can check it ([1cd0151](https://github.com/elct9620/sumitsubo/commit/1cd0151409a6c543ec06f8d7cfa6ae9b396313cf))
* **spec:** register the commands this executable answers ([04a95f4](https://github.com/elct9620/sumitsubo/commit/04a95f469b0759b335f4d43ce11c02ced0e460de))
* **spec:** register the seams this project means to keep ([6f65851](https://github.com/elct9620/sumitsubo/commit/6f65851891eaafe5e1546f8b0f98349fb8e4a547))
* **spec:** register the shape each seam is reached by ([310c59a](https://github.com/elct9620/sumitsubo/commit/310c59aebec45b6596754c20addee5f64f111275))
* **spec:** start the reference line Sumitsubo verifies itself against ([1200fee](https://github.com/elct9620/sumitsubo/commit/1200feebfbde62bf5af5f44f20e12cf677f3378c))
* **treesitter:** let a capture say which one it is and what it came with ([9fe696d](https://github.com/elct9620/sumitsubo/commit/9fe696d8b235f8c0d0063b886d26f3bb9dcd80be))
* **treesitter:** read Ruby through a grammar linked into the build ([2054d46](https://github.com/elct9620/sumitsubo/commit/2054d46f856e9c1400d8562803a146d275ae5e1c))
* **verify:** compare the behaviours declared against the ones claimed ([131eef4](https://github.com/elct9620/sumitsubo/commit/131eef45d071ef47269ec822345589038ae1bb5f))
* **verify:** compare the contracts registered against the ones claimed ([ea39bc0](https://github.com/elct9620/sumitsubo/commit/ea39bc073b4137c23724f23d9a7913ef346e5521))
* **verify:** lead a finding with the word that would claim it ([cf62db1](https://github.com/elct9620/sumitsubo/commit/cf62db1fd1499821914c71825b3458871696e218))
* **verify:** run against the configuration, from wherever it is invoked ([6645386](https://github.com/elct9620/sumitsubo/commit/664538604e3e1fd0b5d4cbc4b84373c092a25ff4))
* **verify:** say what the syntax tree reading cannot see ([7787b5e](https://github.com/elct9620/sumitsubo/commit/7787b5e28aa44bac1fa7eb989c4d121e00039074))
* **verify:** send a specification that will not load to the form ([86dad5e](https://github.com/elct9620/sumitsubo/commit/86dad5e88c0b04d3645b0fe8e6d264125d12d17e))


### Bug Fixes

* **cli:** refuse what the run could not make of its arguments ([f1893b5](https://github.com/elct9620/sumitsubo/commit/f1893b5d6215d6e209b28d426ce9a6f0a2e839a5))
* **contract:** say what init lays down, per mechanism ([d98a92d](https://github.com/elct9620/sumitsubo/commit/d98a92d38713fea57d216739a0d245cfe062cd2f))
* **contract:** stop telling a Rust project why a Ruby method went missing ([c87a98a](https://github.com/elct9620/sumitsubo/commit/c87a98a32a772715bb489fc8c6946920d16fb8d1))
* **contract:** take each name from where the one before it was found ([47b6066](https://github.com/elct9620/sumitsubo/commit/47b606687a2f645e98824776f3a878f97d63b507))
* **definitions:** spell a reopened singleton method as the class's own ([135aa30](https://github.com/elct9620/sumitsubo/commit/135aa30f80a0c6120c208f1f752f3d2bde94e093))
* **glossary:** answer a broken reference line where the reader can go ([515edda](https://github.com/elct9620/sumitsubo/commit/515edda78aa5aaf7452077d6758e94e38809854e))
* **glossary:** compose the path with an operator Pathname answers ([5fa549c](https://github.com/elct9620/sumitsubo/commit/5fa549c37c28d65b5f541c787ca8771adec9ca98))
* **render:** keep a document's path out of the Struct that loses it ([e07f1a5](https://github.com/elct9620/sumitsubo/commit/e07f1a556cc5212f7d04a7aa982098caa4bb74c8))
* **spec:** give every declaration on a line somewhere to answer ([beb4465](https://github.com/elct9620/sumitsubo/commit/beb446582c7cf4c5064a503563a6887f5eaf5bb4))
* **verify:** let a mechanism that cannot be read stop only itself ([0063e30](https://github.com/elct9620/sumitsubo/commit/0063e3099994a4320161e6e4c81fd4d1cb46d743))
