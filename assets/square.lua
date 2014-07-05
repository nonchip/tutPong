return{ -- a "unit square"
  0, 1, -- 0: top left
  0, 0, -- 1: bottom left
  1, 0, -- 2: bottom right
  1, 1, -- 3: top right
},{
  0, 1, 2, -- lower left triangle
  2, 3, 0, -- upper right triangle
}