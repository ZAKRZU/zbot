# ZBOT VERSION 2
This is second version of my own plugin. This one is written in a better way, so it is smaller (600+ lines, not 1100++), and more clean and way more optimised!.

## SETUP
In line 255 you can set your server ip and port, to have fast copy paste command for other players to join. I didn't make it get this values automaticaly because i didn't need that feel free to implement something like that. 😀

### Chat Commands
Every command need to start from ! or . Ex. `!ready` or `.ready`
- During warmup (before match starts)
  - !ready \- Indicates that your team is ready to play
  - !unready \- Indicates that your team is not ready to play
- After knife round (available only for team that won knife round)
  - !switch \- Switches side where team starts
  - !stay \- You stay on your side
- Available during match
  - !pause \- Pauses the match
  - !unpause \- Unpauses the match (agreement of both sides is needed to unpause match)


### Console Commands
- zbot
  - create \- Create match
  - forceready \- make both team ready
  - forceunpause \- like the name says, unpause mach no confirmation from teams is needed
  - update \- updates teams names, and server password
  - delete \- delete match, you can also type **cancel**

### Custom ConVars
- zbot_demo \- Turn on/off demo recording. ***!YOU NEED TO SETUP GOTV!***
- zbot_knife \- Turn on/off knife round
- zbot_pass \- Changes server password during match so no one will join to the server after match and you can practise in peace.
- zbot_config \- Points to config file you want to load when setting up match ex. esl5on5.cfg
- zbot_team1 \- Changes first team name
- zbot_team2 \- Changes second team name
