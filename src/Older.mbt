let older_idle_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts1/Older/IDLE.png",
    10,
    width=96,
     height=96,
  ),
  loop_=true,
  fps=12,
)

let older_attack_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts1/Older/ATTACK1.png",
    7,
    width=96,
    height=96,
  ),
  loop_=true,
  fps=12,
)

let older_run_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts1/Older/RUN.png",
    16,
    width=96,
    height=96,
  ),
  loop_=true,
  fps=12
) 

let older_hurt_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts1/Older/HURT.png",
    4,
    width=96,
    height=96,
  ),
  loop_=true,
  fps=12
)

///|
const Older_SPEED = 30.0
const Older_BLINK_COOLDOWN = 3.0  // 闪现冷却时间3秒
const Older_BLINK_RANGE = 200.0   // 闪现检测范围
const Older_ATTACK_DAMAGE = 1     // 攻击伤害
const Older_ATTACK_RANGE = 100.0  // 攻击范围
const Older_ATTACK_DURATION = 0.3 // 攻击持续时间（0.3秒内可以造成伤害）

struct Older {
  mut health : Int
  speed : Double
  mut direction : Direction2
  mut is_hurt : Bool
  mut hurt_timer : Double
  mut state : OlderState
  mut idle_timer : Double
  mut blink_timer : Double  // 闪现冷却计时器
  mut attack_timer : Double // 攻击计时器，用于判定攻击伤害的时机
  mut has_attacked : Bool   // 本次攻击是否已经造成伤害
  mut has_talked : Bool     // 是否已经对话，只有对话后才会攻击
}

enum OlderState {
  Idle
  Run
  Attack
  HURT
}

///|
let olders : Map[@system.Entity, Older] = Map::new()

fn add_Older(pos : @math.Vec2D) -> @system.Entity {
  let entity = @system.Entity::new()
  let older_sprite = @sprite.Sprite::from_animation(
    older_idle_animation, 10,
  )
  @sprite.sprites.set(entity, older_sprite)
  @velocity.velocities.set(entity, @math.Vec2D::zero()) // 初始速度为0，静止状态
  @position.positions.set(entity, pos)
  
  // Older 不需要碰撞体积，只保留主物理体积
  // 可以添加交互区域用于与玩家交互
  let area = @collision.Area::new(
    @collision.CollisionMask::new([player_collision_layer])
  )
  @collision.areas.set(entity, area)
  
  olders[entity] = Older::{
    health: 100,
    speed: Older_SPEED,
    direction: Direction2::Right,
    is_hurt: false,
    hurt_timer: 0.0,
    state: OlderState::Idle,
    idle_timer: 0.0,
    blink_timer: 0.0,  // 初始可以立即闪现
    attack_timer: 0.0,
    has_attacked: false,
    has_talked: false,  // 初始未对话
  }
  
  entity  // 返回创建的实体
}

fn older_ai_system(delta : Double) -> Unit{
  // 首先检查玩家攻击是否击中 Older
  if attack_state.is_attacking {
    let player_pos = @position.positions.get(game_state.player).unwrap_or(@math.Vec2D::zero())
    let attack_range = match attack_state.attack_type {
      1 => 120.0
      2 => 150.0
      _ => 120.0
    }
    
    for e, older in olders {
      guard e.is_alive() else { continue }
      guard older.hurt_timer <= 0.0 else { continue }  // 跳过无敌时间的Older
      
      let older_pos = @position.positions.get(e).unwrap_or(@math.Vec2D::zero())
      let dx = older_pos.0[X] - player_pos.0[X]
      let dy = older_pos.0[Y] - player_pos.0[Y]
      let distance_squared = dx * dx + dy * dy
      let max_distance_squared = attack_range * attack_range
      
      if distance_squared <= max_distance_squared {
        let is_correct_direction = match game_state.direction {
          Direction2::Right => dx > 0.0
          Direction2::Left => dx < 0.0
        }
        
        if is_correct_direction {
          let damage = match attack_state.attack_type {
            1 => 25
            2 => 40
            _ => 25
          }
          
          older.is_hurt = true
          older.hurt_timer = 0.5
          older.health -= damage
          older.state = OlderState::HURT
          println("👴 Older 受到攻击！伤害: \{damage}，剩余生命: \{older.health}")
          
          // Older 作为 Boss 不会被击退，只是停止移动并播放受击动画
          @velocity.velocities[e] = @math.Vec2D(0.0, 0.0)
        }
      }
    }
  }
  
  for e, older in olders {
    guard e.is_alive() else { continue }
    
    // Older 不需要重力，保持在固定位置
    guard @velocity.velocities.get(e) is Some(velocity) else { continue }
    
    // 获取 Older 位置
    guard @position.positions.get(e) is Some(older_pos) else { continue }
    
    // 更新受伤计时器
    if older.hurt_timer > 0.0 {
      older.hurt_timer -= delta
    }
    
    // 更新闪现冷却计时器
    if older.blink_timer > 0.0 {
      older.blink_timer -= delta
    }
    
    // 死亡状态
    if older.health <= 0 {
      @velocity.velocities[e] = @math.Vec2D::zero()
      @sprite.play_animation(
        e,
        older_idle_animation,
        transform=@math.Transform::new()
      )
      
      // 显示死亡对话
      show_dialogue("Older", "原来是这样吗...\n看来喵喵公主有救了", Some(older_idle_animation))
      
      // 从场景切换跟踪系统中移除
      older_entities.remove(e)
      println("💀 Older 已死亡，从场景切换跟踪系统中移除")
      
      e.destroy()
      olders.remove(e)
      continue
    }
    
    // 受伤状态
    if older.is_hurt && older.hurt_timer > 0.0 {
      older.state = OlderState::HURT
      // Older 作为 Boss，受伤时完全静止，不保留任何速度
      @velocity.velocities[e] = @math.Vec2D(0.0, 0.0)
      let transform = match older.direction {
        Direction2::Left => @math.Transform::flip_x(48.0)
        Direction2::Right => @math.Transform::new()
      }
      @sprite.play_animation(
        e,
        older_hurt_animation,
        transform=transform
      )
      continue
    } else if older.is_hurt && older.hurt_timer <= 0.0 {
      older.is_hurt = false
      older.state = OlderState::Idle
    }
    
    // 检测周围是否有玩家
    let mut has_nearby_player = false
    let mut player_distance_squared = 1000000.0
    let detection_range = 150.0  // 检测范围
    let attack_range = 80.0      // 攻击范围
    
    match @position.positions.get(game_state.player) {
      Some(player_pos) => {
        let dx = player_pos.0[X] - older_pos.0[X]
        let dy = player_pos.0[Y] - older_pos.0[Y]
        let distance_squared = dx * dx + dy * dy
        player_distance_squared = distance_squared
        
        if distance_squared < detection_range * detection_range {
          has_nearby_player = true
          
          // 如果还未对话，检测F键触发对话
          if not(older.has_talked) {
            if @inputs.is_just_pressed(@inputs.KeyF) && not(is_dialogue_showing()) {
              show_dialogue("Older", "哼！又一个不自量力的冒险者...\n让我来教训你！", Some(older_idle_animation))
              older.has_talked = true  // 标记已对话
              println("👴 Older 开始对话，现在会主动攻击！")
            }
          }
          
          // 根据玩家位置更新方向
          if dx < 0.0 {
            older.direction = Direction2::Left
          } else {
            older.direction = Direction2::Right
          }
        }
      }
      None => ()
    }
    
    // 闪现逻辑：只有对话后才会闪现
    if older.has_talked && has_nearby_player && older.blink_timer <= 0.0 && player_distance_squared < Older_BLINK_RANGE * Older_BLINK_RANGE {
      match @position.positions.get(game_state.player) {
        Some(player_pos) => {
          // 计算玩家背后的位置
          let blink_offset = 60.0  // 闪现到玩家背后60像素
          let blink_x = match game_state.direction {
            Direction2::Right => player_pos.0[X] - blink_offset  // 玩家面向右，闪现到左边
            Direction2::Left => player_pos.0[X] + blink_offset   // 玩家面向左，闪现到右边
          }
          let blink_y = player_pos.0[Y]  // 保持同样的Y坐标
          
          // 执行闪现
          @position.positions[e] = @math.Vec2D(blink_x, blink_y)
          older.blink_timer = Older_BLINK_COOLDOWN  // 重置冷却时间
          
          // 更新Older的朝向，面向玩家
          older.direction = match game_state.direction {
            Direction2::Right => Direction2::Right  // 玩家面向右，Older也面向右
            Direction2::Left => Direction2::Left    // 玩家面向左，Older也面向左
          }
          
          println("👴 Older 闪现到玩家背后！位置: (\{blink_x}, \{blink_y})")
        }
        None => ()
      }
    }
    
    // 攻击冷却递减（在所有状态下都执行）
    if older.attack_timer > 0.0 {
      older.attack_timer -= delta
    }
    
    // 根据状态执行不同的行为（只有对话后才会攻击）
    if older.has_talked && player_distance_squared < attack_range * attack_range {
      // 攻击状态
      older.state = OlderState::Attack
      @velocity.velocities[e] = @math.Vec2D(0.0, velocity.0[Y])
      
      // 检查是否可以攻击（冷却完毕 且 玩家没有无敌时间）
      if older.attack_timer <= 0.0 && game_state.hurt_timer <= 0.0 {
        match @position.positions.get(game_state.player) {
          Some(player_pos) => {
            // 计算攻击范围内是否包含玩家
            let dx = player_pos.0[X] - older_pos.0[X]
            let dy = player_pos.0[Y] - older_pos.0[Y]
            let distance_squared = dx * dx + dy * dy
            
            if distance_squared < Older_ATTACK_RANGE * Older_ATTACK_RANGE {
              // 检查攻击方向是否正确
              let is_correct_direction = match older.direction {
                Direction2::Right => dx > 0.0  // 玩家在Older右侧
                Direction2::Left => dx < 0.0   // 玩家在Older左侧
              }
              
              if is_correct_direction {
                // 击中玩家，调用hurt_player函数（会触发受击动画和音效）
                hurt_player()
                older.attack_timer = 2.5  // 设置2.5秒攻击冷却
              }
            }
          }
          None => ()
        }
      }
      
      let transform = match older.direction {
        Direction2::Left => @math.Transform::flip_x(48.0)
        Direction2::Right => @math.Transform::new()
      }
      @sprite.play_animation(
        e,
        older_attack_animation,
        transform=transform
      )
    } else if older.has_talked && has_nearby_player {
      // 奔跑状态 - 向玩家移动（只有对话后才会主动追击）
      older.state = OlderState::Run
      
      let direction_multiplier = match older.direction {
        Direction2::Left => -1.0
        Direction2::Right => 1.0
      }
      let velocity_x = older.speed * direction_multiplier
      @velocity.velocities[e] = @math.Vec2D(velocity_x, velocity.0[Y])
      
      let transform = match older.direction {
        Direction2::Left => @math.Transform::flip_x(48.0)
        Direction2::Right => @math.Transform::new()
      }
      @sprite.play_animation(
        e,
        older_run_animation,
        transform=transform
      )
    } else {
      // 空闲状态 - 原地待机或缓慢巡逻
      older.state = OlderState::Idle
      
      if not(older.has_talked) {
        // 未对话时，完全静止
        @velocity.velocities[e] = @math.Vec2D(0.0, velocity.0[Y])
      } else {
        // 对话后，左右巡逻
        older.idle_timer += delta
        
        // 每 2 秒改变一次方向
        if older.idle_timer > 2.0 {
          older.idle_timer = 0.0
          older.direction = match older.direction {
            Direction2::Left => Direction2::Right
            Direction2::Right => Direction2::Left
          }
        }
        
        // 慢速移动
        let direction_multiplier = match older.direction {
          Direction2::Left => -1.0
          Direction2::Right => 1.0
        }
        let velocity_x = older.speed * 0.5 * direction_multiplier  // 巡逻速度是奔跑速度的一半
        @velocity.velocities[e] = @math.Vec2D(velocity_x, velocity.0[Y])
      }
      
      let transform = match older.direction {
        Direction2::Left => @math.Transform::flip_x(48.0)
        Direction2::Right => @math.Transform::new()
      }
      @sprite.play_animation(
        e,
        older_idle_animation,  // 使用 idle 动画而不是 run 动画
        transform=transform
      )
    }
  }
}