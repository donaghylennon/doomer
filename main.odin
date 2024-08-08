package doomer

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

win_width  :: 600
win_height :: 600

grid_cols :: 10
grid_rows :: 10

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

    player := Player { { 5, 5 }, 0.1, { 0, -0.3 }, 0 }
    player.camera_plane = rl.Vector2Rotate(player.direction, math.PI*0.5)
    world_size :: rl.Vector2 { grid_cols, grid_rows }
    grid_start :: rl.Vector2 { 0, 0 }
    grid_end :: rl.Vector2 { 600, 600 }

    worldmap: WorldMap
    worldmap.cells[0][0] = true
    worldmap.cells[1][0] = true
    worldmap.cells[5][0] = true
    worldmap.cells[0][1] = true
    worldmap.cells[0][grid_rows-1] = true
    worldmap.cells[grid_cols-1][0] = true
    worldmap.size = { grid_cols, grid_rows }

    for !rl.WindowShouldClose() {
        dt := rl.GetFrameTime()
        handle_input(&player, worldmap, dt)
        mouse_pos := rl.GetMousePosition()
        mouse_world_pos := world_pos(grid_start, grid_end, mouse_pos, world_size)
        if (rl.IsMouseButtonDown(rl.MouseButton.LEFT)) {
            world_pos := linalg.to_uint(mouse_world_pos)
            worldmap.cells[world_pos.x][world_pos.y] = true
        }

        rl.BeginDrawing()
            rl.ClearBackground(rl.RAYWHITE)
            draw_walls(grid_start, grid_end, worldmap)
            draw_grid(grid_start, grid_end)
            rl.DrawCircleV(screen_pos(grid_start, grid_end, player.pos, worldmap.size), player.size/f32(worldmap.size.x)*(grid_end.x-grid_start.x), rl.RED)
            rl.DrawCircleV(mouse_pos, 0.1*rl.Vector2Length(grid_end - grid_start)/rl.Vector2Length(worldmap.size), rl.BLUE)
            player_pos := screen_pos(grid_start, grid_end, player.pos, worldmap.size)
            player_direction := screen_pos(grid_start, grid_end, player.pos + player.direction, worldmap.size)
            camera_plane := screen_pos(grid_start, grid_end, player.pos + player.direction + player.camera_plane, worldmap.size)
            neg_camera_plane := screen_pos(grid_start, grid_end, player.pos + player.direction - player.camera_plane, worldmap.size)
            hit, hit_point := cast_ray_toward_point(player.pos, mouse_world_pos, worldmap)
            screen_hit_point := screen_pos(grid_start, grid_end, hit_point, world_size)
            rl.DrawCircleV(screen_hit_point, 5, rl.YELLOW)
            rl.DrawLineV(player_pos, screen_hit_point, rl.BLACK)
            rl.DrawLineEx(player_pos, camera_plane, 5, rl.PURPLE)
            rl.DrawLineEx(player_pos, neg_camera_plane, 5, rl.PURPLE)
            rl.DrawLineEx(neg_camera_plane, camera_plane, 5, rl.PURPLE)
            rl.DrawText(rl.TextFormat("%v", rl.GetFPS()), 10, 10, 20, rl.LIGHTGRAY)
        rl.EndDrawing()
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

draw_walls :: proc(grid_start, grid_end: rl.Vector2, worldmap: WorldMap) {
    for x in 0..<uint(worldmap.size.x) {
        for y in 0..<uint(worldmap.size.y) {
            if worldmap.cells[x][y] {
                cell_start := rl.Vector2{f32(x),f32(y)}
                cell_end := rl.Vector2{f32(x+1),f32(y+1)}
                cell_start_screen := screen_pos(grid_start, grid_end, cell_start, worldmap.size)
                cell_size_screen := screen_size(grid_start, grid_end, worldmap.size, 1)
                rl.DrawRectangleV(cell_start_screen, cell_size_screen, rl.BLUE)
            }
        }
    }
}

draw_grid :: proc(start_pos, end_pos: rl.Vector2) {
    lengths := end_pos - start_pos
    for col in 0..=grid_cols {
        x := start_pos.x + f32(col)*lengths.x/grid_cols
        line_start := rl.Vector2 { x, start_pos.y }
        line_end := rl.Vector2 { x, end_pos.y }
        rl.DrawLineV(line_start, line_end, rl.BLACK)
    }
    for row in 0..=grid_rows {
        y := start_pos.y + f32(row)*lengths.y/grid_rows 
        line_start := rl.Vector2 { start_pos.x, y }
        line_end := rl.Vector2 { end_pos.x, y }
        rl.DrawLineV(line_start, line_end, rl.BLACK)
    }
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
        clamp(new_pos.x, 0, worldmap.size.x),
        clamp(new_pos.y, 0, worldmap.size.y)
    }
    flp := linalg.floor(new_pos)
    if new_pos.x < worldmap.size.x && new_pos.y < worldmap.size.y {
        cell: [2]uint = { uint(math.floor_f32(new_pos.x)), uint(math.floor_f32(new_pos.y)) }
        if worldmap.cells[cell.x][cell.y] {
            return
        }
        player.pos = new_pos
    }
}

rotate_player :: proc(player: ^Player, worldmap: WorldMap, angle: f32) {
    player.direction = rl.Vector2Rotate(player.direction, angle)
    player.camera_plane = rl.Vector2Rotate(player.camera_plane, angle)
}

ray_step :: proc(p1, p2: rl.Vector2) -> rl.Vector2 {
    return {}
}

cast_ray_toward_point :: proc(p1, p2: rl.Vector2, worldmap: WorldMap) -> (hit: bool, hit_point: rl.Vector2) {
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
            current_cell.x += step.x
            distance = ray_lengths_1D.x
            ray_lengths_1D.x += ray_unit_step_size.x
        } else {
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
    return hit, hit_point
}
