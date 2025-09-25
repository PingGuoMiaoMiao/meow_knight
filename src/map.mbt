///|
fn add_grass(pos : @math.Vec2D, sprite_id : String) -> Unit {
  let src_pos = match sprite_id {
    "0" => @math.Vec2D(16.0 * 0, 16.0 * 0)
    "1" => @math.Vec2D(16.0 * 1, 16.0 * 0)
    "2" => @math.Vec2D(16.0 * 2, 16.0 * 0)
    _ => panic()
  }
  let sprite = @sprite.Sprite::from_animation(
    @sprite.Animation::single_frame(
      "sprite_fusion/spritesheet.png",
      @math.Vec2D(16.0, 16.0),
      offset=src_pos,
    ),
    10,
  )
  let grass = @system.Entity::new()
  @sprite.sprites.set(grass, sprite)
  @position.positions.set(grass, pos)
  @collision.shapes.set(
    grass,
    Rect(size=@math.Vec2D(16.0, 16.0), offset=@math.Vec2D::zero()),
  )
  @collision.collision_layers.set(grass, terrain_collision_layer)
}

///|
fn tile_to_vec2d(tile : @tilemap.Tile, tile_size : Int) -> @math.Vec2D {
  @math.Vec2D(
    tile.x.to_double() * tile_size.to_double(),
    tile.y.to_double() * tile_size.to_double(),
  )
}



///|
fn generate_map() -> Unit {
  let tilemap = @tilemap.TileMap::from_json(tilemap)
  let world_width = tilemap.map_width.to_double() *
    tilemap.tile_size.to_double()
  let world_height = tilemap.map_height.to_double() *
    tilemap.tile_size.to_double()
  @camera.set_limits(top=0.0, bottom=world_height, left=0.0, right=world_width)
  let mask_dude = tilemap.get_tiles_first("Role")[0]
  add_player(tile_to_vec2d(mask_dude, tilemap.tile_size))
  let grasses = tilemap.get_tiles("Grass")
  for grass in grasses {
    add_grass(tile_to_vec2d(grass, tilemap.tile_size), grass.id)
  }
  let skeletons = tilemap.get_tiles_first("Enemy")
  for skeleton in skeletons {
    add_enemy(tile_to_vec2d(skeleton, tilemap.tile_size))
  }
}