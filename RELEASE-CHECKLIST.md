# Beta release gate

Completed in this pass:
- [x] MIT license and third-party notices included.
- [x] Draft discard and clear confirmations, safe initial selection and busy guards.
- [x] Lighter first-install default without overwriting existing user settings.
- [x] Optional helper auto-start off by default; public launchers use ordinary Python.
- [x] QML component compilation and automated interaction regression tests.
- [x] New confirmation layout checked at 720p with maximum text size.
- [x] Actual Pegasus 5.15.10 runtime startup smoke test with isolated portable config and an empty library. Helper endpoint isolated; software renderer. No theme load error. Pegasus logged a cache-writing warning, which needs follow-up on another machine.

Before a public beta announcement / gallery request:
- [ ] Test physical Xbox and PlayStation controllers, including every modal and splash input release.
- [ ] Launch a real game, return, verify focus and Recent/Favorites persistence.
- [ ] Test real GPU rendering/performance on the intended streaming client at 720p and 1080p; do not use the development GPU as the sole performance target.
- [ ] Extract the ZIP on a separate Windows account or machine with no Python and no credentials; browsing and launching must work. Then test optional helper setup using standard Python.
- [ ] Confirm saved settings survive restart and update.
- [ ] Add a representative populated-library screenshot and short demo suitable for public display. Current screenshots are isolated startup/settings renders.
- [ ] Create the public GitHub repository on the chosen game-dev account; add its real URL to theme.cfg homepage and README.
- [ ] Publish the tested beta archive/release and open a gallery issue or repos.txt pull request.

Do not claim screen-reader support, working trailer streaming or untested platform compatibility. Never publish personal settings, credentials, caches, generated game metadata/media or the entire working installation folder.
