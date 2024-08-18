package doomer

import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

render :: proc(player: Player, worldmap: WorldMap, wall_texture: rl.Texture, floor_image: rl.Image) {
    grid_start :: rl.Vector2 { 0, 0 }
    grid_end :: rl.Vector2 { win_height/3, win_height/3 }

    rl.BeginDrawing()
        rl.ClearBackground(rl.RAYWHITE)
        draw_player_view(win_width, win_height, player, worldmap, wall_texture, floor_image)
        draw_grid(grid_start, grid_end, worldmap)
        rl.DrawCircleV(screen_pos(grid_start, grid_end, player.pos, worldmap.size), player.size/f32(worldmap.size.x)*(grid_end.x-grid_start.x), rl.RED)
        player_pos := screen_pos(grid_start, grid_end, player.pos, worldmap.size)
        player_direction := screen_pos(grid_start, grid_end, player.pos + player.direction, worldmap.size)
        camera_plane := screen_pos(grid_start, grid_end, player.pos + player.direction + player.camera_plane, worldmap.size)
        neg_camera_plane := screen_pos(grid_start, grid_end, player.pos + player.direction - player.camera_plane, worldmap.size)
        rl.DrawLineEx(player_pos, camera_plane, 5, rl.PURPLE)
        rl.DrawLineEx(player_pos, neg_camera_plane, 5, rl.PURPLE)
        rl.DrawLineEx(neg_camera_plane, camera_plane, 5, rl.PURPLE)
        rl.DrawText(rl.TextFormat("%v", rl.GetFPS()), 10, 10, 20, rl.LIGHTGRAY)
    rl.EndDrawing()
}

draw_grid :: proc(start_pos, end_pos: rl.Vector2, worldmap: WorldMap) {
    draw_walls(start_pos, end_pos, worldmap)
    lengths := end_pos - start_pos
    for col in 0..=worldmap.size.x {
        x := start_pos.x + col*lengths.x/grid_cols
        line_start := rl.Vector2 { x, start_pos.y }
        line_end := rl.Vector2 { x, end_pos.y }
        rl.DrawLineV(line_start, line_end, rl.BLACK)
    }
    for row in 0..=worldmap.size.y {
        y := start_pos.y + row*lengths.y/grid_rows 
        line_start := rl.Vector2 { start_pos.x, y }
        line_end := rl.Vector2 { end_pos.x, y }
        rl.DrawLineV(line_start, line_end, rl.BLACK)
    }
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

draw_player_view :: proc(width, height: i32, player: Player, worldmap: WorldMap, wall_texture: rl.Texture, floor_image: rl.Image) {
    for y in 0..<height {
        bg_color: rl.Color
        gradient_color := u8(255 - math.abs((255 *y / height) - 255/2))
        bg_color.r = gradient_color
        bg_color.g = gradient_color
        bg_color.b = gradient_color
        bg_color.a = 255
        rl.DrawLineV({0, f32(y)}, {f32(width), f32(y)}, bg_color)
    }

    for x in 0..<width {
        camera_x: f32 = 2*f32(x)/f32(width) - 1
        ray_direction := player.pos + player.direction + player.camera_plane * camera_x
        hit, x_side, hit_point := raycast_hit_point(player.pos, ray_direction, worldmap)
        if hit {
            perp_wall_distance := linalg.length(hit_point - player.pos) * math.cos(rl.Vector2Angle(player.direction, player.direction+player.camera_plane*camera_x))
            max_distance := worldmap.size.x if worldmap.size.x > worldmap.size.y else worldmap.size.y

            line_height := f32(height) / perp_wall_distance
            draw_start := (f32(height) - line_height)*0.5
            draw_end := draw_start + line_height

            tex_x: f32
            highlight: rl.Color
            if x_side {
                tex_x = (hit_point.y-math.floor(hit_point.y)) * f32(wall_texture.width)
                highlight = rl.RAYWHITE
            } else {
                tex_x = (hit_point.x-math.floor(hit_point.x)) * f32(wall_texture.width)
                highlight = rl.GRAY
            }
            tex_start: f32 = 0
            tex_end: f32 = f32(wall_texture.height)
            src_rect := rl.Rectangle { tex_x, tex_start, 1, tex_end }
            dst_rect := rl.Rectangle { f32(x), draw_start, 1, draw_end-draw_start }
            rl.DrawTexturePro(wall_texture, src_rect, dst_rect, 0, 0, highlight)
        }
    }
}


