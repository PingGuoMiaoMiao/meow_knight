///|
let skeleton_idle_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts/Skeleton/Idle.png",
    4,
    width=120,
    height=150,
  ),
  loop_=false,
  fps=4,
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
  fps=4,
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
  fps=4,
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
  fps=4,
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
  fps=4,
)

///|
let skeleton_take_hit_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts/Skeleton/TakeHit.png",
    4,
    width=120,
    height=150,
  ),
  loop_=false,
  fps=4,
)

///|
const SKELETON_SPEED = 10.0

///|
struct Skeleton {
  health : Int
  speed : Double
  mut direction : Direction2
  mut is_hurt : Bool
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
    skeleton_walk_animation, 10,
  )
  @sprite.sprites.set(entity, skeleton_sprite)
  @velocity.velocities.set(entity, @math.Vec2D(SKELETON_SPEED, 0.0))
  @position.positions.set(entity, pos)
  @collision.shapes.set(
    entity,
    Rect(size=@math.Vec2D(120.0, 80.0), offset=@math.Vec2D(70.0, 0.0)),
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
      }
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
          skeleton_walk_animation,
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
