local G=GAME -- fetch the global game table
local M={} -- the module table

local function readAll(file)
    local f = io.open(file, "rb")
    local content = f:read("*all")
    f:close()
    return content
end

local squareCoords,squareTris=dofile'assets/square.lua'
local squareVertexSource     =readAll'assets/square_vert.glsl'
local squareFragmentSource   =readAll'assets/square_frag.glsl'

local postVertexSource     =readAll'assets/post_vert.glsl'
local postFragmentSource   =readAll'assets/post_frag.glsl'

local font=dofile'assets/digitfont.lua'

function M:init()
  self.window, self.context = Y.sdl.quickGL'tutPong'
  Y.sdl.gL_SetSwapInterval(1)
  Y.sdl.pumpEvents()
  self.shader=Y.gl.mkShader({Y.gl.VERTEX_SHADER,squareVertexSource},{Y.gl.FRAGMENT_SHADER,squareFragmentSource})
  Y.gl.UseProgram(self.shader)
  self.vao=Y.gl.mkVAO(self.shader,Y.gl.STATIC_DRAW,squareTris,{'float',squareCoords,'in_Position',2})
  local winsizeptr=ffi.new('int[1][2]')
  Y.sdl.getWindowSize(self.window,winsizeptr[0],winsizeptr[1])
  self.winsize={winsizeptr[0][0],winsizeptr[1][0]}
  Y.gl.Viewport(0,0,unpack(self.winsize))
  self.ufloc_tmodel=Y.gl.GetUniformLocation(self.shader,'uf_transform_model')
  self.ufloc_tworld=Y.gl.GetUniformLocation(self.shader,'uf_transform_world')
  self.ufloc_tproject=Y.gl.GetUniformLocation(self.shader,'uf_transform_projection')
  self:setProjection()
  font=font(self.shader,'in_Position',self.ufloc_tmodel)
  Y.gl.ActiveTexture(Y.gl.TEXTURE0)
  local fbo_texture=ffi.new('GLuint[1]')
  Y.gl.GenTextures(1, fbo_texture)
  self.fbo_texture=fbo_texture[0]
  Y.gl.BindTexture(Y.gl.TEXTURE_2D, self.fbo_texture)
  Y.gl.TexParameteri(Y.gl.TEXTURE_2D, Y.gl.TEXTURE_MAG_FILTER, Y.gl.LINEAR)
  Y.gl.TexParameteri(Y.gl.TEXTURE_2D, Y.gl.TEXTURE_MIN_FILTER, Y.gl.LINEAR)
  Y.gl.TexParameteri(Y.gl.TEXTURE_2D, Y.gl.TEXTURE_WRAP_S, Y.gl.CLAMP_TO_EDGE)
  Y.gl.TexParameteri(Y.gl.TEXTURE_2D, Y.gl.TEXTURE_WRAP_T, Y.gl.CLAMP_TO_EDGE)
  Y.gl.TexImage2D(Y.gl.TEXTURE_2D, 0, Y.gl.RGBA, self.winsize[1], self.winsize[2], 0, Y.gl.RGBA, Y.gl.UNSIGNED_BYTE, ffi.NULL)
  Y.gl.BindTexture(Y.gl.TEXTURE_2D, 0)
  local fbo=ffi.new('GLuint[1]')
  Y.gl.GenFramebuffers(1, fbo)
  self.fbo=fbo[0]
  Y.gl.BindFramebuffer(Y.gl.FRAMEBUFFER, self.fbo)
  Y.gl.FramebufferTexture2D(Y.gl.FRAMEBUFFER, Y.gl.COLOR_ATTACHMENT0, Y.gl.TEXTURE_2D, self.fbo_texture, 0)
  Y.gl.BindFramebuffer(Y.gl.FRAMEBUFFER, 0)
  self.postshader=Y.gl.mkShader({Y.gl.VERTEX_SHADER,postVertexSource},{Y.gl.FRAGMENT_SHADER,postFragmentSource})
  self.upost_fbo_texture=Y.gl.GetUniformLocation(self.postshader,'fbo_texture')
  self.upost_winsize=Y.gl.GetUniformLocation(self.postshader,'winsize')
end

function M:setProjection()
  local w,h=unpack(self.winsize)
  local window_ratio=w/h
  local field_w,field_h=400,300 -- in each direction, so it'll be actually 800x600, because (0;0) is in the center
  if window_ratio >=1 then -- window is at least as wide as it's high, so we can limit the width
    h=field_h
    w=field_h*window_ratio
  else -- limit the height
    h=field_w/window_ratio
    w=field_w
  end
  local project=Y.math.ortho(-w-1,w+1,-h-1,h+1,-1,1) -- calculate the projection matrix
  Y.gl.UseProgram(self.shader)
  Y.gl.UniformMatrix4fv(self.ufloc_tproject, 1, Y.gl.TRUE, project.gl) -- uploading.
                                                                       -- parameters: uniform location, number of matrices, shall it be transposed, gl matrix
  if self.fbo_texture then
    Y.gl.BindTexture(Y.gl.TEXTURE_2D, self.fbo_texture)
    Y.gl.TexImage2D(Y.gl.TEXTURE_2D, 0, Y.gl.RGBA, self.winsize[1], self.winsize[2], 0, Y.gl.RGBA, Y.gl.UNSIGNED_BYTE, ffi.NULL)
    Y.gl.BindTexture(Y.gl.TEXTURE_2D, 0)
    Y.gl.UseProgram(self.postshader)
    Y.gl.Uniform2f(self.upost_winsize, unpack(self.winsize))
  end
end

function M:renderQuad(x,y,w,h)
  Y.gl.BindVertexArray(self.vao)
  Y.gl.UseProgram(self.shader)
  local transform=Y.math.translate(x,y,0) -- x,y is the lower left corner
  transform=transform*Y.math.mat4(w,0,0,0, -- scale in x dimension by w
                                  0,h,0,0, -- scale in y dimension by h
                                  0,0,1,0, -- scale in z dimension by 1 (=don't scale)
                                  0,0,0,1) -- scale in w dimension by 1 (=don't scale)
  Y.gl.UniformMatrix4fv(self.ufloc_tmodel, 1, Y.gl.TRUE, transform.gl) -- upload the matrix
  Y.gl.DrawElements(Y.gl.TRIANGLES, 6, Y.gl.UNSIGNED_INT, ffi.NULL)
end

local eventptr = ffi.new('SDL_Event[1]')
local event = nil
function M:tick()
  local now=Y.sdl.getTicks()
  if not self.fps then self.fps={lasttime=now,current=60,frames=0} end
  self.fps.frames=self.fps.frames+1
  if self.fps.lasttime < now-1000 then -- 1000ms=1s
    self.fps.lasttime=now
    self.fps.current=self.fps.frames
    self.fps.frames=0
    GAME.fps=self.fps.current
  end
  if not self.keysdown then self.keysdown={} end
  while Y.sdl.pollEvent(eventptr) > 0 do
    event = eventptr[0]
    if event.type == Y.sdl.KEYDOWN then
      if event.key.keysym.scancode==Y.sdl.SCANCODE_UP then
        self.keysdown.up=true
      elseif event.key.keysym.scancode==Y.sdl.SCANCODE_DOWN then
        self.keysdown.down=true
      end
    elseif event.type == Y.sdl.KEYUP then
      if event.key.keysym.scancode==Y.sdl.SCANCODE_ESCAPE then
        GAME.running=false
      elseif event.key.keysym.scancode==Y.sdl.SCANCODE_UP then
        self.keysdown.up=nil
      elseif event.key.keysym.scancode==Y.sdl.SCANCODE_DOWN then
        self.keysdown.down=nil
      end
    elseif event.type == Y.sdl.WINDOWEVENT and event.window.event == Y.sdl.WINDOWEVENT_RESIZED then
      self.winsize={event.window.data1,event.window.data2}
      Y.gl.Viewport(0,0,unpack(self.winsize))
      self:setProjection()
    end
  end
  if GAME.playerSide>0 then
    if self.keysdown.up then
      GAME.paddles[GAME.playerSide]=GAME.paddles[GAME.playerSide]+180/self.fps.current
      if GAME.paddles[GAME.playerSide] > 275 then -- 300 - the 25 the paddle extends to the top
        GAME.paddles[GAME.playerSide]=275
      end
    elseif self.keysdown.down then
      GAME.paddles[GAME.playerSide]=GAME.paddles[GAME.playerSide]-180/self.fps.current
      if GAME.paddles[GAME.playerSide] < -275 then -- -300 + the 25 the paddle extends to the bottom
        GAME.paddles[GAME.playerSide]=-275
      end
    end
  end
  Y.gl.ClearColor(0,0,0,1)
  Y.gl.Clear(Y.gl.COLOR_BUFFER_BIT)
  Y.gl.BindFramebuffer(Y.gl.FRAMEBUFFER, self.fbo)
  Y.gl.Clear(Y.gl.COLOR_BUFFER_BIT)
  Y.gl.BindVertexArray(0)
  self:renderQuad(-400, 295, 800,   5) -- top
  self:renderQuad(-400,-300, 800,   5) -- bottom
  self:renderQuad(-400,-300,   5, 600) -- left
  self:renderQuad( 395,-300,   5, 600) -- right
  font(GAME.scores[1],-200,200,10)
  font(GAME.scores[2], 170,200,10) -- the digit's lower left is its position, and it's size is 10, and because all digits have a width of 3 bit, you need 200-(10*3)=170
  for i=-285,285, 20 do
    self:renderQuad(-2,i,4,10)
  end
  self:renderQuad(-380,GAME.paddles[1]-25,8,50)
  self:renderQuad( 372,GAME.paddles[2]-25,8,50)
  local fpsstr=tostring(self.fps.current) -- convert FPS to string
  for i=1,#fpsstr do -- iterate over it's characters
    font(tonumber(fpsstr:sub(i,i)),-380+7*i,280,2) -- render each digit individually while advancing x by 7 (fontsize 2 means a digit is 6 wide, +1px margin)
  end
  self:renderQuad(GAME.ball[1]-5,GAME.ball[2]-5,10,10)
  Y.gl.BindFramebuffer(Y.gl.FRAMEBUFFER, 0)
  Y.gl.UseProgram(self.postshader)
  Y.gl.BindTexture(Y.gl.TEXTURE_2D, self.fbo_texture)
  Y.gl.Uniform1i(self.upost_fbo_texture, 0)
  Y.gl.BindVertexArray(self.vao)
  Y.gl.DrawElements(Y.gl.TRIANGLES, 6, Y.gl.UNSIGNED_INT, ffi.NULL)
  Y.sdl.gL_SwapWindow(self.window)
end

return M -- return the module table