-- collision engine stuff
-- 2d rigid body physics
-- https://gamedevelopment.tutsplus.com/tutorials/how-to-create-a-custom-2d-physics-engine-the-basics-and-impulse-resolution--gamedev-6331


function _draw()
 cls(1)
 circ(ball.body.position.x, ball.body.position.y, ball.body.radius, 7)
 for i=1,#boxes do
    draw_box(boxes[i])
 end

 --print('v.y:' .. ball.body.velocity.y)
 --print(debug)
end

function draw_box(box)
 rect(
  box.body.position.x - box.body.hw,
  box.body.position.y - box.body.hh,
  box.body.position.x + box.body.hw,
  box.body.position.y + box.body.hh,
  7
 )
end

function _update60()
 --if btnp(5) then
  step(bodies)
 --end
end

function step(bodies)
    -- move all bodies
    for i=1,#bodies do
        local b = bodies[i]
        b.position.x = b.position.x + b.velocity.x
        b.position.y = b.position.y + b.velocity.y
    end
 
    local collisions = {}
    -- n^2 - bad performance and wrong
    for i=1,#bodies - 1 do
        local a = bodies[i]
        for j=i+1,#bodies do
            local b = bodies[j]
            if a.type == BODY_TYPE_CIRCLE and b.type == BODY_TYPE_CIRCLE then
                if is_circle_circle_collided(a, b) then
                add(collisions, {a,b})
                end
            elseif a.type == BODY_TYPE_CIRCLE and b.type == BODY_TYPE_BOX then
                if is_circle_box_collided(a, b) then
                    add(collisions, {a,b})
                end
            elseif a.type == BODY_TYPE_BOX and b.type == BODY_TYPE_CIRCLE then
                if is_box_circle_collided(a, b) then
                    add(collisions, {a,b})
                end
            elseif a.type == BODY_TYPE_BOX and b.type == BODY_TYPE_BOX then
                if is_box_box_collided(a, b) then
                    add(collisions, {a,b})
                end
            end
        end
    end

    local collision_manifolds = {}
    for i=1,#collisions do
        local c = collisions[i]
        local m = collision_manifold(c[1],c[2])
        add(collision_manifolds, m)
    end

    -- resolve all collisions
    for i=1,#collision_manifolds do
        local m = collision_manifolds[i]
        resolve_collision(m)
    end
end

function _init()
    debug = ''
    bodies = {}
    ball = {
        body = {
            position={x = 64,y = 48},
            velocity={x = 1.3, y = 0.3},
            inv_mass = 1/2,
            restitution = 1,
            radius = 2,
            type = BODY_TYPE_CIRCLE,
            active = true,
        }
    }
    add(bodies, ball.body)

    boxes = {}
    for i=1,10 do
        for j = 1,5 do
            local box = {
                body = {
                    position = {x=7 + (i-1)*12,y=20+j*8},
                    velocity = {x=0,y=0},
                    inv_mass = 0,
                    restitution = 0,
                    hw = 5,
                    hh = 3,
                    type = BODY_TYPE_BOX,
                    active = true,
                }
            }
            add(boxes, box)
            add(bodies, box.body)
        end
    end
end