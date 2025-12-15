# Changelog

## [0.1.2](https://github.com/chiptoma/dotfiles-zsh/compare/dotfiles-zsh-v0.1.1...dotfiles-zsh-v0.1.2) (2025-12-15)


### Bug Fixes

* auto-install unzip when needed for yazi ([faf51ff](https://github.com/chiptoma/dotfiles-zsh/commit/faf51ffae840554be4f517d9c2849ee8a902233b))
* copy installation not copying dotfiles (.zshenv, .zshrc) ([37d0634](https://github.com/chiptoma/dotfiles-zsh/commit/37d063401708a63395560aa3ddaf5a6951916648))
* display prompt_choice menu when called in subshell ([11b2fde](https://github.com/chiptoma/dotfiles-zsh/commit/11b2fde334064829fbea1863071f69771bcfa520))
* don't offer symlink option in curl-pipe mode ([6a9c405](https://github.com/chiptoma/dotfiles-zsh/commit/6a9c4051e52bb111ae071136b35c28c9fb92f6c7))
* escape code interpretation in tool list display ([696b560](https://github.com/chiptoma/dotfiles-zsh/commit/696b56011956795eb591f33a026e7201b2138b78))
* prevent stdin read blocking in curl-pipe mode ([b702e40](https://github.com/chiptoma/dotfiles-zsh/commit/b702e4025b8c55a0eeeb59142842d8a08a3d5bcd))
* suppress /dev/tty redirect errors in curl-pipe mode ([6a224c0](https://github.com/chiptoma/dotfiles-zsh/commit/6a224c0616edd102059573e31d236f2c16daf020))
* unified tool counter and exec zsh in curl-pipe mode ([5a6ac3e](https://github.com/chiptoma/dotfiles-zsh/commit/5a6ac3e70ff7b76ab2f82f6e1a443f5b9d703958))
* use correct function name get_package_manager for unzip install ([d9d8a1e](https://github.com/chiptoma/dotfiles-zsh/commit/d9d8a1efe60517b5858d66e32828566cbdb9f2d5))


### Documentation

* fix CI badges and add complete installer options ([1f32562](https://github.com/chiptoma/dotfiles-zsh/commit/1f325622d432a71572b2e2c517bacca384b08961))

## [0.1.1](https://github.com/chiptoma/dotfiles-zsh/compare/dotfiles-zsh-v0.1.0...dotfiles-zsh-v0.1.1) (2025-12-11)


### Features

* add atuin config setup to installer ([eba8de7](https://github.com/chiptoma/dotfiles-zsh/commit/eba8de7dd32376473de4d662c3e572ffa7b0b2f3))
* add comprehensive CI validation jobs ([04dd44e](https://github.com/chiptoma/dotfiles-zsh/commit/04dd44ea8d6d20e600e89b635edc0acce7f91ed9))
* add installer lifecycle tests and hardening ([b516227](https://github.com/chiptoma/dotfiles-zsh/commit/b516227d94cc96c385c40037899673864b52284d))
* add interactive update prompt and auto-apply option ([40433ba](https://github.com/chiptoma/dotfiles-zsh/commit/40433bab15e2a7987070398cf1305d947bafae28))
* add starship prompt configuration ([1354fe3](https://github.com/chiptoma/dotfiles-zsh/commit/1354fe3d53ac673679197d2dc7af5a531a1ca06f))
* add unit tests, optimize compaudit, consolidate PATH management ([65892cc](https://github.com/chiptoma/dotfiles-zsh/commit/65892cc5ea531529cd506e49e3c267d24a4fa502))
* implement high-value improvements for 90% score ([39420d6](https://github.com/chiptoma/dotfiles-zsh/commit/39420d64bf309587223eee17ab5e899bb97f7749))
* improve installer UX with cleaner output and complete plugin setup ([f69ab28](https://github.com/chiptoma/dotfiles-zsh/commit/f69ab28527a0a7276b6d98a1cbf24cb6ff8afc92))
* install modern fzf and yazi from GitHub releases ([e1d423d](https://github.com/chiptoma/dotfiles-zsh/commit/e1d423da528291ce4546b74efd0da5b68a116b86))
* major installer improvements and HOMEBREW_PREFIX fix ([9fbec04](https://github.com/chiptoma/dotfiles-zsh/commit/9fbec04b4af239bbfcaa6d9f3e421f493417925c))
* simplify installation with auto-OMZ and add release automation ([d8d26cb](https://github.com/chiptoma/dotfiles-zsh/commit/d8d26cb8cde16616671f5986b4e9043162424394))


### Bug Fixes

* add /dev/tty fallback to remaining read calls ([fc51870](https://github.com/chiptoma/dotfiles-zsh/commit/fc518707cca0d90d8ec457a36c5c8d4d9536e9ec))
* add atuin bin directory to PATH ([c3a40a2](https://github.com/chiptoma/dotfiles-zsh/commit/c3a40a2959b18fe44f55956ecce59506f6d56716))
* add custom ZSH to PATH for version matrix tests ([a88bcf0](https://github.com/chiptoma/dotfiles-zsh/commit/a88bcf053250f323bc9df97712b47dcd5f89f329))
* add debug output to CI install step ([aaca2d6](https://github.com/chiptoma/dotfiles-zsh/commit/aaca2d6bff13533b5dcdc5b715c19b890adcd972))
* add directory listing aliases as fallbacks ([0aba42b](https://github.com/chiptoma/dotfiles-zsh/commit/0aba42bc1aa3d50b3e1beecaaf42373d987f57c6))
* add Homebrew PATH for macOS tool verification in CI ([500e778](https://github.com/chiptoma/dotfiles-zsh/commit/500e778ff5f880237d1dc5b0eac364a8fbf6e782))
* add lazy up-arrow binding for atuin history search ([c84729e](https://github.com/chiptoma/dotfiles-zsh/commit/c84729ec5d497b3b6af54c98d7f877cac94d68bc))
* add retries to GitHub binary downloads ([a8e7886](https://github.com/chiptoma/dotfiles-zsh/commit/a8e7886857aef57f64977f621e89eab3f51b42a9))
* address security and performance issues from code review ([96b2ae0](https://github.com/chiptoma/dotfiles-zsh/commit/96b2ae069ae143dab8a0bc8cf5efb161559ac56a))
* auto-detect non-interactive mode when stdin is not a tty ([77d9dfc](https://github.com/chiptoma/dotfiles-zsh/commit/77d9dfc487b8fd7b8ab3fd1c5cdfe672f60604b6))
* bind Ctrl+R to atuin when available, fzf as fallback ([5ad6bfe](https://github.com/chiptoma/dotfiles-zsh/commit/5ad6bfeafb893ae8d7c8cf6fa7b0cad1d2d1c7ac))
* check for unzip before installing yazi ([a162aee](https://github.com/chiptoma/dotfiles-zsh/commit/a162aeec4ec3826088f3ed1c9f45b4b4808e0e50))
* CI workflow - exclude zsh from shellcheck, remove unused vars ([b4e9f84](https://github.com/chiptoma/dotfiles-zsh/commit/b4e9f84c55c7789ad12d6212025d5ed63267a9c0))
* **ci:** add OMZ check and show debug output in smoke tests ([366162b](https://github.com/chiptoma/dotfiles-zsh/commit/366162b02060706c5bc239cc7d4c57f2cd632675))
* **ci:** install Oh My Zsh before running smoke tests ([913ba6a](https://github.com/chiptoma/dotfiles-zsh/commit/913ba6ae2f6cc47daba9fff8288601125e5ddf1d))
* **ci:** remove redundant OMZ install steps and fix smoke test ([9489d34](https://github.com/chiptoma/dotfiles-zsh/commit/9489d34c05f730e6b7463f2b4f17aea98e47ec97))
* **ci:** set ZDOTDIR for smoke tests and relax ShellCheck ([1e45c27](https://github.com/chiptoma/dotfiles-zsh/commit/1e45c27a7cf9a268d4ad0190d719b950e504d288))
* correct interactive input for install mode tests ([d1a8636](https://github.com/chiptoma/dotfiles-zsh/commit/d1a863663083ef706ac1c16bcf71f7aa085a8728))
* defer path initialization to pick up env overrides ([b55148d](https://github.com/chiptoma/dotfiles-zsh/commit/b55148dc11176af13c80b7929fe2cc5e1c7166a4))
* disable atuin lazy loading by default ([9155d44](https://github.com/chiptoma/dotfiles-zsh/commit/9155d44924f07699ca8426df12f68b331631bd70))
* env-isolation test - test shell behavior not installer with bad env ([81f5c3e](https://github.com/chiptoma/dotfiles-zsh/commit/81f5c3eb7b0798540850678ca99be735b925a0e2))
* handle read failures gracefully in CI environments ([1fec08e](https://github.com/chiptoma/dotfiles-zsh/commit/1fec08e96a086f393988fda379163f7afbd13670))
* install unzip via apt for yazi extraction ([ac4a264](https://github.com/chiptoma/dotfiles-zsh/commit/ac4a2645d8b92296afad7e1621b1242e89c1f200))
* installer tests - repair exit code and XDG env vars ([53cd029](https://github.com/chiptoma/dotfiles-zsh/commit/53cd0294ba2f7bd2e895f856a732371e792b85ac))
* installer tests - rollback and env isolation edge cases ([f3dfe8b](https://github.com/chiptoma/dotfiles-zsh/commit/f3dfe8b10d3e5261fc0744486083fa4933eaa639))
* installer tests - symlink handling and sudo HOME ([efa1835](https://github.com/chiptoma/dotfiles-zsh/commit/efa1835e1681f17bd0321eff276fc0afae387935))
* make installer interactive when piped via curl ([10d9d7f](https://github.com/chiptoma/dotfiles-zsh/commit/10d9d7fbed215c4b01028dc39dbc93b0b0154d02))
* move starship to enhanced category for default installation ([4e85ead](https://github.com/chiptoma/dotfiles-zsh/commit/4e85ead8b770c24c9ba3e571bd7806af7ec6c8dc))
* pass original arguments in curl-pipe re-exec ([7133feb](https://github.com/chiptoma/dotfiles-zsh/commit/7133febc40523d3a886b720ac7909ea146038f7e))
* pass ZDOTDIR correctly in minimal test ([afbc8db](https://github.com/chiptoma/dotfiles-zsh/commit/afbc8db7d6edf4410e940ee28b5f7a2655bb0f79))
* pre-install OMZ in installer lifecycle tests ([cea8e01](https://github.com/chiptoma/dotfiles-zsh/commit/cea8e0180b5c79e64e9a04e9f8960a1bcf5ab561))
* prevent OMZ reinstallation in CI workflows ([b09ef0e](https://github.com/chiptoma/dotfiles-zsh/commit/b09ef0e777bf0da7fc4f70940e018cf6c222c53c))
* prevent shell hang in non-interactive update check ([99c966a](https://github.com/chiptoma/dotfiles-zsh/commit/99c966a33df9e004adffacba8995b48d0fab80a8))
* remove .zshenv sourcing from bash verification steps ([2979dec](https://github.com/chiptoma/dotfiles-zsh/commit/2979dec7ab46fac131cd41e0e8fed65c9c744d83))
* remove deprecated macos-13 from CI matrix ([c08f6e0](https://github.com/chiptoma/dotfiles-zsh/commit/c08f6e087e6838a4540f4acdc0cae2ac5c636332))
* remove unused rollback_needed variable ([50df570](https://github.com/chiptoma/dotfiles-zsh/commit/50df570f801a073df15b8679e42815636e29f370))
* repair auto-fix with --yes and handle Ubuntu binary names ([0869676](https://github.com/chiptoma/dotfiles-zsh/commit/08696764fd4d6a5a5ccdeb48ee761ccb9cb9517d))
* resolve CI failures from shellcheck and OMZ plugin cloning ([906944d](https://github.com/chiptoma/dotfiles-zsh/commit/906944d1517dce432cbd0f2076e541ce24a226e7))
* resolve CI job failures ([fce7555](https://github.com/chiptoma/dotfiles-zsh/commit/fce75557c9a32dc9d2dbe4f5e584a5ac0db9f162))
* resolve minimal test ZDOTDIR and invalidate stale cache ([be515b3](https://github.com/chiptoma/dotfiles-zsh/commit/be515b3ad1a71e285d55b6dc241750797a90d936))
* respect pre-set ZDOTDIR in .zshenv ([c86a255](https://github.com/chiptoma/dotfiles-zsh/commit/c86a2552d8bc415784cb9b8ebf16de676ef72e79))
* respect ZSH_LAZY_ATUIN setting in environment.zsh ([e036eb4](https://github.com/chiptoma/dotfiles-zsh/commit/e036eb4b9d3d03fb39ecc9abba05ad704cc5f51d))
* set XDG_CONFIG_HOME in CI to match test HOME ([c15bdc2](https://github.com/chiptoma/dotfiles-zsh/commit/c15bdc2e3c2f4ad7e4712d629afcea3ddf58af57))
* simplify atuin integration, remove lazy binding artifacts ([a8fd06d](https://github.com/chiptoma/dotfiles-zsh/commit/a8fd06d79bf570532288e5b1031c9bae7c84f18e))
* skip zoxide lazy load when OMZ plugin already initialized ([0c54995](https://github.com/chiptoma/dotfiles-zsh/commit/0c54995ac203200e0e0c916e9704ea14fc15e7d9))
* **smoke-test:** use pattern matching to handle OMZ warnings ([a9bf1e6](https://github.com/chiptoma/dotfiles-zsh/commit/a9bf1e6ff35e5166b19db0803d8d6f203c92bea9))
* source ZDOTDIR/.zshenv from ~/.zshenv after setting ZDOTDIR ([4243b8b](https://github.com/chiptoma/dotfiles-zsh/commit/4243b8b6ccfa6fbcc585bc19b1608fd9d91fe050))
* support curl-pipe installation (curl ... | bash) ([9048149](https://github.com/chiptoma/dotfiles-zsh/commit/9048149fa0981e07862142855d453ceca5b9d1c9))
* update essential files paths in install.sh verification ([b6dd69c](https://github.com/chiptoma/dotfiles-zsh/commit/b6dd69cfad32d0e21d012e9ebc2bf581439df8c9))
* use &gt;| to override noclobber in update check ([411e790](https://github.com/chiptoma/dotfiles-zsh/commit/411e7902cbe64bc442f215fb1a3f66cf29af4b3f))
* use brighter gray (245) for starship prompt box chars ([1e0f1d1](https://github.com/chiptoma/dotfiles-zsh/commit/1e0f1d1f6cb0dcaa0cafcd35ffaf8249dd047129))
* use eval for zoxide lazy wrappers to avoid parse-time alias conflict ([ab7c76e](https://github.com/chiptoma/dotfiles-zsh/commit/ab7c76ee4fcd135e0434fc0da6532e91f13158c0))
* use maybe_sudo for containers, make optional tools non-fatal ([71af791](https://github.com/chiptoma/dotfiles-zsh/commit/71af79117e19b8a697d96470f2abc3af71872bd1))
* use Ubuntu 22.04 instead of 20.04 (deprecated runner) ([1f4843e](https://github.com/chiptoma/dotfiles-zsh/commit/1f4843e835e9f4f5763e1d630d0c5cefce851eec))


### Refactoring

* centralize all keybindings in keybindings.zsh ([7b4133b](https://github.com/chiptoma/dotfiles-zsh/commit/7b4133ba9e55382af5234ad0d5416af0bc156b88))
* **ci:** standardize workflows for consistency and best practices ([a0550a7](https://github.com/chiptoma/dotfiles-zsh/commit/a0550a713f1175d8b9b5a87e184e2341c30564a3))
* consolidate utils into lib/utils/ barrel structure ([88e9bab](https://github.com/chiptoma/dotfiles-zsh/commit/88e9bab151d560fb564c9c778b5b6fb7d3103738))
* deduplicate CI pipeline and improve weak tests ([80fda09](https://github.com/chiptoma/dotfiles-zsh/commit/80fda099bdc25486bc4c74452ccd0196732926d5))
* extract smoke tests, clean up CI workflow ([a5b31bd](https://github.com/chiptoma/dotfiles-zsh/commit/a5b31bdb8df5a1b65b2ffee2184fb29c97f84fba))
* implement POST_INTERACTIVE hook system ([31959fe](https://github.com/chiptoma/dotfiles-zsh/commit/31959fe40cc4c43830b6b1f8a77546cfc5d8a225))
* move starship/atuin init to environment.zsh ([95a50a6](https://github.com/chiptoma/dotfiles-zsh/commit/95a50a6a97f2399f1da94743cc0a44b0f325b03e))
* organize template files into examples/ folder ([ef5172e](https://github.com/chiptoma/dotfiles-zsh/commit/ef5172eaa4e8f479a7706dff1f793d30d09fdc8f))
* remove broken lazy loading for starship/atuin ([8f7fa95](https://github.com/chiptoma/dotfiles-zsh/commit/8f7fa95f71f963480d50967e7da80c29287eee29))
* remove dead code and unused functions ([24bff13](https://github.com/chiptoma/dotfiles-zsh/commit/24bff13d56047bd5c40ea7d9fb4164939b2713b7))
* rename local.zsh to .zshlocal and add tool configs ([92c6107](https://github.com/chiptoma/dotfiles-zsh/commit/92c6107f823d20b13ec14422636e59a98e015471))
* reorganize tool categories for better defaults ([19a1781](https://github.com/chiptoma/dotfiles-zsh/commit/19a17814d5d1935f29db1863c0621b4511e2f096))


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
* restructure workflows for comprehensive testing ([0d12c23](https://github.com/chiptoma/dotfiles-zsh/commit/0d12c23d49f932d06fb68206c5edcdd5fca7a59c))


### Testing

* comprehensive CI coverage for 95%+ real-world scenarios ([78a8f56](https://github.com/chiptoma/dotfiles-zsh/commit/78a8f5601931fca9f3709a26b77351a9cacd4a98))
