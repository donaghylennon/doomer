package doomer

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

win_width  :: 1400
win_height :: 900

grid_cols :: 60
grid_rows :: 40

Player :: struct {
    pos: rl.Vector2,
    size: f32,
    direction: rl.Vector2,
    camera_plane: rl.Vector2
}

WorldMap :: struct {
    cells: [grid_cols][grid_rows]bool,
    size: rl.Vector2
}

main :: proc() {
    rl.InitWindow(win_width, win_height, "Raylib Game")
    defer rl.CloseWindow()
    rl.SetTargetFPS(60)
    rl.SetExitKey(.Q)

    wall_image := rl.LoadImage("res/stone-bricks.png")
    wall_texture := rl.LoadTextureFromImage(wall_image)
    defer rl.UnloadImage(wall_image)
    defer rl.UnloadTexture(wall_texture)

    floor_image := rl.LoadImage("res/wooden-floor.png")
    defer rl.UnloadImage(floor_image)

    player := Player { { 5, 5 }, 0.3, { 0, -0.3 }, 0 }
    player.camera_plane = rl.Vector2Rotate(player.direction, math.PI*0.5)

    worldmap: WorldMap
    worldmap.size = { grid_cols, grid_rows }
    generate_dungeon(grid_cols, grid_rows, &worldmap)
    init_player_pos(&player, worldmap)

    for !rl.WindowShouldClose() {
        dt := rl.GetFrameTime()
        handle_input(&player, worldmap, dt)
        render(player, worldmap, wall_texture, floor_image)
    }
}

screen_pos :: proc(start_pos, end_pos, world_pos, world_size: rl.Vector2) -> rl.Vector2 {
    screen_lengths := end_pos - start_pos
    return start_pos + world_pos*screen_lengths/world_size
}

screen_size :: proc(start_pos, end_pos, world_size, size: rl.Vector2) -> rl.Vector2 {
    screen_lengths := end_pos - start_pos
    return size*screen_lengths/world_size
}

world_pos :: proc(start_pos, end_pos, screen_pos, world_size: rl.Vector2) -> rl.Vector2 {
    screen_lengths := end_pos - start_pos
    return (screen_pos - start_pos) / screen_lengths * world_size
}

handle_input :: proc(player: ^Player, worldmap: WorldMap, dt: f32) {
    world_size: [2]uint = linalg.to_uint(worldmap.size)
    speed: f32 = 10
    rot_speed: f32 = 1
    if rl.IsKeyDown(.A) {
        rotate_player(player, worldmap, -rot_speed*dt*math.PI)
    }
    if rl.IsKeyDown(.D) {
        rotate_player(player, worldmap, rot_speed*dt*math.PI)
    }
    if rl.IsKeyDown(.W) {
        move_player(player, worldmap, dt*speed*player.direction)
    }
    if rl.IsKeyDown(.S) {
        move_player(player, worldmap, -dt*speed*player.direction)
    }
}

move_player :: proc(player: ^Player, worldmap: WorldMap, displacement: rl.Vector2) {
    // TODO: figure out more sophisticated movement (that won't break when moving more
    // than a small amount at a time
    new_pos := player.pos + displacement
    new_pos = {
        clamp(new_pos.x, 0+player.size, worldmap.size.x-player.size),
        clamp(new_pos.y, 0+player.size, worldmap.size.y-player.size)
    }
    flp := linalg.floor(new_pos)
    if displacement.x > 0 {
        if displacement.y > 0 {
            if new_pos.x + player.size < worldmap.size.x && new_pos.y + player.size < worldmap.size.y {
                cell: [2]uint = { uint(math.floor_f32(new_pos.x + player.size)), uint(math.floor_f32(new_pos.y + player.size)) }
                if worldmap.cells[cell.x][cell.y] {
                    return
                }
                player.pos = new_pos
            }
        } else {
            if new_pos.x + player.size < worldmap.size.x && new_pos.y - player.size < worldmap.size.y {
                cell: [2]uint = { uint(math.floor_f32(new_pos.x + player.size)), uint(math.floor_f32(new_pos.y - player.size)) }
                if worldmap.cells[cell.x][cell.y] {
                    return
                }
                player.pos = new_pos
            }
        }
    } else {
        if displacement.y > 0 {
            if new_pos.x - player.size < worldmap.size.x && new_pos.y + player.size < worldmap.size.y {
                cell: [2]uint = { uint(math.floor_f32(new_pos.x - player.size)), uint(math.floor_f32(new_pos.y + player.size)) }
                if worldmap.cells[cell.x][cell.y] {
                    return
                }
                player.pos = new_pos
            }
        } else {
            if new_pos.x - player.size < worldmap.size.x && new_pos.y - player.size < worldmap.size.y {
                cell: [2]uint = { uint(math.floor_f32(new_pos.x - player.size)), uint(math.floor_f32(new_pos.y - player.size)) }
                if worldmap.cells[cell.x][cell.y] {
                    return
                }
                player.pos = new_pos
            }
        }
    }
}

rotate_player :: proc(player: ^Player, worldmap: WorldMap, angle: f32) {
    player.direction = rl.Vector2Rotate(player.direction, angle)
    player.camera_plane = rl.Vector2Rotate(player.camera_plane, angle)
}

ray_step :: proc(p1, p2: rl.Vector2) -> rl.Vector2 {
    return {}
}

raycast_hit_point :: proc(p1, p2: rl.Vector2, worldmap: WorldMap) -> (hit: bool, x_side: bool, hit_point: rl.Vector2) {
    ray_direction := linalg.normalize(p2 - p1)
    current_cell := linalg.to_int(p1)
    ray_unit_step_size := rl.Vector2 { math.sqrt(1 + (ray_direction.y / ray_direction.x) * (ray_direction.y / ray_direction.x)),
                                        math.sqrt(1 + (ray_direction.x / ray_direction.y) * (ray_direction.x / ray_direction.y)) }

    ray_lengths_1D: rl.Vector2
    step: [2]int

    if ray_direction.x < 0 {
        step.x = -1
        ray_lengths_1D.x = (p1.x - f32(current_cell.x)) * ray_unit_step_size.x
    } else {
        step.x = 1
        ray_lengths_1D.x = (f32(current_cell.x + 1) - p1.x) * ray_unit_step_size.x
    }
    if ray_direction.y < 0 {
        step.y = -1
        ray_lengths_1D.y = (p1.y - f32(current_cell.y)) * ray_unit_step_size.y
    } else {
        step.y = 1
        ray_lengths_1D.y = (f32(current_cell.y + 1) - p1.y) * ray_unit_step_size.y
    }

    max_distance: f32 = 100
    distance: f32 = 0
    hit = false
    for !hit && distance < max_distance {
        if ray_lengths_1D.x < ray_lengths_1D.y {
            x_side = true
            current_cell.x += step.x
            distance = ray_lengths_1D.x
            ray_lengths_1D.x += ray_unit_step_size.x
        } else {
            x_side = false
            current_cell.y += step.y
            distance = ray_lengths_1D.y
            ray_lengths_1D.y += ray_unit_step_size.y
        }

        if current_cell.x >= 0 && current_cell.y >= 0 &&
            current_cell.x < int(worldmap.size.x) && current_cell.y < int(worldmap.size.y) {
            if worldmap.cells[current_cell.x][current_cell.y] {
                hit = true
            }
        }
    }
    
    hit_point = p1 + ray_direction * distance
    return hit, x_side, hit_point
}

DungeonRoom :: struct {
    startx: i32,
    starty: i32,
    width: i32,
    height: i32
}

generate_dungeon :: proc(x, y: uint, worldmap: ^WorldMap) {
    n, m: uint = 3, 2
    sector_width := x/n
    sector_height := y/m

    for i in 0..<x {
        for j in 0..<y {
            worldmap.cells[i][j] = true
        }
    }

    rooms := make(map[[2]uint]DungeonRoom)
    defer delete(rooms)

    for i in 0..<n {
        for j in 0..<m {
            sector_startx:= i32(i * sector_width)
            sector_starty:= i32(j * sector_height)
            room_width := rl.GetRandomValue(3, i32(sector_width-2))
            room_height := rl.GetRandomValue(3, i32(sector_height-2))
            startx := sector_startx + rl.GetRandomValue(2, i32(sector_width)-2-room_width)
            starty := sector_starty + rl.GetRandomValue(2, i32(sector_height)-2-room_height)
            rooms[{i,j}] = DungeonRoom {startx, starty, room_width, room_height}
            for s in startx..<startx+room_width {
                for t in starty..<starty+room_height {
                    worldmap.cells[s][t] = false
                }
            }
        }
    }

    for i in 0..<n {
        for j in 0..<m {
            room := rooms[{i,j}]
            if i + 1 < n {
                adjacent := rooms[{i+1,j}]
                x1 := room.startx + room.width
                x2 := adjacent.startx
                c1 := [2]i32 { rl.GetRandomValue(x1+1, x2-1), rl.GetRandomValue(room.starty+1, room.starty+room.height-1) }
                c2 := [2]i32 { rl.GetRandomValue(x1+1, x2-1), rl.GetRandomValue(adjacent.starty+1, adjacent.starty+adjacent.height-1) }
                if c1.x > c2.x {
                    temp := c1.x
                    c1.x = c2.x
                    c2.x = temp
                }
                for x in x1..=c1.x {
                    worldmap.cells[x][c1.y] = false
                }
                miny, maxy : i32
                if c1.y < c2.y do miny, maxy = c1.y, c2.y
                else do miny, maxy = c2.y, c1.y
                for y in miny..=maxy {
                    worldmap.cells[c1.x][y] = false
                }
                for x in c1.x..=x2 {
                    worldmap.cells[x][c2.y] = false
                }
                worldmap.cells[c1.x][c1.y] = false
                worldmap.cells[c2.x][c2.y] = false
            }
            if j + 1 < m {
                adjacent := rooms[{i,j+1}]
                y1 := room.starty + room.height
                y2 := adjacent.starty
                c1 := [2]i32 { rl.GetRandomValue(room.startx+1, room.startx+room.width-1), rl.GetRandomValue(y1+1, y2-1) }
                c2 := [2]i32 { rl.GetRandomValue(adjacent.startx+1, adjacent.startx+adjacent.width-1), rl.GetRandomValue(y1+1, y2-1) }
                if c1.y > c2.y {
                    temp := c1.y
                    c1.y = c2.y
                    c2.y = temp
                }
                for y in y1..=c1.y {
                    worldmap.cells[c1.x][y] = false
                }
                minx, maxx : i32
                if c1.x < c2.x do minx, maxx = c1.x, c2.x
                else do minx, maxx = c2.x, c1.x
                for x in minx..=maxx {
                    worldmap.cells[x][c1.y] = false
                }
                for y in c1.y..=y2 {
                    worldmap.cells[c2.x][y] = false
                }
                worldmap.cells[c1.x][c1.y] = false
                worldmap.cells[c2.x][c2.y] = false
            }
        }
    }
}

init_player_pos :: proc(player: ^Player, worldmap: WorldMap) {
    // TODO: remove this and init from dungeon generation
    for i in 0..<len(worldmap.cells) {
        for j in 0..<len(worldmap.cells[0]) {
            if !worldmap.cells[i][j] {
                player.pos = { f32(i), f32(j)+player.size+0.2 }
                break
            }
        }
    }
}
