// Cat 的10个动画状态
let cat_idle_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts1/Cats/cat_sprite_sheet.png",
    4,  // 第一个动画：idle
    width=32,
    height=32,
    offset=@math.Vec2D(0.0, 0.0)  // 第一行
  ),
  loop_=true,
  fps=8,
)

let cat_walk_right_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts1/Cats/cat_sprite_sheet.png",
    4,  // 第二个动画：向右走
    width=32,
    height=32,
    offset=@math.Vec2D(0.0, 32.0)  // 第二行
  ),
  loop_=true,
  fps=12,
)

let cat_angry_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts1/Cats/cat_sprite_sheet.png",
    4,  // 第三个动画：生气
    width=32,
    height=32,
    offset=@math.Vec2D(0.0, 64.0)  // 第三行
  ),
  loop_=true,
  fps=10,
)

let cat_wipe_eyes_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts1/Cats/cat_sprite_sheet.png",
    4,  // 第四个动画：抹眼睛
    width=32,
    height=32,
    offset=@math.Vec2D(0.0, 96.0)  // 第四行
  ),
  loop_=true,
  fps=6,
)

let cat_happy_jump_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts1/Cats/cat_sprite_sheet.png",
    8,  // 第五个动画：开心的跳
    width=32,
    height=32,
    offset=@math.Vec2D(0.0, 128.0)  // 第五行
  ),
  loop_=true,
  fps=14,
)

let cat_run_jump_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts1/Cats/cat_sprite_sheet.png",
    8,  // 第六个动画：跑着跳
    width=32,
    height=32,
    offset=@math.Vec2D(0.0, 160.0)  // 第六行
  ),
  loop_=true,
  fps=16,
)

let cat_sleep_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts1/Cats/cat_sprite_sheet.png",
    4,  // 第七个动画：sleep
    width=32,
    height=32,
    offset=@math.Vec2D(0.0, 192.0)  // 第七行
  ),
  loop_=true,
  fps=4,
)

let cat_happy_walk_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts1/Cats/cat_sprite_sheet.png",
    6,  // 第八个动画：开心的走
    width=32,
    height=32,
    offset=@math.Vec2D(0.0, 224.0)  // 第八行
  ),
  loop_=true,
  fps=10,
)

let cat_pounce_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts1/Cats/cat_sprite_sheet.png",
    7,  // 第九个动画：扑向你的跳
    width=32,
    height=32,
    offset=@math.Vec2D(0.0, 256.0)  // 第九行
  ),
  loop_=false,  // 扑跳动画不循环
  fps=18,
)

let cat_fluffy_angry_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts1/Cats/cat_sprite_sheet.png",
    8,  // 第十个动画：炸毛
    width=32,
    height=32,
    offset=@math.Vec2D(0.0, 288.0)  // 第十行
  ),
  loop_=true,
  fps=12,
)


let cats : Map[@system.Entity, Cat] = Map::new()

///|
const CAT_SPEED = 12.0
const CAT_GRAVITY = 1800.0  // Cat 的重力加速度

enum CatState {
  Idle          // 待机
  WalkRight     // 向右走
  Angry         // 生气
  WipeEyes      // 抹眼睛
  HappyJump     // 开心的跳
  RunJump       // 跑着跳
  Sleep         // 睡觉
  HappyWalk     // 开心的走
  Pounce        // 扑向玩家
  FluffyAngry   // 炸毛
}

struct Cat{
  health : Int
  speed : Double
  mut direction : Direction2
  mut is_hurt : Bool
  mut hurt_timer : Double
  mut state : CatState
  mut idle_timer : Double
  mut state_timer : Double    // 状态持续时间
  mut mood : Int             // 心情值：0-100，影响行为
  mut interaction_count : Int // 与玩家交互次数
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
    state_timer: 0.0,
    mood: 75,  // 初始心情良好
    interaction_count: 0,
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
    
    // 更新状态计时器
    cat.state_timer += delta
    cat.idle_timer += delta
    
    // 检测玩家距离
    let mut player_distance = 1000.0  // 默认很远
    let mut player_pos_opt : Option[@math.Vec2D] = None
    
    match @position.positions.get(game_state.player) {
      Some(player_pos) => {
        player_pos_opt = Some(player_pos.0)
        let dx = cat_pos.0[X] - player_pos.0[X]
        let dy = cat_pos.0[Y] - player_pos.0[Y]
        player_distance = dx * dx + dy * dy  // 距离的平方
      }
      None => ()
    }
    
    // Cat 状态机：根据距离、心情和时间决定行为
    let close_distance = 80.0 * 80.0     // 近距离
    let medium_distance = 150.0 * 150.0  // 中距离
    
    // 状态转换逻辑
    match cat.state {
      CatState::Idle => {
        if player_distance < close_distance {
          // 玩家靠近，根据心情决定反应
          if cat.mood > 60 {
            cat.state = CatState::HappyWalk
            cat.interaction_count += 1
          } else if cat.mood < 30 {
            cat.state = CatState::FluffyAngry
          } else {
            cat.state = CatState::WalkRight
          }
          cat.state_timer = 0.0
        } else if cat.idle_timer > 5.0 {
          cat.state = CatState::Sleep
          cat.state_timer = 0.0
        } else if cat.state_timer > 3.0 {
          // 随机选择一个动作
          let random_action = (cat.state_timer * 17.0).to_int() % 4
          match random_action {
            0 => cat.state = CatState::WipeEyes
            1 => cat.state = CatState::HappyJump
            2 => cat.state = CatState::Angry
            _ => cat.state = CatState::WalkRight
          }
          cat.state_timer = 0.0
        }
      }
      
      CatState::WalkRight => {
        if cat.state_timer > 2.0 {
          cat.state = CatState::Idle
          cat.state_timer = 0.0
        }
      }
      
      CatState::HappyWalk => {
        if player_distance > medium_distance {
          cat.state = CatState::Idle
          cat.state_timer = 0.0
        } else if cat.state_timer > 1.5 && player_distance < close_distance {
          cat.state = CatState::Pounce  // 扑向玩家
          cat.state_timer = 0.0
        }
      }
      
      CatState::Pounce => {
        if cat.state_timer > 1.0 {  // 扑跳动画完成
          cat.state = CatState::HappyJump
          cat.mood += 10  // 心情变好
          cat.state_timer = 0.0
        }
      }
      
      CatState::FluffyAngry => {
        if cat.state_timer > 2.0 {
          if player_distance > medium_distance {
            cat.state = CatState::Idle
            cat.mood += 5  // 玩家离开后情绪好转
          } else {
            cat.state = CatState::Angry
          }
          cat.state_timer = 0.0
        }
      }
      
      CatState::Sleep => {
        cat.idle_timer = 0.0  // 重置idle计时器
        if player_distance < close_distance {
          cat.state = CatState::WipeEyes  // 被唤醒，揉眼睛
          cat.state_timer = 0.0
        }
      }
      
      _ => {
        // 其他状态在一定时间后回到Idle
        if cat.state_timer > 2.0 {
          cat.state = CatState::Idle
          cat.state_timer = 0.0
        }
      }
    }
    
    // 根据状态执行动画和移动
    match cat.state {
      CatState::Idle => {
        @velocity.velocities[e] = @math.Vec2D(0.0, new_velocity_y)
        @sprite.play_animation(e, cat_idle_animation, transform=@math.Transform::new())
      }
      
      CatState::WalkRight => {
        let velocity_x = cat.speed * 0.5  // 慢慢走
        @velocity.velocities[e] = @math.Vec2D(velocity_x, new_velocity_y)
        @sprite.play_animation(e, cat_walk_right_animation, transform=@math.Transform::new())
      }
      
      CatState::HappyWalk => {
        let velocity_x = cat.speed * 0.7  // 开心地走快一点
        @velocity.velocities[e] = @math.Vec2D(velocity_x, new_velocity_y)
        @sprite.play_animation(e, cat_happy_walk_animation, transform=@math.Transform::new())
      }
      
      CatState::Pounce => {
        // 扑向玩家
        match player_pos_opt {
          Some(player_pos) => {
            let dx = player_pos[X] - cat_pos.0[X]
            let pounce_speed = if dx > 0.0 { cat.speed * 1.5 } else { -cat.speed * 1.5 }
            @velocity.velocities[e] = @math.Vec2D(pounce_speed, new_velocity_y - 200.0)  // 跳起来
          }
          None => @velocity.velocities[e] = @math.Vec2D(0.0, new_velocity_y)
        }
        @sprite.play_animation(e, cat_pounce_animation, transform=@math.Transform::new())
      }
      
      CatState::HappyJump => {
        @velocity.velocities[e] = @math.Vec2D(0.0, new_velocity_y)
        @sprite.play_animation(e, cat_happy_jump_animation, transform=@math.Transform::new())
      }
      
      CatState::RunJump => {
        let velocity_x = cat.speed * 1.2  // 跑跳
        @velocity.velocities[e] = @math.Vec2D(velocity_x, new_velocity_y)
        @sprite.play_animation(e, cat_run_jump_animation, transform=@math.Transform::new())
      }
      
      CatState::Sleep => {
        @velocity.velocities[e] = @math.Vec2D(0.0, new_velocity_y)
        @sprite.play_animation(e, cat_sleep_animation, transform=@math.Transform::new())
      }
      
      CatState::Angry => {
        @velocity.velocities[e] = @math.Vec2D(0.0, new_velocity_y)
        @sprite.play_animation(e, cat_angry_animation, transform=@math.Transform::new())
      }
      
      CatState::FluffyAngry => {
        @velocity.velocities[e] = @math.Vec2D(0.0, new_velocity_y)
        @sprite.play_animation(e, cat_fluffy_angry_animation, transform=@math.Transform::new())
      }
      
      CatState::WipeEyes => {
        @velocity.velocities[e] = @math.Vec2D(0.0, new_velocity_y)
        @sprite.play_animation(e, cat_wipe_eyes_animation, transform=@math.Transform::new())
      }
    }
    
    // 心情自然恢复
    if cat.state_timer > 10.0 {
      if cat.mood < 50 {
        cat.mood += 1
      }
    }
  }
}