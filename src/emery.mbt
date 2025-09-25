///|
let skeleton_idle_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts/Monsters_Creatures_Fantasy/Skeleton/Idle.png",
    4,
    width=105,
    height=210,
  ),
  loop_=true,
  fps=12,
)

///|
let skeleton_walk_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts/Monsters_Creatures_Fantasy/Skeleton/Walk.png",
    4,
    width=105,
    height=210,
  ),
  loop_=true,
  fps=12,
)

///|
let skeleton_death_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts/Monsters_Creatures_Fantasy/Skeleton/Death.png",
    4,
    width=105,
    height=210,
  ),
  loop_=false,
  fps=1,
)

///|
let skeleton_attack_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts/Monsters_Creatures_Fantasy/Skeleton/Attack.png",
    8,
    width=105,
    height=210,
  ),
  loop_=false,
  fps=12,
)

///|
let skeleton_shield_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts/Monsters_Creatures_Fantasy/Skeleton/Shield.png",
    4,
    width=105,
    height=210,
  ),
  loop_=false,
  fps=12,
)

///|
let skeleton_take_hit_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts/Monsters_Creatures_Fantasy/Skeleton/TakeHit.png",
    4,
    width=105,
    height=210,
  ),
  loop_=false,
  fps=1,
)

///|
const SKELETON_SPEED = 10.0

///|
struct Skeleton {
  mut health : Int
  speed : Double
  mut direction : Direction2
  mut is_hurt : Bool
  mut hurt_timer : Double
  mut state : SkeletonState
  mut idle_timer : Double
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
  @velocity.velocities.set(entity, @math.Vec2D::zero()) // 初始速度为0，静止状态
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
    hurt_timer: 0.0,
    state: SkeletonState::Idle,
    idle_timer: 0.0,
  }
}


/// 静态骷髅AI - 怪物不移动，只处理受伤和死亡
///|
fn skeleton_ai_system(_delta : Double) -> Unit {
  for e, skeleton in skeletons {
    guard e.is_alive() else { continue }
    
    // 更新受伤计时器
    if skeleton.hurt_timer > 0.0 {
      skeleton.hurt_timer -= 1.0
    }
    
    // 死亡状态
    if skeleton.health <= 0 {
      skeleton.state = SkeletonState::Death
      @velocity.velocities[e] = @math.Vec2D::zero()
      @collision.collision_layers.remove(e)
      @sprite.play_animation(
        e,
        skeleton_death_animation,
        transform=@math.Transform::new()
      )
      if @sprite.is_animation_finished(e) {
        e.destroy()
        skeletons.remove(e)
      }
      continue
    }
    
    // 受伤状态
    if skeleton.is_hurt && skeleton.hurt_timer > 0.0 {
      skeleton.state = SkeletonState::TakeHit
      @velocity.velocities[e] = @math.Vec2D::zero()
      @sprite.play_animation(
        e,
        skeleton_take_hit_animation,
        transform=@math.Transform::new()
      )
      continue
    } else if skeleton.is_hurt && skeleton.hurt_timer <= 0.0 {
      // 受伤状态结束，回到待机
      skeleton.is_hurt = false
      skeleton.state = SkeletonState::Idle
    }
    
    // 默认状态：静止播放待机动画
    @velocity.velocities[e] = @math.Vec2D::zero()
    @sprite.play_animation(
      e,
      skeleton_idle_animation,
      transform=@math.Transform::new()
    )
  }
}
