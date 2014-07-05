local facew,faceh=3,5

local zero={
  1,1,1,
  1,0,1,
  1,0,1,
  1,0,1,
  1,1,1
}

local one={
  0,0,1,
  0,0,1,
  0,0,1,
  0,0,1,
  0,0,1
}

local two={
  1,1,1,
  0,0,1,
  1,1,1,
  1,0,0,
  1,1,1
}

local three={
  1,1,1,
  0,0,1,
  1,1,1,
  0,0,1,
  1,1,1
}

local four={
  1,0,1,
  1,0,1,
  1,1,1,
  0,0,1,
  0,0,1
}

local five={
  1,1,1,
  1,0,0,
  1,1,1,
  0,0,1,
  1,1,1
}

local six={
  1,1,1,
  1,0,0,
  1,1,1,
  1,0,1,
  1,1,1
}

local seven={
  1,1,1,
  0,0,1,
  0,0,1,
  0,0,1,
  0,0,1
}

local eight={
  1,1,1,
  1,0,1,
  1,1,1,
  1,0,1,
  1,1,1
}

local nine={
  1,1,1,
  1,0,1,
  1,1,1,
  0,0,1,
  1,1,1
}

local font={one,two,three,four,five,six,seven,eight,nine,[0]=zero}

local meshw,meshh,meshd=4,6,2

local meshVerts={
  0,5, 1,5, 2,5, 3,5, --  0
  0,4, 1,4, 2,4, 3,4, --  4
  0,3, 1,3, 2,3, 3,3, --  8
  0,2, 1,2, 2,2, 3,2, -- 12
  0,1, 1,1, 2,1, 3,1, -- 16
  0,0, 1,0, 2,0, 3,0, -- 20
}

local function faceOffsetToMeshVerts(fo) -- don't ask how I figured this out, was a pain in the ass. probably because I was high.
  fo=fo-1 -- and it took my 2 hours to realize I need this line. because see above.
  local mo=fo%facew+math.floor(fo/facew)*meshw
  return mo,mo+1,mo+meshw,mo+meshw+1
end

local vaocache={}
local shader,attr,tmodel

local function getVao(digit,x,y,s)
  if vaocache[digit] then return vaocache[digit](x,y,s) end
  local meshOffsets={}
  for o=1,facew*faceh do
    if font[digit][o]==1 then
      local tl,tr,bl,br=faceOffsetToMeshVerts(o)
      table.insert(meshOffsets,bl)
      table.insert(meshOffsets,br)
      table.insert(meshOffsets,tl)
      table.insert(meshOffsets,br)
      table.insert(meshOffsets,tr)
      table.insert(meshOffsets,tl)
    end
  end
  local vao=Y.gl.mkVAO(shader,Y.gl.STATIC_DRAW,meshOffsets,{'int',meshVerts,attr,2})
  local num=#meshOffsets
  vaocache[digit]=function(x,y,s)
    Y.gl.BindVertexArray(vao)
    Y.gl.UseProgram(shader)
    local transform=Y.math.translate(x,y,0)
    transform=transform*Y.math.mat4(s, 0, 0, 0,
                                    0, s, 0, 0,
                                    0, 0, 1, 0,
                                    0, 0, 0, 1)
    Y.gl.UniformMatrix4fv(tmodel, 1, Y.gl.TRUE, transform.gl) -- upload the matrix
    Y.gl.DrawElements(Y.gl.TRIANGLES, num, Y.gl.UNSIGNED_INT, ffi.NULL)
  end
  return vaocache[digit](x,y,s)
end

local function init(_shader,_attr,_tmodel)
  shader=_shader
  attr=_attr
  tmodel=_tmodel
  return getVao
end

return init