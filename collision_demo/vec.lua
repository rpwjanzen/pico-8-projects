-- vec - 2D Vector
-- {x,y}
function vec_eq(a,b)
 return a.x == b.x and a.y == b.y
end

function vec_diff(a,b)
 return { x = a.x - b.x, y = a.y - b.y }
end

function vec_sub(a,b)
 return vec_diff(a,b)
end

function vec_add(a,b)
 return { x = a.x + b.x, y = a.y + b.y }
end

function vec_div(v,n)
 return {x = v.x / n, y = v.y / n}
end

function vec_mul(v,n)
 return {x = v.x * n, y = v.y * n}
end

function vec_normalize(v)
 return vec_div(v, vec_length(v))
end

function vec_dot(a,b)
 return a.x * b.x + a.y * b.y
end

function vec_length_squared(v)
 return v.x * v.x + v.y * v.y
end

function vec_length(v)
 return sqrt(v.x * v.x + v.y * v.y)
end

function vec_negate(v)
 return {x=-v.x,y=-v.y}
end

function vec_mid(a,b,c)
 return {x=mid(a.x,b.x,c.x),y=mid(a.y,b.y,c.y)}
end

vec_up = {x=0,y=-1}
vec_down = {x=0,y=1}
vec_left = {x=-1,y=0}
vec_right = {x=1,y=0}