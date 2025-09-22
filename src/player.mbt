let player_idle_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "/asserts/Colour1/NoOutline/120x80_PNGSheets/_Idle.png",
    12,
    width=120.0,
    height=80.0,
  ),
  loop_=true,
  fps=12,
)

fn add_player(pos : @math.Vec2D) -> Unit {
  let player_sprite = @sprite.Sprite::from_animation(player_idle_animation , 10);
  @sprite.sprites.set(game_state.player, player_sprite);
  @velocity.velocities.set(game_state.player, @math.Vec2D::zero());
  @position.positions.set(game_state.player, pos);
  @collision.shapes.set(
    game_state.player,
    Rect(size=@math.Vec2D(120.0, 80.0),offset=@math.Vec2D::zero())
  )
  @collision.collision_layers.set(game_state.player, player_collision_layer);
  @collision.colliders.set(
    game_state.player,
    @collision.Collider::new(
      @collision.CollisionMask::new([
        terrain_collision_layer,
        enemy_collision_layer,
      ])
    )
  )
    @camera.attach_entity(game_state.player, @math.Vec2D(16.0, 16.0))
}

///|
enum PlayerState {
  Idle
} derive(Show)

///|
const GRAVITY = 1800.0

///|
const MAX_RUN_V = 240.0

///|
const JUMP_V = 680.0

///|
const MAX_FALL_V = 900.0

///|
const RUN_ACC = 3600.0

///|
const BUMP_V : Double = JUMP_V / 2.0

///|
fn player_collision_system(_delta : Double) -> Unit {
  if game_state.hurt_timer > 0.0 {
    game_state.hurt_timer -= 1.0
  }
  
}

