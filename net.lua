local G=GAME -- fetch the global game table
local M={} -- the module table

function M:init()
  self.gameport=55232
  GAME.playerSide=0
  if arg[1]=="-c" then
    print'Client mode'
    self:connect(arg[2])
  elseif arg[1]=="-h" then
    print'Host mode'
    self:host()
  else
    print'Lobby mode'
    self:lobby()
  end
end

function M:lobby()
  self.multicast=Y.net:umc(Y.destination.publicIP,self.gameport+1) -- this is a small trick to use the IP collected by YDestination
  self.multicast:mcadd'239.1.33.7' -- add a multicast address to listen on
  self.ownIP,self.ownPort=self.multicast:sockname(true)
  GAME.dontSim=true
  self.tick=self.lobbyTick
end

function M:lobbyTick()
  local pending=true
  while pending do
    local msg,a,b,c = self.multicast:receive()
    if not msg then
      pending=false
      if a ~= "timeout" then error('connection error: '..tostring(a)) end
    elseif a~=self.ownIP and b~=self.ownPort and c~=self.multicast.id then -- we want to be sure we don't listen to our own messages
      if msg.type=="announce" then
        print'Client found, getting them'
        self:host()
        return self.multicast:send({type="gotcha",id=c},a,self.gameport+1)
      elseif msg.type=="gotcha" and msg.id==self.multicast.id then -- we want to make sure we only listen to messages that were meant for us
        print'They got me, connecting'
        return self:connect(a)
      end
    end
  end
  self.lobbyCount=(self.lobbyCount or 0)+1
  if self.lobbyCount>20 then
    self.lobbyCount=0
    print'announcing'
    self.multicast:send({type="announce"},'239.1.33.7',self.gameport+1)
  end
end

function M:host()
  self.connection=Y.net:userver(self.gameport)
  GAME.dontSim=true
  self.tick=self.hostTick
end

function M:connect(ip)
  self.connection=Y.net:uclient(ip,self.gameport)
  self.connection:send{type="handshake",shake="request"}
  GAME.dontSim=true
  self.tick=self.clientTick
end

function M:hostTick()
  local pending=true
  while pending do
    local msg,a,b,c = self.connection:receive()
    if not msg then
      pending=false
      if a ~= "timeout" then error('connection error: '..tostring(a)) end
    elseif not self.clientIP or (a==self.clientIP and b==self.clientPort) then
      self.clientTimer=0
      if msg.type=="handshake" then
        if msg.shake=="request" then
          self.clientIP=a
          self.clientPort=b
          self.connection:send({type="handshake",shake="response"},self.clientIP,self.clientPort)
          GAME.dontSim=false
          GAME.playerSide=1
        end
      elseif msg.type=="tick" then
        GAME.paddles[2]=msg.paddle
      end
    end
  end
  if self.clientIP then
    self.connection:send({type="tick",ball=GAME.ball,paddle=GAME.paddles[1],scores=GAME.scores},self.clientIP,self.clientPort)
    self.clientTimer=(self.clientTimer or 0)+1
    if self.clientTimer > GAME.fps*3 then
      Y.quit()
    end
  end
end

function M:clientTick()
  local pending=true
  while pending do
    local msg,a,b,c = self.connection:receive()
    if not msg then
      pending=false
      if a=="connection refused" then Y.quit() end
      if a ~= "timeout" then error('connection error: '..tostring(a)) end
    elseif msg.type=="handshake" then
      if msg.shake=="response" then
        GAME.dontSim=true
        GAME.playerSide=2
      end
    elseif msg.type=="tick" then
      GAME.ball=msg.ball
      GAME.paddles[1]=msg.paddle
      GAME.scores=msg.scores
    end
  end
  if GAME.playerSide==2 then
    self.connection:send{type="tick",paddle=GAME.paddles[2]}
  end
end

return M -- return the module table