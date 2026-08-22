# Changelog

## [0.1.0-preview2](https://github.com/elct9620/sumitsubo/compare/v0.1.0-preview1...v0.1.0-preview2) (2026-08-22)


### Features

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
