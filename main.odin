package doomer

import "core:fmt"
import "core:strings"
import "core:strconv"
import rl "vendor:raylib"

win_width  :: 800
win_height :: 400

grid_cols :: 20
grid_rows :: 20

Player :: struct {
    pos: rl.Vector2,
    size: f32
}

main :: proc() {
    rl.InitWindow(win_width, win_height, "Raylib Game")
    defer rl.CloseWindow()
    rl.SetTargetFPS(60)

    player :: Player { { 10, 10 }, 0.3 }
    world_size :: rl.Vector2 { grid_cols, grid_rows }
    grid_start :: rl.Vector2 { 10, 10 }
    grid_end :: rl.Vector2 { 300, 300 }

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
            rl.ClearBackground(rl.RAYWHITE)
            draw_grid(grid_start, grid_end)
            rl.DrawCircleV(screen_pos(grid_start, grid_end, world_size, player.pos), player.size/20*(300-10), rl.RED)
            rl.DrawText("First Window!", 350, 190, 20, rl.LIGHTGRAY)
            rl.DrawText(rl.TextFormat("%v", rl.GetFPS()), 10, 10, 20, rl.LIGHTGRAY)
        rl.EndDrawing()
    }
}

screen_pos :: proc(start_pos, end_pos, world_size, world_pos: rl.Vector2) -> rl.Vector2 {
    screen_lengths := end_pos - start_pos
    return start_pos + world_pos*screen_lengths/world_size
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
