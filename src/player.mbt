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

///|
let player_run_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "/asserts/Colour2/NoOutline/120x80_PNGSheets/_Run.png",
    12,
    width=120.0,
    height=80.0,
  ),
  loop_=true,
  fps=12,
)

///|
fn add_player(pos : @math.Vec2D) -> Unit {
  let player_sprite = @sprite.Sprite::from_animation(player_idle_animation, 10)
  @sprite.sprites.set(game_state.player, player_sprite)
  @velocity.velocities.set(game_state.player, @math.Vec2D::zero())
  @position.positions.set(game_state.player, pos)
  @collision.shapes.set(
    game_state.player,
    Rect(size=@math.Vec2D(120.0, 80.0), offset=@math.Vec2D(0.0, 0.0)),
  )
  @collision.collision_layers.set(game_state.player, player_collision_layer)
  @collision.colliders.set(
    game_state.player,
    @collision.Collider::new(
      @collision.CollisionMask::new([
        terrain_collision_layer, enemy_collision_layer,
      ]),
    ),
  )
  @camera.attach_entity(game_state.player, @math.Vec2D(16.0, 16.0))
}

///|
enum PlayerState {
  Idle
  Hit
  Jump
  Fall
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
  let player_collision = @collision.get_collision_infos(game_state.player)
}

fn player_state_system(delta : Double) -> Unit {
 let velocity = @collision.real_velocities
    .get(game_state.player)
    .unwrap_or(@math.Vec2D::zero())
  let mut new_velocity_x = velocity.0[X]
  let mut new_velocity_y = velocity.0[Y]
  if !(game_state.player_state is Hit) {
    if @inputs.is_pressed(@inputs.ArrowLeft) {
      new_velocity_x -= RUN_ACC * delta
      if new_velocity_x < -MAX_RUN_V {
        new_velocity_x = -MAX_RUN_V
      }
      game_state.direction = Direction2::Left
    } else if @inputs.is_pressed(@inputs.ArrowRight) {
      new_velocity_x += RUN_ACC * delta
      if new_velocity_x > MAX_RUN_V {
        new_velocity_x = MAX_RUN_V
      }
      game_state.direction = Direction2::Right
    } else {
      new_velocity_x = 0.0
    }
  }
  let transform = match game_state.direction {
    Direction2::Left => @math.Transform::flip_x(32.0)
    Direction2::Right => @math.Transform::new()
  }
  match game_state.player_state {
    Idle => {
      if velocity.0[X] == 0.0 {
        @sprite.play_animation(
          game_state.player,
          player_idle_animation,
          transform~,
        )
      } else {
        @sprite.play_animation(
          game_state.player,
          player_run_animation,
          transform~,
        )
      }
      if velocity.0[Y] > 0.0 {
        game_state.player_state = PlayerState::Fall
      }
      if @inputs.is_just_pressed(ArrowUp) &&
        @collision.is_on_floor(game_state.player) {
        new_velocity_y = -JUMP_V
        game_state.player_state = PlayerState::Jump
        if game_state.volume_on {
          @audio.play_audio("sounds/jump.wav")
        }
      }
    }
    _ => {game_state.player_state = PlayerState::Idle}
  }
}
