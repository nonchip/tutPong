require "YEng"
GAME={ -- global table to hold the game data
  running=true;
  paddles={0,0}; -- left,right
  playerSide=1; -- 0=unknown, 1=left, 2=right
  scores={0,0}; -- left,right
  ball={-100,0,20,0}; -- x,y,sx,sy (s* being the speed in units/second)
  fps=60;
}

local net=dofile"net.lua"; -- the ...
local ui=dofile"ui.lua"; -- ... three ...
local sim=dofile"sim.lua"; -- ... modules

sim:init() -- call each of the module's init functions
net:init()
ui:init()


while GAME.running do -- just call each of the module's tick functions as long as running is true
  sim:tick()
  net:tick()
  ui:tick()
end

Y.quit() -- tell YEng to clean up.