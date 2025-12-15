# Changelog

## [0.1.2](https://github.com/chiptoma/dotfiles-zsh/compare/dotfiles-zsh-v0.1.1...dotfiles-zsh-v0.1.2) (2025-12-15)


### Features

* add atuin config setup to installer ([586fc61](https://github.com/chiptoma/dotfiles-zsh/commit/586fc61a1098ee0e887fd960481b1c63915ef224))
* add comprehensive CI validation jobs ([e2547c1](https://github.com/chiptoma/dotfiles-zsh/commit/e2547c13f05aa5481edd851c4b45216ea929d9da))
* add installer lifecycle tests and hardening ([6bb7f4a](https://github.com/chiptoma/dotfiles-zsh/commit/6bb7f4a101baf233fb2b89d40a9c6c08b66a07a3))
* add interactive update prompt and auto-apply option ([5c277ad](https://github.com/chiptoma/dotfiles-zsh/commit/5c277adb30c74741c850e0032b781da2188006cd))
* add starship prompt configuration ([4207b52](https://github.com/chiptoma/dotfiles-zsh/commit/4207b52572e0e530e1dfce07ad14b48603b36ed5))
* add unit tests, optimize compaudit, consolidate PATH management ([ecc48dd](https://github.com/chiptoma/dotfiles-zsh/commit/ecc48dd8588a5b7ca6dbdecc72eb6f89cae5c215))
* implement high-value improvements for 90% score ([31c86bd](https://github.com/chiptoma/dotfiles-zsh/commit/31c86bdb1b1d0d08b0b2b7d979021989544edbad))
* improve installer UX with cleaner output and complete plugin setup ([c3b4d05](https://github.com/chiptoma/dotfiles-zsh/commit/c3b4d0514712b2ce6471513b348c1c180999b5d2))
* install modern fzf and yazi from GitHub releases ([80e17cd](https://github.com/chiptoma/dotfiles-zsh/commit/80e17cdbe781c448f2664cbb2d498ba8a2b502c5))
* major installer improvements and HOMEBREW_PREFIX fix ([65cbe2f](https://github.com/chiptoma/dotfiles-zsh/commit/65cbe2ff1a876a32947576f18da9a481750c1690))
* simplify installation with auto-OMZ and add release automation ([0cca4e9](https://github.com/chiptoma/dotfiles-zsh/commit/0cca4e9c30d3d8b737524716b394a7a560ea4c9d))


### Bug Fixes

* add /dev/tty fallback to remaining read calls ([9bd0d55](https://github.com/chiptoma/dotfiles-zsh/commit/9bd0d55c3a676f0149e30e0a399f2c16f7e02bf8))
* add atuin bin directory to PATH ([c6419d3](https://github.com/chiptoma/dotfiles-zsh/commit/c6419d35573e056330732ebc425d4ac3abe486bc))
* add custom ZSH to PATH for version matrix tests ([5d00e13](https://github.com/chiptoma/dotfiles-zsh/commit/5d00e13f039a1f89ca08184110ea97d0cc0e2ec0))
* add debug output to CI install step ([aaca2d6](https://github.com/chiptoma/dotfiles-zsh/commit/aaca2d6bff13533b5dcdc5b715c19b890adcd972))
* add directory listing aliases as fallbacks ([f16c074](https://github.com/chiptoma/dotfiles-zsh/commit/f16c074cab671361e0447ed0396a9201d3f0a951))
* add Homebrew PATH for macOS tool verification in CI ([0551379](https://github.com/chiptoma/dotfiles-zsh/commit/055137972b0bc449ebff904248237b997c9d0a73))
* add lazy up-arrow binding for atuin history search ([781b886](https://github.com/chiptoma/dotfiles-zsh/commit/781b8861a51894599f1e340e26fa8ac21d177fb7))
* add retries to GitHub binary downloads ([ec3bd57](https://github.com/chiptoma/dotfiles-zsh/commit/ec3bd57814904301e392394f14da4fc7cda98ccc))
* address security and performance issues from code review ([29537af](https://github.com/chiptoma/dotfiles-zsh/commit/29537afac1d49f0bcd8cb95014f6d2a2494de1bb))
* auto-detect non-interactive mode when stdin is not a tty ([2f03d7c](https://github.com/chiptoma/dotfiles-zsh/commit/2f03d7cde917d31da188bfc0c11b9cfa3a684f3c))
* auto-install unzip when needed for yazi ([457fe76](https://github.com/chiptoma/dotfiles-zsh/commit/457fe763c41633ffb54c1d642324bef456e24033))
* bind Ctrl+R to atuin when available, fzf as fallback ([ca4565d](https://github.com/chiptoma/dotfiles-zsh/commit/ca4565d6c4818fbcc6e1cf3f381318f0894e6894))
* check for unzip before installing yazi ([3adcb39](https://github.com/chiptoma/dotfiles-zsh/commit/3adcb398154c475b06edbbf2acac39458afb14c2))
* CI workflow - exclude zsh from shellcheck, remove unused vars ([b4e9f84](https://github.com/chiptoma/dotfiles-zsh/commit/b4e9f84c55c7789ad12d6212025d5ed63267a9c0))
* **ci:** add OMZ check and show debug output in smoke tests ([1987a28](https://github.com/chiptoma/dotfiles-zsh/commit/1987a2806cb330ad149cc04f60cd6e604b82bd3e))
* **ci:** install Oh My Zsh before running smoke tests ([3601de0](https://github.com/chiptoma/dotfiles-zsh/commit/3601de07bbe4cf2cf5d74cf51279d8e9b2cf0c81))
* **ci:** remove redundant OMZ install steps and fix smoke test ([7f7b889](https://github.com/chiptoma/dotfiles-zsh/commit/7f7b889e864d6bc4793d1dbe67c2dd62c9bcbc27))
* **ci:** set ZDOTDIR for smoke tests and relax ShellCheck ([79a2303](https://github.com/chiptoma/dotfiles-zsh/commit/79a2303413a9bb5271c7c94d9c1b4d2cd48a3dbe))
* copy installation not copying dotfiles (.zshenv, .zshrc) ([81550d7](https://github.com/chiptoma/dotfiles-zsh/commit/81550d708de42e4f4da36cc7c2243c0da2adb089))
* correct interactive input for install mode tests ([3b292e7](https://github.com/chiptoma/dotfiles-zsh/commit/3b292e7d0305f8b4ed20997fc42b85a9d4a05c0a))
* defer path initialization to pick up env overrides ([b55148d](https://github.com/chiptoma/dotfiles-zsh/commit/b55148dc11176af13c80b7929fe2cc5e1c7166a4))
* disable atuin lazy loading by default ([8a6f384](https://github.com/chiptoma/dotfiles-zsh/commit/8a6f384eda88016c2a3d3930dd7ba8173bcfff0e))
* display prompt_choice menu when called in subshell ([4f7e142](https://github.com/chiptoma/dotfiles-zsh/commit/4f7e142b8f79e7d9604745211fed52a58f78b719))
* don't offer symlink option in curl-pipe mode ([aeea16b](https://github.com/chiptoma/dotfiles-zsh/commit/aeea16b5610b09b76f92a47febe4261f20ce406e))
* env-isolation test - test shell behavior not installer with bad env ([b108f79](https://github.com/chiptoma/dotfiles-zsh/commit/b108f792d6765f9a7feef70a9b0f869d1b1c3493))
* escape code interpretation in tool list display ([ed74660](https://github.com/chiptoma/dotfiles-zsh/commit/ed7466081001034c78368aed535ccbad1f4267af))
* handle read failures gracefully in CI environments ([6767597](https://github.com/chiptoma/dotfiles-zsh/commit/6767597e1df1d0f83843318a8428034c27c9cd7b))
* install unzip via apt for yazi extraction ([4ac3eb7](https://github.com/chiptoma/dotfiles-zsh/commit/4ac3eb7cc65cb02aeb12926dd2ff25d4dafc485c))
* installer tests - repair exit code and XDG env vars ([14c8822](https://github.com/chiptoma/dotfiles-zsh/commit/14c88226ef5ca2bedc909280770d0bda74da586a))
* installer tests - rollback and env isolation edge cases ([e87f205](https://github.com/chiptoma/dotfiles-zsh/commit/e87f205f2d792cc4d76040f0ca97e257242cdadd))
* installer tests - symlink handling and sudo HOME ([3b1787f](https://github.com/chiptoma/dotfiles-zsh/commit/3b1787fb75247a20079a39042fbc9785362eadf3))
* make installer interactive when piped via curl ([8d98c0c](https://github.com/chiptoma/dotfiles-zsh/commit/8d98c0c443868b25fcad5d82a52bc348d52457b1))
* move starship to enhanced category for default installation ([3a05b91](https://github.com/chiptoma/dotfiles-zsh/commit/3a05b9118cbee7bb2baee950281041d8b8e5e016))
* pass original arguments in curl-pipe re-exec ([d6278f2](https://github.com/chiptoma/dotfiles-zsh/commit/d6278f2f631be7ccee5e8e2244ff6cd3fd2443db))
* pass ZDOTDIR correctly in minimal test ([afbc8db](https://github.com/chiptoma/dotfiles-zsh/commit/afbc8db7d6edf4410e940ee28b5f7a2655bb0f79))
* pre-install OMZ in installer lifecycle tests ([2531f57](https://github.com/chiptoma/dotfiles-zsh/commit/2531f57e0a61ff578771158223d4ec9cfdc27198))
* prevent OMZ reinstallation in CI workflows ([19c43eb](https://github.com/chiptoma/dotfiles-zsh/commit/19c43eb2783d9c481b4ca19f187e4d88562b44d2))
* prevent shell hang in non-interactive update check ([ea7ccc9](https://github.com/chiptoma/dotfiles-zsh/commit/ea7ccc902031282460ccee38ca415b4f09b96b03))
* prevent stdin read blocking in curl-pipe mode ([0152d6d](https://github.com/chiptoma/dotfiles-zsh/commit/0152d6d98ee8258bc3e0d0f98d3a4636f995e1a1))
* remove .zshenv sourcing from bash verification steps ([dee6e23](https://github.com/chiptoma/dotfiles-zsh/commit/dee6e23306bef489a6f1d6d59375e37bd4799648))
* remove deprecated macos-13 from CI matrix ([c08f6e0](https://github.com/chiptoma/dotfiles-zsh/commit/c08f6e087e6838a4540f4acdc0cae2ac5c636332))
* remove unused rollback_needed variable ([a425a1d](https://github.com/chiptoma/dotfiles-zsh/commit/a425a1dd7af769a2c5d0c85a295ce73ec7c4a922))
* repair auto-fix with --yes and handle Ubuntu binary names ([80ee235](https://github.com/chiptoma/dotfiles-zsh/commit/80ee235570d465781dfc7ff87413229407d7f0f8))
* resolve CI failures from shellcheck and OMZ plugin cloning ([4df7add](https://github.com/chiptoma/dotfiles-zsh/commit/4df7adde00ad3d1fa16c2f47cb5f312acc422de3))
* resolve CI job failures ([8274ae2](https://github.com/chiptoma/dotfiles-zsh/commit/8274ae271cefb62e89818ed1bca1f095e74bcf88))
* resolve minimal test ZDOTDIR and invalidate stale cache ([6cf5800](https://github.com/chiptoma/dotfiles-zsh/commit/6cf58003811c8b5352f86f8f29296a062c49e3a8))
* respect pre-set ZDOTDIR in .zshenv ([4f1d8ee](https://github.com/chiptoma/dotfiles-zsh/commit/4f1d8ee011c6ac9f9a044b1be34c84d77a2fe18e))
* respect ZSH_LAZY_ATUIN setting in environment.zsh ([81236c8](https://github.com/chiptoma/dotfiles-zsh/commit/81236c807dcb19914131ea4de922d3170b32b61d))
* set XDG_CONFIG_HOME in CI to match test HOME ([c15bdc2](https://github.com/chiptoma/dotfiles-zsh/commit/c15bdc2e3c2f4ad7e4712d629afcea3ddf58af57))
* simplify atuin integration, remove lazy binding artifacts ([a8a1e4d](https://github.com/chiptoma/dotfiles-zsh/commit/a8a1e4dca78a135bc6021a4ed4de01cfcc8de152))
* skip zoxide lazy load when OMZ plugin already initialized ([0c54995](https://github.com/chiptoma/dotfiles-zsh/commit/0c54995ac203200e0e0c916e9704ea14fc15e7d9))
* **smoke-test:** use pattern matching to handle OMZ warnings ([7950ea3](https://github.com/chiptoma/dotfiles-zsh/commit/7950ea3d99c560b879c09c44e790f8b6f8ec67aa))
* source ZDOTDIR/.zshenv from ~/.zshenv after setting ZDOTDIR ([64a35ea](https://github.com/chiptoma/dotfiles-zsh/commit/64a35eabc31066ec1ce2f7a7c7c69064de9e286e))
* support curl-pipe installation (curl ... | bash) ([319dd81](https://github.com/chiptoma/dotfiles-zsh/commit/319dd811668a4bd7e3141c8166729f26224b4eba))
* suppress /dev/tty redirect errors in curl-pipe mode ([4572056](https://github.com/chiptoma/dotfiles-zsh/commit/4572056c20279fc1fbbc337c3e3eb38b2b350238))
* unified tool counter and exec zsh in curl-pipe mode ([8e6b536](https://github.com/chiptoma/dotfiles-zsh/commit/8e6b5367f5e28505758eee877d00abc2886545c7))
* update essential files paths in install.sh verification ([57f603e](https://github.com/chiptoma/dotfiles-zsh/commit/57f603e3db7e8e978d56adcc7e60f657d79e50fa))
* use &gt;| to override noclobber in update check ([5b52033](https://github.com/chiptoma/dotfiles-zsh/commit/5b52033921bea3b7d418f59a6ff7a150a1deffd7))
* use brighter gray (245) for starship prompt box chars ([255b6b5](https://github.com/chiptoma/dotfiles-zsh/commit/255b6b5dc77299ed8438df5911b874da61bce2d5))
* use correct function name get_package_manager for unzip install ([95508bb](https://github.com/chiptoma/dotfiles-zsh/commit/95508bb3cbfcb995dfcff8ba51e387424481dad4))
* use eval for zoxide lazy wrappers to avoid parse-time alias conflict ([ab7c76e](https://github.com/chiptoma/dotfiles-zsh/commit/ab7c76ee4fcd135e0434fc0da6532e91f13158c0))
* use maybe_sudo for containers, make optional tools non-fatal ([71af791](https://github.com/chiptoma/dotfiles-zsh/commit/71af79117e19b8a697d96470f2abc3af71872bd1))
* use Ubuntu 22.04 instead of 20.04 (deprecated runner) ([6ece95d](https://github.com/chiptoma/dotfiles-zsh/commit/6ece95d1d57b5c15a8d1bef54eeaa791dcb0d312))


### Refactoring

* centralize all keybindings in keybindings.zsh ([e7da1d9](https://github.com/chiptoma/dotfiles-zsh/commit/e7da1d9d351946a6c43fef4e5563271c87278644))
* **ci:** standardize workflows for consistency and best practices ([36cfb37](https://github.com/chiptoma/dotfiles-zsh/commit/36cfb3779e1bf164445ceaf278ae5fbebfbbf9ba))
* consolidate utils into lib/utils/ barrel structure ([163791a](https://github.com/chiptoma/dotfiles-zsh/commit/163791a3baed660790d10931fff5452396d688ec))
* deduplicate CI pipeline and improve weak tests ([0748c11](https://github.com/chiptoma/dotfiles-zsh/commit/0748c1145200980cbac845b1a7ff25b01acd719a))
* extract smoke tests, clean up CI workflow ([a5b31bd](https://github.com/chiptoma/dotfiles-zsh/commit/a5b31bdb8df5a1b65b2ffee2184fb29c97f84fba))
* implement POST_INTERACTIVE hook system ([4012fb4](https://github.com/chiptoma/dotfiles-zsh/commit/4012fb412412fd7026a5a1a47627cbe23156c865))
* move starship/atuin init to environment.zsh ([4390a82](https://github.com/chiptoma/dotfiles-zsh/commit/4390a82cd8d699ff0e48cbbda3f47e270d51a11a))
* organize template files into examples/ folder ([8997de3](https://github.com/chiptoma/dotfiles-zsh/commit/8997de315c66cbcf70a337693aedbeda5d176e80))
* remove broken lazy loading for starship/atuin ([75d00f4](https://github.com/chiptoma/dotfiles-zsh/commit/75d00f471b722a77622288dc696266ac7907aafd))
* remove dead code and unused functions ([51c26b3](https://github.com/chiptoma/dotfiles-zsh/commit/51c26b3b16e04ed638ae9cb0b2a8107c750bd4d5))
* rename local.zsh to .zshlocal and add tool configs ([14e9c82](https://github.com/chiptoma/dotfiles-zsh/commit/14e9c8245081147cd4725dc601029bdc8eced8a2))
* reorganize tool categories for better defaults ([848781d](https://github.com/chiptoma/dotfiles-zsh/commit/848781dc0fc52da1a868dd0d75d345872421565b))


### Documentation

* fix CI badges and add complete installer options ([a5e4ed9](https://github.com/chiptoma/dotfiles-zsh/commit/a5e4ed961cdf36f0ff7c731291315b3a42ee7f68))
* fix useful commands table with correct aliases ([7a74406](https://github.com/chiptoma/dotfiles-zsh/commit/7a74406af61265b2cf2501c833ef6ec1666418ca))


### Maintenance

* clean up redundant files and consolidate tests folder ([3c9ba81](https://github.com/chiptoma/dotfiles-zsh/commit/3c9ba81ffa90ae0943caa8aa01df2c4b406556da))
* initial commit ([763aa18](https://github.com/chiptoma/dotfiles-zsh/commit/763aa18bf2a4fe1e1d920d4cf4a9eb5b8dfbcaf3))
* **main:** release dotfiles-zsh 0.1.1 ([f10fde1](https://github.com/chiptoma/dotfiles-zsh/commit/f10fde1a20a87e3d0b7a10850e2b4b1986678346))
* **main:** release dotfiles-zsh 0.1.1 ([db68bb2](https://github.com/chiptoma/dotfiles-zsh/commit/db68bb29e4b6196acd233135a5ab7455c8a7b582))


### CI/CD

* add Fedora/Arch testing, verify functions load ([8f8ee42](https://github.com/chiptoma/dotfiles-zsh/commit/8f8ee424bb26189733caf5cd2c81c1002b23dd17))
* add top 10% improvements - caching, benchmarks, minimal mode ([75d1d32](https://github.com/chiptoma/dotfiles-zsh/commit/75d1d3220a779a2be0ed6dc86f79050f9946435c))
* bump actions/checkout from 4 to 6 ([cec8b19](https://github.com/chiptoma/dotfiles-zsh/commit/cec8b192b91ac8daa0b08436ebf1be54daba67cc))
* bump actions/checkout from 4 to 6 ([f89339f](https://github.com/chiptoma/dotfiles-zsh/commit/f89339fe5fe39fd85b98ccfb233f6112dcf47786))
* bump softprops/action-gh-release from 1 to 2 ([c2052d9](https://github.com/chiptoma/dotfiles-zsh/commit/c2052d99a7ecf460d1f6a7c7bf5d8b20f49f1a51))
* bump softprops/action-gh-release from 1 to 2 ([16929db](https://github.com/chiptoma/dotfiles-zsh/commit/16929dbca4961e3d4462c94f6ff20c8196404e14))
* install OMZ plugins, make smoke tests stricter ([fb83c0d](https://github.com/chiptoma/dotfiles-zsh/commit/fb83c0d0789380e595db1db070ece08727d231b9))
* restructure workflows for comprehensive testing ([1844b91](https://github.com/chiptoma/dotfiles-zsh/commit/1844b91148b10ab706f24fb26d0af07a59aec89e))


### Testing

* comprehensive CI coverage for 95%+ real-world scenarios ([e701f3a](https://github.com/chiptoma/dotfiles-zsh/commit/e701f3a2e3a41211b970dab63c4ec6cb6faf5fe3))

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
