# Changelog

## 1.0.0+90 changelog

* [✨](https://github.com/microscotch/tenk/tree/498855a6474c84d9efd20b21c9ccbd073c236903): add the app icon -- engraved brass 3/4-view die (1 / 10 / K)
* [✨](https://github.com/microscotch/tenk/tree/ce26c4c6f4ac9a1c5d636724029de12837315c52): localize the app into 11 languages, add the intro screen avatar
* [📝](https://github.com/microscotch/tenk/tree/6377d038f32f8bdb4d24cdcf71fffe10aabeb8cf): add the screen-flow diagram and rules explained for a child
* [🐛](https://github.com/microscotch/tenk/tree/cb2fc596f0bb493361e9437044080f2f1d799bf8): make the TestFlight upload non-blocking, bump the build (1.0.0+3)
* [🐛](https://github.com/microscotch/tenk/tree/fff69365cedd24206033d63110fe0c80beb3b93a): always display a roll's 5 dice on a single row
* [✨](https://github.com/microscotch/tenk/tree/fdb2af65dd02ea5c480f55e824454bff69a0adfe): add player avatars, game persistence/replay, a 2-zone home screen
* [🐛](https://github.com/microscotch/tenk/tree/0281797b9686d1f849ba778560d5f35211f717d6): unblock reaching exactly 10000 to win
* [✨](https://github.com/microscotch/tenk/tree/342e04a090fc3034e59b308161556b515748bd8b): 3-zone accordion, archive finished runs, timed spectator replay
* [📝](https://github.com/microscotch/tenk/tree/5ba6ee78fb0ac9a2f7ee78a83baecb08a93ef43b): add turn and game state diagrams
* [✨](https://github.com/microscotch/tenk/tree/4916a927a7bb4cbd444f9d3f513a10776f026596): split new-game setup into its own screen, make run lists static
* [✨](https://github.com/microscotch/tenk/tree/71dc790f9d53aefc180edcd8d8df32b565a66ba2): add a rules help screen, smarter dice-keep default
* [✨](https://github.com/microscotch/tenk/tree/2e354863b01841cc228587a73758195f267e68d5): rework the game screen around dedicated roll/hand zones and a turn log
* [🐛](https://github.com/microscotch/tenk/tree/1063098781d800e99d18c345cdbc73827ed4d43f): rename Lancé to Piste, move turn score into zone labels, persist the log
* [🐛](https://github.com/microscotch/tenk/tree/090a6db3e930d553ccc8ec496cade25b3448dbaa): delay roll scores, fade default-kept dice into hand, uniform dice size
* [🐛](https://github.com/microscotch/tenk/tree/e478385ba6a2fc5dca07a7c5a7fd30673747b40a): crash when the smart keep-default tries to decline a 5 with no junk die
* [🐛](https://github.com/microscotch/tenk/tree/fc24a368cef5b0889dcdf44792aec8f3640092d3): pause on background, drop redundant roll UI, resume-game popup
* [✨](https://github.com/microscotch/tenk/tree/09f28ab8d0c8b51c47c1d73fecca409caf09fe3c): unify roll controls into one row, portrait lock, compact zones
* [✨](https://github.com/microscotch/tenk/tree/483000f7ab8dde53b8c7ef7042aeff0e715f7984): default AutoRoll on for AI players in new-game setup
* [🐛](https://github.com/microscotch/tenk/tree/58192873e24d2b868405b302d4913570b975aed1): main pleine label/banner lagged one roll behind actual hot dice
* [🐛](https://github.com/microscotch/tenk/tree/25c13d0fa1dd0848437f681587dff59a0dab3918): guarantee distinct avatar colors across a game's roster
* [🐛](https://github.com/microscotch/tenk/tree/5a3f93c9e9164240cce55dc3d24c793ce29888b9): splash roll is now visibly seen tumbling before TenK/footer
* [🐛](https://github.com/microscotch/tenk/tree/7758bd9ed3e60be40b935634cd6e73e1bad86ef2): revert splash center text back to "10K"
* [✨](https://github.com/microscotch/tenk/tree/79ff598647ab35e07abb90596ee767b6b74ddd65): announce banked score and leftover dice in the game log
* [✨](https://github.com/microscotch/tenk/tree/a9f6cfd271d1a8a7eec2fbaecb0e1caafeca82de): add an About dialog with app version and build number
* [🐛](https://github.com/microscotch/tenk/tree/e9b3991dc631a69a8334cbbfc412fe7da821d4c5): score collision must check a player's whole grid, not just their current total
* [🐛](https://github.com/microscotch/tenk/tree/ae1eda87662f183bad95ce484f5afb91080fb888): bar-fallback must skip already-barred lines, not just step back one
* [🐛](https://github.com/microscotch/tenk/tree/a68a9f48e09e25ff5140a315098139ceca6fbbf8): game-over screen returns home via an OK button
* [✨](https://github.com/microscotch/tenk/tree/0f3ee5eba459e9c9a6dba937174a53af269479e3): drop the scoring-probability readout from the player list
* [✨](https://github.com/microscotch/tenk/tree/e0611aa082cfaf9835a3a0dda2138e164454bb33): show gold/silver/bronze medals in the player list
* [✨](https://github.com/microscotch/tenk/tree/2e785025fb3f849a402f8476ce7ee1f0aeb1e575): call the 10000 overshoot at roll time, and stop offering doomed keeps
* [🐛](https://github.com/microscotch/tenk/tree/056f4c4ccf731e294f771db13b68b2025d7ee7ad): lighten the gold medal so it reads on the current player's row
* [✨](https://github.com/microscotch/tenk/tree/41f286e13b051256be4441ebaf5600fb8232fbe8): rework the game screen's control row
* [🐛](https://github.com/microscotch/tenk/tree/b5c01b5f2d5db3e4e7c70e44fc895dabd0c8b941): make player name fields editable, stop crashing without a saved name
* [✨](https://github.com/microscotch/tenk/tree/4accb0d13d2f633f131e27581def16d87e11cfa9): make the AI weigh bar risk and avoid self-inflicted 50 traps
* [✨](https://github.com/microscotch/tenk/tree/a27c10d6d98dd166ce115c9ab3f87ece086a89da): dedicated popups for bust/inherited hand, avatar-based score grid, compact stop button
* [🐛](https://github.com/microscotch/tenk/tree/d0079c9ecd0ebc15344d42b63c1d8316e1effc65): roll immediately when accepting/declining an inherited hand
* [✨](https://github.com/microscotch/tenk/tree/d845057dac0b6560854f1a497d690d97b5e9d676): add shake-to-roll, toggleable in settings
* [✨](https://github.com/microscotch/tenk/tree/de0b63f31c6718f89c5b931c460f33ab31037d72): one log entry per roll, and hold Stop back until the dice land
* [✨](https://github.com/microscotch/tenk/tree/4ce002a51da52a95547db3636944c54e942a2f85): say what each roll, bank, resume and bust actually did in the log
* [🐛](https://github.com/microscotch/tenk/tree/045341870752a8505891464a962bf5c8b51d9cce): a full hand landing exactly on 10000 is a dead end, not a win
* [🐛](https://github.com/microscotch/tenk/tree/870714d3a9d343d6aee13afe829988830befb4d4): the tiret belongs to the grid line, so both screens agree on it
* [♻️](https://github.com/microscotch/tenk/tree/a0dcce1bce3651f2cf5cd61deab8ce5c4f1ad868): one control-row template for human and AI turns alike
* [♻️](https://github.com/microscotch/tenk/tree/4953070d6b796544468a1c2964284234075fc8c9): put the inherited-hand row on the shared control template too
* [🐛](https://github.com/microscotch/tenk/tree/5fedccac85c386fa837646839b1050c22d2c5445): no spinner on a bust, and a short dead zone after each transition
* [🐛](https://github.com/microscotch/tenk/tree/370a3c92983619ce281ea4c69abfa20efe4e80cb): "run" is feminine in French, agree every label with it
* [📝](https://github.com/microscotch/tenk/tree/4b9a66b457ac96b227399644bbbccdc784d0c138): add a class diagram of the engine and state layers (draw.io)
* [📝](https://github.com/microscotch/tenk/tree/02ca1ccfed5348403f5ffc03807f03396c377a1d): explain the class diagram in architecture.md, and make it repeatable
* [🐛](https://github.com/microscotch/tenk/tree/271dde0b9cc191d8d7ddf23a5529aa4dd2296626): the game-over screen's back arrow led to a dead, spinner-only screen
* [✨](https://github.com/microscotch/tenk/tree/61edc645f49b53271e72bf94c821a78b09f220bc): the ace quint (five 1s) always wins, even in a full hand
* [🐛](https://github.com/microscotch/tenk/tree/d9ede43fb3392d368092835909d5ab344208be97): show who actually barred a score, not the column's own player
* [✨](https://github.com/microscotch/tenk/tree/3008243aeb6002634cbd03ff08d0409d4179ab92): larger dice in the roll and current-hand zones
* [✨](https://github.com/microscotch/tenk/tree/1a32f25d7ae9d476f1116ab15047aa1e88e092eb): keep the previous, smaller dice size on AI turns
* [🐛](https://github.com/microscotch/tenk/tree/b105d302e6fc182f35e9e618ee49038ebab398cd): refuse an inherited hand that lands exactly on 10000
* [✨](https://github.com/microscotch/tenk/tree/ba21c4ad4ce4c2a7c33b88d564e7e911201c7885): skip the inherited-hand prompt when there is nothing to choose
* [🐛](https://github.com/microscotch/tenk/tree/e0204cec40afb508408146a4f677b08731d9e0c0): stop the new-game screen test colliding with a random AI name
* [🐛](https://github.com/microscotch/tenk/tree/5e87fc29e46d8a59ba62bdb80f0e725b76684e6e): back button no longer dismisses the bust and inherited-hand popups
* [✨](https://github.com/microscotch/tenk/tree/599ba652d4b1869e9200fd57714708c3940389fd): make the scoring-odds display an opt-in setting
* [✨](https://github.com/microscotch/tenk/tree/32df7bce0ef22f98641bb9316ee50735bd997fd2): show the inherited dice in the hand-takeover popup
* [✨](https://github.com/microscotch/tenk/tree/7a3ac86fcf45c0aeef9b7f18d17ea617aa647e53): stack the hand-takeover popup top to bottom, centred
* [✨](https://github.com/microscotch/tenk/tree/9fe6bbb502633b382985f6254f0cef68588635b6): centre the hand-takeover popup title with the rest
* [✨](https://github.com/microscotch/tenk/tree/100d58eb1e97116aef229d23328849b162e9f9fe): centre the bust popup title too
* [✨](https://github.com/microscotch/tenk/tree/8ce3c6103081654f36a1004462037bb1a750b32a): centre the Continuer button in the bust popup
* [🐛](https://github.com/microscotch/tenk/tree/4c7bd886d8e70425c4d9ca973f69b469e4649802): drop the tiret from a barred line in the score grid
* [🐛](https://github.com/microscotch/tenk/tree/b0c0930b74b9cc00fa3e0bdeb1c9f21ca62020ee): put the previous score's tiret inside its parentheses
* [✨](https://github.com/microscotch/tenk/tree/77c05a3206715802439a07be334c032e671c9ad6): put Stop left, Roll centred and the exchange right
* [🐛](https://github.com/microscotch/tenk/tree/15b813d8fdb7d9bbb5dbdd97b4ebbca66ae1c9ae): don't play music at launch when it is switched off
* [🐛](https://github.com/microscotch/tenk/tree/e95be09142d3b0feb334fb608cf8007fd40e8bec): keep a player's badge colour when their grid is shown alone
* [🐛](https://github.com/microscotch/tenk/tree/b2d88ea5b6d7abac9ad52f12aa0f18496a3da246): don't show the inherited-hand choice on an AI turn
* [✨](https://github.com/microscotch/tenk/tree/2f4f76dcaa7adefca3e7949ad5b5d915a37fd0fa): new icons for the Stop and fives-exchange controls
* [✨](https://github.com/microscotch/tenk/tree/80944b75b9edaf8a346976b468ed4261c4149c8e): left/right-handed layout for the side controls
* [✨](https://github.com/microscotch/tenk/tree/b1e87f385bc855e11dbfcbe96e9cd2cc240640f0): light the side controls in amber when they become usable
* [✨](https://github.com/microscotch/tenk/tree/32d1f11aa65dacbc00189af465023d2580bb4653): group the current hand by figure, one frame per roll
* [✨](https://github.com/microscotch/tenk/tree/94f73d6e80cf283e1a16c1ed71880ce5859b0fb2): frame the roll being played, and show what a bust costs
* [♻️](https://github.com/microscotch/tenk/tree/a2f632a14b76334089b7e4b335f63615f6fa265c): put the whole busted hand on one line in the popup
* [🐛](https://github.com/microscotch/tenk/tree/89e1f6c70767ce0364d21c84f64c63b14bab96c7): stop the hand zone flickering while the dice roll
* [✨](https://github.com/microscotch/tenk/tree/236a64b73b3ad4dd610b41d13d489ca529046312): colour the current-hand outline by whether the player can stop
* [🐛](https://github.com/microscotch/tenk/tree/fed43a7d284e08b27f7fa847479116fc5ab8fade): pull the roll frames clear of the zone's inlaid label
* [🐛](https://github.com/microscotch/tenk/tree/431e73836a951a6bc4aebec5e0bde2e9b39a5648): stop a new roll from showing its kept dice before they land
* [✨](https://github.com/microscotch/tenk/tree/aab9006ad4750e5523e20b26a794fdd1f3c400c0): frame each roll in the inherited-hand popup too
* [✨](https://github.com/microscotch/tenk/tree/2ead8f7957f1e5ddf16ece8171688ec561d29210): show what the busted hand was worth
* [✨](https://github.com/microscotch/tenk/tree/eb41f0bf5a0cc0a491e0fc063be5820b5ddc9ee6): read the bust's cost off the grid mark it leaves
* [✨](https://github.com/microscotch/tenk/tree/615f0dcad50ab49d09da6e319a70a1a410e36a3f): spell out the drop when a bust bars the line
* [🔹](https://github.com/microscotch/tenk/tree/a2e225ff4eb000464caada2818383edc51a0aba7): Change export method from 'app-store' to 'app-store-connect'
* [📝](https://github.com/microscotch/tenk/tree/39a0735f3ae253fbdfc771c609d54422a90ff6fe): track the privacy policy the stores point at
* [✨](https://github.com/microscotch/tenk/tree/1504df6b36ceaf0bcd67ba5c7de60d477d8ed4d2): turn the inherited-hand dialog into an icon prompt
* [✅](https://github.com/microscotch/tenk/tree/6c44da179f1b58b82d59688f72a621bb5edffc06): cover consulting the score grid from the inherited-hand dialog
* [✨](https://github.com/microscotch/tenk/tree/f67b040ac9647ee83f560735d3a8ff25fbe592d0): flag the die the extension rule makes worth 100
* [♻️](https://github.com/microscotch/tenk/tree/74a872446df2a4a19b4d4b61fa2c34856035543e): move the extension mention into the zone label
* [🐛](https://github.com/microscotch/tenk/tree/37e9f546938e55eeae52d2d4de1bb28cf7eed6b8): announce the extension when the brelan lands, not a roll later
* [✨](https://github.com/microscotch/tenk/tree/febfd60300497d96ae3caca1cdf1f51008349317): leave the game and game-over screens by system back
* [📝](https://github.com/microscotch/tenk/tree/8a7567f556e9c8275259ea65ce26da08ff10b65a): describe the iOS CI as it actually is
* [✨](https://github.com/microscotch/tenk/tree/8f26fa063d4c203f7807011a7a33161979b44756): reduce the home screen to five buttons
* [🐛](https://github.com/microscotch/tenk/tree/77cd1bd64d456f8597256d352d5262f585b6a09f): make the run-le10000 readiness probe fire again
* [✨](https://github.com/microscotch/tenk/tree/c6c2412d9f9f4980889716ec885120f3d7947d25): add a player database and statistics derived from replays
* [✨](https://github.com/microscotch/tenk/tree/bdeac3ae867f94aadf4e16c22ee84bcfa2a5b13c): manage players, pick them for a game, and read their statistics
* [✨](https://github.com/microscotch/tenk/tree/05ab3320100ec2e808e45a6bb511c3549ddc3c60): give each player's statistics their own screen, and spell out figures
* [✨](https://github.com/microscotch/tenk/tree/7bb3bb3d17f6fd8349b6d8ded2da2f6182c04eb8): chart each player's score across their own turns
* [✨](https://github.com/microscotch/tenk/tree/0d7ce09919498179436fbcf442127dee9b58baeb): draw the extended die, and call players by their nickname
* [✨](https://github.com/microscotch/tenk/tree/a4c4087542a4b1a7624e6f89998c6ebcb6962899): chart and statistics buttons on the game-over screen
* [✨](https://github.com/microscotch/tenk/tree/d65a8cd10ec0a3bd094ff5e865bf508a939ffb84): replay button, finished runs open the end screen, roll statistics
* [✨](https://github.com/microscotch/tenk/tree/c40f895dde06f95e4cb250fcdabe450e82f04486): expandable player panels on the general statistics screen
* [🐛](https://github.com/microscotch/tenk/tree/d0f72f4df67692bf06518bba3bcc4526dc8c2cde): show the popups in the game replay and close them on the next step
* [✨](https://github.com/microscotch/tenk/tree/cb7fb37fcfe5e2eb51dd43a7dbe9d26c6e78f363): figure breakdowns in game and record statistics, dashed detail rows
* [✨](https://github.com/microscotch/tenk/tree/5c9a22fae4d2563f1e0d6c26f644d04c5f709d5d): gold '= 100' mention in the current-hand label
* [🐛](https://github.com/microscotch/tenk/tree/d5614142edab074e60db19aba5282d04248e9c71): journal each move before publishing the new game state
* [✨](https://github.com/microscotch/tenk/tree/157796cd45ed1c50a85b5cb012cef573e464f1e1): faint grid line every 200 points on the score chart
* [✨](https://github.com/microscotch/tenk/tree/b482f409ba508a51555c2129dea6aa9bab3e00c8): movable vertical cursor with a scores tooltip on the score chart
* [✨](https://github.com/microscotch/tenk/tree/103f10d2697532b51806691fdf50ad2f4bcbd4f5): replay starts on the game, with bottom controls, pause and a turn slider
* [🐛](https://github.com/microscotch/tenk/tree/5ffd87b69b428a351a6e918b0e0784378edc9008): name players by nickname wherever a finished game is shown
* [✨](https://github.com/microscotch/tenk/tree/ee5548786304e856460fdcdbff1c88d1a9f969d1): score grid and chart icons in the inherited-hand popup, aligned decisions
* [🐛](https://github.com/microscotch/tenk/tree/0f5b9c55115afc1a56d873157c3abee64a010472): bust straight away on a full hand landing exactly on 10000
* [✨](https://github.com/microscotch/tenk/tree/f7491bd34ef3a28c3f11293abd2a53f4b3736d4f): collapsible figure details in the statistics, with their share of the total
* [📝](https://github.com/microscotch/tenk/tree/11c2f8bc8af23d0838d8e54fcd9215a207975b0a): bring the class diagram, screen flow and turn-state up to date
* [✨](https://github.com/microscotch/tenk/tree/18571282efb6fbe6bd8f4ec8b482a70e5032b166): date, time and participants on the paused/finished game tiles
* [✨](https://github.com/microscotch/tenk/tree/ef660674878ba1404d14fdd83272090d6551d425): simultaneous roll-off and reorderable player list
* [✨](https://github.com/microscotch/tenk/tree/d92c93044976948ad0502286a1785935ab0cced8): translate every missing string into the ten other languages
* [♻️](https://github.com/microscotch/tenk/tree/92e86411226b1d101d8541a2a5a08eafec749f79): remove dead code
* [📝](https://github.com/microscotch/tenk/tree/b87ce518a7884eabe562609e168d3340570c08a2): add the human-turn sequence diagram
* [🐛](https://github.com/microscotch/tenk/tree/a0ad4bc76a445c161f275efb45b2e21092d2775f): count a finished game in player statistics within the same session
* [📝](https://github.com/microscotch/tenk/tree/c8d35ec386804b0e6cb187da714da708ae695268): add the UML set under docs/uml
* [✨](https://github.com/microscotch/tenk/tree/21eae75b0bf2bb072fda7ef7191ef828434c048d): give each die its own roll duration and spin direction
* [✨](https://github.com/microscotch/tenk/tree/d1cf70552f834776f618b382226229e6dd7ef2dd): vary which side faces show when a die comes to rest
* [✨](https://github.com/microscotch/tenk/tree/38c3248aeebe00cbbca621a23cca78ccf732cfe6): make dice bounce on the table while rolling
* [✨](https://github.com/microscotch/tenk/tree/9ab27eea4534c229d4caa2d91abe9e012cc67763): lower the dice view angle and randomize their resting yaw
* [✨](https://github.com/microscotch/tenk/tree/f7f1882e0e1907c2913515ce1166f3fb719e3751): in-game statistics, Android back navigation and a new home screen
* [✨](https://github.com/microscotch/tenk/tree/cbe42f064bb0efb71db4a4b6a9436606ac4bfd5d): split the home screen into a top title zone and a centred button zone
* [✅](https://github.com/microscotch/tenk/tree/e7caeb956fe953ec8993426be31b07289a3703f0): vérifie la signature des commits [skip ci]
* [✨](https://github.com/microscotch/tenk/tree/9a6d4d7a9df145489fba728e7a3ae9dc556243f5): journal with dice faces and the online protocol
* [✨](https://github.com/microscotch/tenk/tree/12ab4e8213ff3b56893d1e2c897c2b64091c113f): authoritative online game server
* [✨](https://github.com/microscotch/tenk/tree/0334592cb31b4144953eab8aaf6536d9b0c9d937): online session and remote mode of the game notifier
* [✨](https://github.com/microscotch/tenk/tree/fed0e4cd936b3e854378da7c3700bd256310b31e): online game screens (entry, room, roll-off, game)
* [📝](https://github.com/microscotch/tenk/tree/bf7997c5e789d26bc6c3c73ac4294befec7b8ab0): online games in the architecture, the UML set and the privacy policy
* [🐛](https://github.com/microscotch/tenk/tree/82c82dd7ff6a5d198ac77c64467ad55add17e9f8): harden the online server and check it end to end
* [🐛](https://github.com/microscotch/tenk/tree/4e24f12774858814109dad524ea9354baf6ba4e8): the host stays the host wherever they sit at the table
* [🐛](https://github.com/microscotch/tenk/tree/e0a40b092b6560da9a9d7c9cc815a2250df1b08e): keep online sessions out of local games, and make Quit keep the seat
* [📦](https://github.com/microscotch/tenk/tree/03023ee33fdee503b7bd22b33a5c81cb75f39c2a): cross-compile the server image, and document the image pipeline
* [✨](https://github.com/microscotch/tenk/tree/c648a723c6ba090192b375244e85a2ff3fe978e6): default to the production server, let CI skip store publishing, add the server compose file [skip ci]
* [🐛](https://github.com/microscotch/tenk/tree/89a345538d520ecc9341d34336970f7da0a2dcbc): stopping on a pending roll in an online game now sends the bank
* [✨](https://github.com/microscotch/tenk/tree/35d9c15f17a24b65d78187e0b99b12e03bab1457): share the room code from the online lobby
* [✨](https://github.com/microscotch/tenk/tree/2749ebcf42a33bea7c496fe38e056a8d5b7a6001): invitation links that open the app on the shared room
* [🐛](https://github.com/microscotch/tenk/tree/0509148b14197f0e7e3cd839c0e77273b39341b1): read the association file straight from the server in dev iOS builds
* [✨](https://github.com/microscotch/tenk/tree/63e6762500a8bf870ae9d96071d585092f27ad60): real recorded dice sounds, matched to the number of dice rolled
* [✨](https://github.com/microscotch/tenk/tree/55758270f84fe5260d8cb5c60e5d9272ce079cb5): archive finished online games
* [✨](https://github.com/microscotch/tenk/tree/d87262509715614057072529a9771632d7830a60): user profile, asked at launch and used as the online pseudo
* [🐛](https://github.com/microscotch/tenk/tree/6cba99d0a52b48898862a119aa599b1e27b8f9ed): declare the Google Play signing key for Android invitation links
* [✨](https://github.com/microscotch/tenk/tree/789486a422a7a16bec16ad6c6d43603a69ce43f6): choose between realistic and synthetic dice sounds
* [✨](https://github.com/microscotch/tenk/tree/457e25f100db6565554cdfb78ee4b0cc372c1936): show the active player's 5s choice live to the other online players
* [🐛](https://github.com/microscotch/tenk/tree/803537f50016e3af7eaed09b75d5be9cbd4aa202): stop stacking "server unreachable" messages after sharing a room code
* [🐛](https://github.com/microscotch/tenk/tree/2cdbd1a1d2a026f238cefc8fe465f910987683e3): rejoin one's own seat instead of joining twice from an invitation link
* [✨](https://github.com/microscotch/tenk/tree/817d024906f74dd9aa0f83eb45b698a3f96295c8): slide screens in like tiles instead of fading them
