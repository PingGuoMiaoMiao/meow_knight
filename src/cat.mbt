let cat_idle_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts1/Cats/cat_sprite_sheet.png",
    4,
    width=32,
    height=32,
  ),
  loop_=true,
  fps=8,
)

let cat_run_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts1/Cats/cat_sprite_sheet.png",
    8,
    width=32,
    height=32,
    offset=@math.Vec2D(0.0, 32.0)  // 第二行动画
  ),
  loop_=true,
  fps=12,
)


let cats : Map[@system.Entity, Cat] = Map::new()

///|
const CAT_SPEED = 12.0
const CAT_GRAVITY = 1800.0  // Cat 的重力加速度

enum CatState {
  Idle
  Run
  Sleep
}

struct Cat{
  health : Int
  speed : Double
  mut direction : Direction2
  mut is_hurt : Bool
  mut hurt_timer : Double
  mut state : CatState
  mut idle_timer : Double
}


fn add_cat(pos : @math.Vec2D) -> Unit{
  println("🐱 Creating cat entity at position: \{pos}")
  let entity = @system.Entity::new()
  let cat_sprite = @sprite.Sprite::from_animation(
    cat_idle_animation, 10,
  )
  @sprite.sprites.set(entity, cat_sprite)
  @velocity.velocities.set(entity, @math.Vec2D::zero())
  @position.positions.set(entity, pos)
  
  println("🐱 Cat entity components set")
  
  // Cat 需要碰撞体积来站在地面上，但不会阻挡玩家
  @collision.shapes.set(
    entity,
    Rect(size=@math.Vec2D(32.0, 32.0), offset=@math.Vec2D(0.0, 0.0)),
  )
  @collision.collision_layers.set(entity, cat_collision_layer)  // 使用独立的 cat 层
  @collision.colliders.set(
    entity,
    @collision.Collider::new(
      @collision.CollisionMask::new([terrain_collision_layer])  // 只与地形碰撞
    ),
  )
  
  // 添加交互区域用于与玩家交互
  let area = @collision.Area::new(
    @collision.CollisionMask::new([player_collision_layer])
  )
  @collision.areas.set(entity, area)
  
  cats[entity] = Cat::{
    health: 50,
    speed: CAT_SPEED,
    direction: Direction2::Right,
    is_hurt: false,
    hurt_timer: 0.0,
    state: CatState::Idle,
    idle_timer: 0.0,
  }
  
  println("🐱 Cat added successfully")
}


fn cat_ai_system(delta : Double) -> Unit{
  if cats.is_empty() {
    return  // 没有 cat 就直接返回
  }
  
  for e, cat in cats {
    guard e.is_alive() else { continue }
    
    // 应用重力
    guard @velocity.velocities.get(e) is Some(velocity) else { continue }
    
    // 获取 cat 位置
    guard @position.positions.get(e) is Some(cat_pos) else { continue }
    
    // 应用重力到 Y 轴速度
    let mut new_velocity_y = velocity.0[Y]
    new_velocity_y += CAT_GRAVITY * delta
    
    // 检测周围是否有其他角色（玩家）
    let mut has_nearby_entity = false
    let detection_range = 100.0  // 检测范围
    
    // 检测玩家
    match @position.positions.get(game_state.player) {
      Some(player_pos) => {
        let dx = cat_pos.0[X] - player_pos.0[X]
        let dy = cat_pos.0[Y] - player_pos.0[Y]
        let distance_squared = dx * dx + dy * dy
        if distance_squared < detection_range * detection_range {
          has_nearby_entity = true
        }
      }
      None => ()
    }
    
    // 如果有角色在附近，切换到 Run 状态
    if has_nearby_entity {
      cat.state = CatState::Run
      cat.idle_timer = 0.0  // 重置 idle 计时器
    } else {
      // 没有角色在附近，更新 idle 计时器
      cat.idle_timer += delta
      
      // 超过 3 秒，切换到 Sleep 状态
      if cat.idle_timer > 3.0 {
        cat.state = CatState::Sleep
      }
    }
    
    // 根据状态执行不同的行为
    match cat.state {
      CatState::Run => {
        // 左右走动
        let direction_multiplier = match cat.direction {
          Direction2::Left => -1.0
          Direction2::Right => 1.0
        }
        let mut velocity_x = cat.speed * direction_multiplier
        
        // 简单的转向逻辑：碰到边界转向
        if cat_pos.0[X] < 100.0 {
          cat.direction = Direction2::Right
        } else if cat_pos.0[X] > 200.0 {
          cat.direction = Direction2::Left
        }
        
        let new_direction_multiplier = match cat.direction {
          Direction2::Left => -1.0
          Direction2::Right => 1.0
        }
        velocity_x = cat.speed * new_direction_multiplier
        @velocity.velocities[e] = @math.Vec2D(velocity_x, new_velocity_y)
        
        // 播放奔跑动画，根据方向翻转
        let transform = match cat.direction {
          Direction2::Left => @math.Transform::flip_x(16.0)  // 使用cat中心点翻转
          Direction2::Right => @math.Transform::new()
        }
        @sprite.play_animation(
          e,
          cat_run_animation,
          transform=transform
        )
      }
      CatState::Idle => {
        // 静止，播放 idle 动画
        @velocity.velocities[e] = @math.Vec2D(0.0, new_velocity_y)
        @sprite.play_animation(
          e,
          cat_idle_animation,
          transform=@math.Transform::new()
        )
      }
      CatState::Sleep => {
        // 睡觉，播放 idle 动画
        @velocity.velocities[e] = @math.Vec2D(0.0, new_velocity_y)
        @sprite.play_animation(
          e,
          cat_idle_animation,
          transform=@math.Transform::new()
        )
      }
    }
  }
}