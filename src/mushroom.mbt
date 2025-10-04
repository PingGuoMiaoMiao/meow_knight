let mushroom_idle_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts1/Mushroom/Idle.png",
    4,
    width=32,
    height=32,
  ),
  loop_=true,
  fps=12,
)

let mushroom_run_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts1/Mushroom/Run.png",
    8,
    width=32,
    height=32
  ),
  loop_=true,
  fps=12,
)

let mushroom_attack_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts1/Mushroom/Attack.png",
    8,
    width=32,
    height=32
  ),
  loop_=true,
  fps=12,
)

let mushroom_death_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts1/Mushroom/Death.png",
    4,
    width=32,
    height=32
  ),
  loop_=true,
  fps=12,
)

let mushroom_takehit_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts1/Mushroom/Take Hit.png",
    4,
    width=32,
    height=32
  ),
  loop_=true,
  fps=12,
)


let mushrooms : Map[@system.Entity, Mushroom] = Map::new()

///|
const MUSHROOM_SPEED = 8.0

enum MushroomState {
  Idle
  Run
  Attack
  Death
  TakeHit
}

struct Mushroom{
   health : Int
  speed : Double
  mut direction : Direction2
  mut is_hurt : Bool
  mut hurt_timer : Double
  mut state : MushroomState
  mut idle_timer : Double
}


fn add_mushroom(pos : @math.Vec2D) -> Unit{
  let entity = @system.Entity::new()
  let mushroom_sprite = @sprite.Sprite::from_animation(
    mushroom_idle_animation, 10,
  )
  @sprite.sprites.set(entity, mushroom_sprite)
  @velocity.velocities.set(entity, @math.Vec2D::zero()) // 初始速度为0，静止状态
  @position.positions.set(entity, pos)
  
  // Mushroom 不需要碰撞体积，只保留主物理体积
  // 可以添加交互区域用于与玩家交互
  let area = @collision.Area::new(
    @collision.CollisionMask::new([player_collision_layer])
  )
  @collision.areas.set(entity, area)
  
  mushrooms[entity] = Mushroom::{
    health: 80,
    speed: MUSHROOM_SPEED,
    direction: Direction2::Left,
    is_hurt: false,
    hurt_timer: 0.0,
    state: MushroomState::Idle,
    idle_timer: 0.0,
  }
}


fn mushroom_ai_system(delta : Double) -> Unit{
  for e, mushroom in mushrooms {
    guard e.is_alive() else { continue }
    
    // Mushroom 不需要重力，保持在固定位置
    guard @velocity.velocities.get(e) is Some(velocity) else { continue }
    
    // 更新受伤计时器
    if mushroom.hurt_timer > 0.0 {
      mushroom.hurt_timer -= 1.0
    }
    
    // 死亡状态
    if mushroom.health <= 0 {
      mushroom.state = MushroomState::Death
      @velocity.velocities[e] = @math.Vec2D::zero()
      @collision.collision_layers.remove(e)
      @sprite.play_animation(
        e,
        mushroom_death_animation,
        transform=@math.Transform::new()
      )
      if @sprite.is_animation_finished(e) {
        e.destroy()
        mushrooms.remove(e)
      }
      continue
    }
    
    // 受伤状态
    if mushroom.is_hurt && mushroom.hurt_timer > 0.0 {
      mushroom.state = MushroomState::TakeHit
      @velocity.velocities[e] = @math.Vec2D::zero()
      @sprite.play_animation(
        e,
        mushroom_takehit_animation,
        transform=@math.Transform::new()
      )
      continue
    } else if mushroom.is_hurt && mushroom.hurt_timer <= 0.0 {
      // 受伤状态结束，回到待机
      mushroom.is_hurt = false
      mushroom.state = MushroomState::Idle
    }
    
    // 默认状态：静止播放待机动画
    @velocity.velocities[e] = @math.Vec2D::zero()
    @sprite.play_animation(
      e,
      mushroom_idle_animation,
      transform=@math.Transform::new()
    )
  }
}