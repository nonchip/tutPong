local G=GAME -- fetch the global game table
local M={} -- the module table

function M:init()
  GAME.ball[3]=100
  GAME.ball[4]=1
end

function M:tick()
  if GAME.dontSim then return end
  GAME.ball[1]=GAME.ball[1]+GAME.ball[3]/GAME.fps
  GAME.ball[2]=GAME.ball[2]+GAME.ball[4]/GAME.fps
  if self:collide(-math.huge,GAME.paddles[1]-25,-372,GAME.paddles[1]+25) then
    GAME.ball[3]=GAME.ball[3]*(-1.1)
    GAME.ball[4]=GAME.ball[4]+(GAME.ball[2]-GAME.paddles[1])
  elseif self:collide(372,GAME.paddles[2]-25,math.huge,GAME.paddles[2]+25) then
    GAME.ball[3]=GAME.ball[3]*(-1.1)
    GAME.ball[4]=GAME.ball[4]+(GAME.ball[2]-GAME.paddles[2])
  end
  if GAME.ball[1]<-400 then
    GAME.scores[2]=GAME.scores[2]+1
    GAME.ball={-100,0,100,1}
  elseif GAME.ball[1]>400 then
    GAME.scores[1]=GAME.scores[1]+1
    GAME.ball={100,0,-100,1}
  end
  if GAME.ball[2]<-295 or GAME.ball[2]>295 then
    GAME.ball[4]=-GAME.ball[4]
  end
  if GAME.scores[1]>=9 or GAME.scores[2]>=9 then
    GAME.running=false
  end
end

function M:collide(x1,y1,x2,y2)
  local x,y=unpack(GAME.ball)
  return x+5>=x1 and x-5<=x2 and y+5>=y1 and y-5<=y2
end

return M -- return the module table