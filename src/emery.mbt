///|
let skeleton_idle_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts/Skeleton/Idle.png",
    4,
    width=120,
    height=150,
  ),
  loop_=true,
  fps=12,
)

///|
let skeleton_walk_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts/Skeleton/Walk.png",
    4,
    width=120,
    height=150,
  ),
  loop_=true,
  fps=12,
)

///|
let skeleton_death_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts/Skeleton/Death.png",
    4,
    width=120,
    height=150,
  ),
  loop_=false,
  fps=12,
)

///|
let skeleton_attack_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts/Skeleton/Attack.png",
    8,
    width=120,
    height=150,
  ),
  loop_=false,
  fps=12,
)

///|
let skeleton_shield_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts/Skeleton/Shield.png",
    4,
    width=120,
    height=150,
  ),
  loop_=false,
  fps=12,
)

///|
let skeleton_take_hit_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts/Skeleton/Take Hit.png",
    4,
    width=120,
    height=150,
  ),
  loop_=false,
  fps=12,
)

///|
const SKELETON_SPEED = 0.0

///|
struct Skeleton {
  mut health : Int
  speed : Double
  mut direction : Direction2
  mut is_hurt : Bool
  mut hurt_timer : Double
}

///|
let skeletons : Map[@system.Entity, Skeleton] = Map::new()

///|
enum SkeletonState {
  Idle
  Walk
  Attack
  Shield
  TakeHit
  Death
}

///|
fn add_enemy(pos : @math.Vec2D) -> Unit {
  let entity = @system.Entity::new()
  let skeleton_sprite = @sprite.Sprite::from_animation(
    skeleton_idle_animation, 10,
  )
  @sprite.sprites.set(entity, skeleton_sprite)
  @velocity.velocities.set(entity, @math.Vec2D(SKELETON_SPEED, 0.0))
  @position.positions.set(entity, pos)
  @collision.shapes.set(
    entity,
    Rect(size=@math.Vec2D(120.0, 80.0), offset=@math.Vec2D(70.0, -5.0)),
  )
  @collision.collision_layers.set(entity, enemy_collision_layer)
  @collision.colliders.set(
    entity,
    @collision.Collider::new(
      @collision.CollisionMask::new([terrain_collision_layer]),
    ),
  )
  skeletons[entity] = Skeleton::{
    health: 100,
    speed: SKELETON_SPEED,
    direction: Direction2::Left,
    is_hurt: false,
    hurt_timer: 0.0,
  }
}

///|
fn hurt_enemy_on_player_attack() -> Unit {
  // 玩家攻击时，敌人在受击范围内则受伤
  let is_player_attacking = game_state.player_state is PlayerState::Attack
  if !is_player_attacking {
    return
  }
  let player_pos = @position.positions.get(game_state.player).unwrap_or(@math.Vec2D::zero())
  for e, skeleton in skeletons {
    guard e.is_alive() else { continue }
    let enemy_pos = @position.positions.get(e).unwrap_or(@math.Vec2D::zero())
    let hurt_range = 80.0
    let dx = (player_pos.0[X] - enemy_pos.0[X]).abs()
    let dy = (player_pos.0[Y] - enemy_pos.0[Y]).abs()
    if dx < hurt_range && dy < 60.0 {
      if !skeleton.is_hurt {
        skeleton.health -= 50
        skeleton.is_hurt = true
        skeleton.hurt_timer = 30.0
        if skeleton.health <= 0 {
          skeleton.health = 0
        }
        // 播放受击动画
        match skeleton.direction {
          Left =>
            @sprite.play_animation(
              e,
              skeleton_take_hit_animation,
              transform=@math.Transform::new(),
            )
          Right =>
            @sprite.play_animation(
              e,
              skeleton_take_hit_animation,
              transform=@math.Transform::flip_x(32.0),
            )
        }
      }
    }
  }
}

///|
fn enemy_collision_system(_delta : Double) -> Unit {
  // 处理敌人碰撞地面
  for e, skeleton in skeletons {
    guard e.is_alive() else { continue }
    let collision_infos = @collision.get_collision_infos(e)
    for info in collision_infos {
      if info.direction[Y] < 0.0 {
        // 敌人碰到地面
        @velocity.velocities[e] = @velocity.velocities[e].0.update(Y, 0.0)
      }
    }
    // 处理敌人受伤计时
    if skeleton.is_hurt {
      skeleton.hurt_timer -= 1.0
      if skeleton.hurt_timer <= 0.0 {
        skeleton.is_hurt = false
        skeleton.hurt_timer = 0.0
      }
    }
  }
}

///|
fn skeleton_ai_system(_ : Double) -> Unit {
  for e, skeleton in skeletons {
    guard e.is_alive() else { continue }
    guard @velocity.velocities.get(e) is Some(_velocity)
    if @sprite.is_animation_finished(e) {
      e.destroy()
      continue
    }
    if skeleton.is_hurt {
      @velocity.velocities[e] = @math.Vec2D::zero()
      if skeleton.health == 0 {
        @collision.collision_layers.remove(e)
        match skeleton.direction {
          Left =>
            @sprite.play_animation(
              e,
              skeleton_death_animation,
              transform=@math.Transform::new(),
            )
          Right =>
            @sprite.play_animation(
              e,
              skeleton_death_animation,
              transform=@math.Transform::flip_x(32.0),
            )
        }
      } else {
        match skeleton.direction {
          Left =>
            @sprite.play_animation(
              e,
              skeleton_take_hit_animation,
              transform=@math.Transform::new(),
            )
          Right =>
            @sprite.play_animation(
              e,
              skeleton_take_hit_animation,
              transform=@math.Transform::flip_x(32.0),
            )
        }
      }
      continue
    }
    let collision_infos = @collision.get_collision_infos(e)
    let hit_wall = collision_infos
      .iter()
      .any(fn(info) {
        (info.direction[X] > 0.0 && skeleton.direction is Right) ||
        (info.direction[X] < 0.0 && skeleton.direction is Left)
      })
    if hit_wall {
      skeleton.direction = match skeleton.direction {
        Left => Right
        Right => Left
      }
    }
    match skeleton.direction {
      Left => {
        @velocity.velocities[e] = @math.Vec2D(-SKELETON_SPEED, 0.0)
        @sprite.play_animation(
          e,
          skeleton_idle_animation,
          transform=@math.Transform::new(),
        )
      }
      Right => {
        @velocity.velocities[e] = @math.Vec2D(SKELETON_SPEED, 0.0)
        @sprite.play_animation(
          e,
          skeleton_take_hit_animation,
          transform=@math.Transform::flip_x(32.0),
        )
      }
    }
  }
}
