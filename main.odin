package doomer

import "core:fmt"
import "core:strings"
import "core:strconv"
import rl "vendor:raylib"

win_width  :: 800
win_height :: 400

grid_cols :: 10
grid_rows :: 10

Player :: struct {
    pos: rl.Vector2,
    size: f32
}

main :: proc() {
    rl.InitWindow(win_width, win_height, "Raylib Game")
    defer rl.CloseWindow()
    rl.SetTargetFPS(60)

    player := Player { { 5, 5 }, 0.3 }
    world_size :: rl.Vector2 { grid_cols, grid_rows }
    grid_start :: rl.Vector2 { 200, 0 }
    grid_end :: rl.Vector2 { 600, 400 }

    grid: [grid_rows][grid_cols]bool
    grid[0][0] = true;
    grid[1][0] = true;
    grid[0][1] = true;

    for !rl.WindowShouldClose() {
        if rl.IsKeyPressed(.A) {
            player.pos.x -= 0.5
            if player.pos.x < 0 do player.pos.x = 0
        } else if rl.IsKeyPressed(.D) {
            player.pos.x += 0.5
            if player.pos.x > world_size.x do player.pos.x = world_size.x
        } else if rl.IsKeyPressed(.W) {
            player.pos.y -= 0.5
            if player.pos.y < 0 do player.pos.y = 0
        } else if rl.IsKeyPressed(.S) {
            player.pos.y += 0.5
            if player.pos.y > world_size.y do player.pos.y = world_size.y
        }

        rl.BeginDrawing()
            rl.ClearBackground(rl.RAYWHITE)
            draw_walls(grid_start, grid_end, world_size, grid)
            draw_grid(grid_start, grid_end)
            rl.DrawCircleV(screen_pos(grid_start, grid_end, world_size, player.pos), player.size/world_size.x*(grid_end.x-grid_start.x), rl.RED)
            rl.DrawText(rl.TextFormat("%v", rl.GetFPS()), 10, 10, 20, rl.LIGHTGRAY)
        rl.EndDrawing()
    }
}

screen_pos :: proc(start_pos, end_pos, world_size, world_pos: rl.Vector2) -> rl.Vector2 {
    screen_lengths := end_pos - start_pos
    return start_pos + world_pos*screen_lengths/world_size
}

screen_size :: proc(start_pos, end_pos, world_size, size: rl.Vector2) -> rl.Vector2 {
    screen_lengths := end_pos - start_pos
    return size*screen_lengths/world_size
}

draw_walls :: proc(grid_start, grid_end, world_size: rl.Vector2, grid: [grid_rows][grid_cols]bool) {
    for x in 0..<grid_cols {
        for y in 0..<grid_rows {
            if grid[x][y] {
                cell_start := rl.Vector2{f32(x),f32(y)}
                cell_end := rl.Vector2{f32(x+1),f32(y+1)}
                cell_start_screen := screen_pos(grid_start, grid_end, world_size, cell_start)
                cell_size_screen := screen_size(grid_start, grid_end, world_size, 1)
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
        y := start_pos.y + f32(row)*lengths.y/grid_cols 
        line_start := rl.Vector2 { start_pos.x, y }
        line_end := rl.Vector2 { end_pos.x, y }
        rl.DrawLineV(line_start, line_end, rl.BLACK)
    }
}
