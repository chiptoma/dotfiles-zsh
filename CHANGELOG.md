# Changelog

## [0.1.1](https://github.com/chiptoma/dotfiles-zsh/compare/dotfiles-zsh-v0.1.0...dotfiles-zsh-v0.1.1) (2025-12-03)


### Features

* add comprehensive CI validation jobs ([04dd44e](https://github.com/chiptoma/dotfiles-zsh/commit/04dd44ea8d6d20e600e89b635edc0acce7f91ed9))
* add installer lifecycle tests and hardening ([b516227](https://github.com/chiptoma/dotfiles-zsh/commit/b516227d94cc96c385c40037899673864b52284d))
* add starship prompt configuration ([1354fe3](https://github.com/chiptoma/dotfiles-zsh/commit/1354fe3d53ac673679197d2dc7af5a531a1ca06f))
* add unit tests, optimize compaudit, consolidate PATH management ([65892cc](https://github.com/chiptoma/dotfiles-zsh/commit/65892cc5ea531529cd506e49e3c267d24a4fa502))
* improve installer UX with cleaner output and complete plugin setup ([f69ab28](https://github.com/chiptoma/dotfiles-zsh/commit/f69ab28527a0a7276b6d98a1cbf24cb6ff8afc92))
* install modern fzf and yazi from GitHub releases ([e1d423d](https://github.com/chiptoma/dotfiles-zsh/commit/e1d423da528291ce4546b74efd0da5b68a116b86))
* simplify installation with auto-OMZ and add release automation ([d8d26cb](https://github.com/chiptoma/dotfiles-zsh/commit/d8d26cb8cde16616671f5986b4e9043162424394))


### Bug Fixes

* add atuin bin directory to PATH ([c3a40a2](https://github.com/chiptoma/dotfiles-zsh/commit/c3a40a2959b18fe44f55956ecce59506f6d56716))
* add custom ZSH to PATH for version matrix tests ([a88bcf0](https://github.com/chiptoma/dotfiles-zsh/commit/a88bcf053250f323bc9df97712b47dcd5f89f329))
* add debug output to CI install step ([aaca2d6](https://github.com/chiptoma/dotfiles-zsh/commit/aaca2d6bff13533b5dcdc5b715c19b890adcd972))
* add directory listing aliases as fallbacks ([0aba42b](https://github.com/chiptoma/dotfiles-zsh/commit/0aba42bc1aa3d50b3e1beecaaf42373d987f57c6))
* add lazy up-arrow binding for atuin history search ([c84729e](https://github.com/chiptoma/dotfiles-zsh/commit/c84729ec5d497b3b6af54c98d7f877cac94d68bc))
* bind Ctrl+R to atuin when available, fzf as fallback ([5ad6bfe](https://github.com/chiptoma/dotfiles-zsh/commit/5ad6bfeafb893ae8d7c8cf6fa7b0cad1d2d1c7ac))
* check for unzip before installing yazi ([a162aee](https://github.com/chiptoma/dotfiles-zsh/commit/a162aeec4ec3826088f3ed1c9f45b4b4808e0e50))
* CI workflow - exclude zsh from shellcheck, remove unused vars ([b4e9f84](https://github.com/chiptoma/dotfiles-zsh/commit/b4e9f84c55c7789ad12d6212025d5ed63267a9c0))
* correct interactive input for install mode tests ([d1a8636](https://github.com/chiptoma/dotfiles-zsh/commit/d1a863663083ef706ac1c16bcf71f7aa085a8728))
* defer path initialization to pick up env overrides ([b55148d](https://github.com/chiptoma/dotfiles-zsh/commit/b55148dc11176af13c80b7929fe2cc5e1c7166a4))
* disable atuin lazy loading by default ([9155d44](https://github.com/chiptoma/dotfiles-zsh/commit/9155d44924f07699ca8426df12f68b331631bd70))
* install unzip via apt for yazi extraction ([ac4a264](https://github.com/chiptoma/dotfiles-zsh/commit/ac4a2645d8b92296afad7e1621b1242e89c1f200))
* pass ZDOTDIR correctly in minimal test ([afbc8db](https://github.com/chiptoma/dotfiles-zsh/commit/afbc8db7d6edf4410e940ee28b5f7a2655bb0f79))
* pre-install OMZ in installer lifecycle tests ([cea8e01](https://github.com/chiptoma/dotfiles-zsh/commit/cea8e0180b5c79e64e9a04e9f8960a1bcf5ab561))
* remove deprecated macos-13 from CI matrix ([c08f6e0](https://github.com/chiptoma/dotfiles-zsh/commit/c08f6e087e6838a4540f4acdc0cae2ac5c636332))
* remove unused rollback_needed variable ([50df570](https://github.com/chiptoma/dotfiles-zsh/commit/50df570f801a073df15b8679e42815636e29f370))
* resolve CI failures from shellcheck and OMZ plugin cloning ([906944d](https://github.com/chiptoma/dotfiles-zsh/commit/906944d1517dce432cbd0f2076e541ce24a226e7))
* resolve CI job failures ([fce7555](https://github.com/chiptoma/dotfiles-zsh/commit/fce75557c9a32dc9d2dbe4f5e584a5ac0db9f162))
* resolve minimal test ZDOTDIR and invalidate stale cache ([be515b3](https://github.com/chiptoma/dotfiles-zsh/commit/be515b3ad1a71e285d55b6dc241750797a90d936))
* respect pre-set ZDOTDIR in .zshenv ([c86a255](https://github.com/chiptoma/dotfiles-zsh/commit/c86a2552d8bc415784cb9b8ebf16de676ef72e79))
* respect ZSH_LAZY_ATUIN setting in environment.zsh ([e036eb4](https://github.com/chiptoma/dotfiles-zsh/commit/e036eb4b9d3d03fb39ecc9abba05ad704cc5f51d))
* set XDG_CONFIG_HOME in CI to match test HOME ([c15bdc2](https://github.com/chiptoma/dotfiles-zsh/commit/c15bdc2e3c2f4ad7e4712d629afcea3ddf58af57))
* simplify atuin integration, remove lazy binding artifacts ([a8fd06d](https://github.com/chiptoma/dotfiles-zsh/commit/a8fd06d79bf570532288e5b1031c9bae7c84f18e))
* skip zoxide lazy load when OMZ plugin already initialized ([0c54995](https://github.com/chiptoma/dotfiles-zsh/commit/0c54995ac203200e0e0c916e9704ea14fc15e7d9))
* source ZDOTDIR/.zshenv from ~/.zshenv after setting ZDOTDIR ([4243b8b](https://github.com/chiptoma/dotfiles-zsh/commit/4243b8b6ccfa6fbcc585bc19b1608fd9d91fe050))
* use &gt;| to override noclobber in update check ([411e790](https://github.com/chiptoma/dotfiles-zsh/commit/411e7902cbe64bc442f215fb1a3f66cf29af4b3f))
* use brighter gray (245) for starship prompt box chars ([1e0f1d1](https://github.com/chiptoma/dotfiles-zsh/commit/1e0f1d1f6cb0dcaa0cafcd35ffaf8249dd047129))
* use eval for zoxide lazy wrappers to avoid parse-time alias conflict ([ab7c76e](https://github.com/chiptoma/dotfiles-zsh/commit/ab7c76ee4fcd135e0434fc0da6532e91f13158c0))
* use maybe_sudo for containers, make optional tools non-fatal ([71af791](https://github.com/chiptoma/dotfiles-zsh/commit/71af79117e19b8a697d96470f2abc3af71872bd1))


### Refactoring

* extract smoke tests, clean up CI workflow ([a5b31bd](https://github.com/chiptoma/dotfiles-zsh/commit/a5b31bdb8df5a1b65b2ffee2184fb29c97f84fba))
* move starship/atuin init to environment.zsh ([95a50a6](https://github.com/chiptoma/dotfiles-zsh/commit/95a50a6a97f2399f1da94743cc0a44b0f325b03e))
* remove broken lazy loading for starship/atuin ([8f7fa95](https://github.com/chiptoma/dotfiles-zsh/commit/8f7fa95f71f963480d50967e7da80c29287eee29))


### Documentation

* fix useful commands table with correct aliases ([a166164](https://github.com/chiptoma/dotfiles-zsh/commit/a166164b05c4cb20dad9b490570bfb698914c3ed))


### Maintenance

* clean up redundant files and consolidate tests folder ([02e744c](https://github.com/chiptoma/dotfiles-zsh/commit/02e744c8185dfc6fb23e36936ea9c96e42c1fca9))
* initial commit ([763aa18](https://github.com/chiptoma/dotfiles-zsh/commit/763aa18bf2a4fe1e1d920d4cf4a9eb5b8dfbcaf3))


### CI/CD

* add Fedora/Arch testing, verify functions load ([8f8ee42](https://github.com/chiptoma/dotfiles-zsh/commit/8f8ee424bb26189733caf5cd2c81c1002b23dd17))
* add top 10% improvements - caching, benchmarks, minimal mode ([75d1d32](https://github.com/chiptoma/dotfiles-zsh/commit/75d1d3220a779a2be0ed6dc86f79050f9946435c))
* bump actions/checkout from 4 to 6 ([321fc4b](https://github.com/chiptoma/dotfiles-zsh/commit/321fc4b32277b4cb1001b8db500c51e2902826eb))
* bump actions/checkout from 4 to 6 ([1519e77](https://github.com/chiptoma/dotfiles-zsh/commit/1519e7743d974ca17869d014f5ad8235f61a859e))
* bump softprops/action-gh-release from 1 to 2 ([144a4cf](https://github.com/chiptoma/dotfiles-zsh/commit/144a4cf77bc68b25f3706f47203e0decbf2d98ae))
* bump softprops/action-gh-release from 1 to 2 ([adffeeb](https://github.com/chiptoma/dotfiles-zsh/commit/adffeeb40fa97a253110be7bc1a96572393437ec))
* install OMZ plugins, make smoke tests stricter ([fb83c0d](https://github.com/chiptoma/dotfiles-zsh/commit/fb83c0d0789380e595db1db070ece08727d231b9))
