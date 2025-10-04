let silme_idle_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts1/FreeSlime/slime_idle.png",
    4,
    width=32,
    height=32,
  ),
  loop_=true,
  fps=12,
)

let silme_run_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts1/FreeSlime/slime_run.png",
    6,
    width=32,
    height=32
  ),
  loop_=true,
  fps=12,
)

let silme_die_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts1/FreeSlime/slime_die.png",
    5,
    width=32,
    height=32
  ),
  loop_=false,
  fps=12,
)


let silmes : Map[@system.Entity, Silme] = Map::new()

///|
const Silme_SPEED = 50.0

enum SilmeState {
  Idle
  Run
  Die
}

struct Silme{
  mut health : Int
  speed : Double
  mut direction : Direction2
  mut is_hurt : Bool
  mut hurt_timer : Double
  mut state : SilmeState
  mut idle_timer : Double
  mut rotation : Double  // 旋转角度（弧度）
}


fn add_silme(pos : @math.Vec2D) -> Unit{
  let entity = @system.Entity::new()
  let silme_sprite = @sprite.Sprite::from_animation(
    silme_idle_animation, 10,
  )
  @sprite.sprites.set(entity, silme_sprite)
  @velocity.velocities.set(entity, @math.Vec2D::zero()) // 初始速度为0，静止状态
  @position.positions.set(entity, pos)
  // 添加碰撞体积，使 slime 能与地形发生碰撞
  // 主物理体积与 slime 图片完全一致
  @collision.shapes.set(
    entity,
    Rect(size=@math.Vec2D(24.0, 24.0), offset=@math.Vec2D(0.0, 0.0)),
  )
  @collision.collision_layers.set(entity, enemy_collision_layer)  // 使用敌人碰撞层，而不是地形层
  @collision.colliders.set(
    entity,
    @collision.Collider::new(
      @collision.CollisionMask::new([
        terrain_collision_layer,  // slime 与地形碰撞，能站在地上
        player_collision_layer,   // slime 也能检测到与玩家的碰撞
      ]),
    ),
  )
  silmes[entity] = Silme::{
    health: 100,
    speed: Older_SPEED,
    direction: Direction2::Left,
    is_hurt: false,
    hurt_timer: 0.0,
    state: SilmeState::Idle,
    idle_timer: 0.0,
    rotation: 0.0,
  }
}


fn silme_ai_system(delta : Double) -> Unit{
  for e, silme in silmes {
    guard e.is_alive() else { continue }
    
    // 添加重力系统
    guard @velocity.velocities.get(e) is Some(velocity) else { 
      println("⚠️ Slime 没有速度组件！")
      continue 
    }
    
    // 获取位置信息用于调试
    let pos = @position.positions.get(e).unwrap_or(@math.Vec2D::zero())
    let is_on_floor = @collision.is_on_floor(e)
    
    let mut new_velocity_y = velocity.0[Y]
    new_velocity_y += 1800.0 * delta  // 使用和 player 相同的重力常数
    
    // 打印调试信息
    if silme.idle_timer.to_int() % 60 == 0 {  // 每秒打印一次
      println("🎮 Slime状态: 位置(" + pos.0[X].to_string() + "," + pos.0[Y].to_string() + ") " +
              "速度(" + velocity.0[X].to_string() + "," + velocity.0[Y].to_string() + ") " +
              "在地面: " + is_on_floor.to_string())
    }
    
    // 更新受伤计时器
    if silme.hurt_timer > 0.0 {
      silme.hurt_timer -= 1.0
    }
    
    // 死亡状态
    if silme.health <= 0 {
      silme.state = SilmeState::Die
      @velocity.velocities[e] = @math.Vec2D::zero()
      @collision.collision_layers.remove(e)
      @sprite.play_animation(
        e,
        silme_die_animation,
        transform=@math.Transform::new()
      )
      if @sprite.is_animation_finished(e) {
        // 死亡动画结束，显示对话
        show_slime_death_dialogue()
        
        // 掉落2个金币
        let drop_pos = @position.positions.get(e).unwrap_or(@math.Vec2D::zero())
        add_coin(@math.Vec2D(drop_pos.0[X] - 10.0, drop_pos.0[Y] - 8.0))
        add_coin(@math.Vec2D(drop_pos.0[X] + 10.0, drop_pos.0[Y] - 8.0))
        
        e.destroy()
        silmes.remove(e)
      }
      continue
    }
    
    // 受伤状态 - 保持击退效果，添加多圈旋转动画
    if silme.is_hurt && silme.hurt_timer > 0.0 {
      silme.state = SilmeState::Idle
      // 不重置速度，让击退效果自然衰减
      // 只应用重力
      @velocity.velocities[e] = @math.Vec2D(velocity.0[X], new_velocity_y)
      
      // 计算旋转进度：从60.0递减到0，用来计算旋转角度
      // 让slime在60帧内转3圈，即每帧转18度
      let rotation_progress = (60.0 - silme.hurt_timer) / 60.0  // 0.0 到 1.0
      silme.rotation = rotation_progress * 18.84954  // 18.84954 = 3 × 2π (转3圈)
      
      // 根据旋转角度决定翻转状态
      // 当旋转角度的余数在90-270度之间时翻转
      let rotation_degrees = (silme.rotation * 57.2958) % 360.0  // 转换为角度并取余数
      let should_flip = rotation_degrees > 90.0 && rotation_degrees < 270.0
      
      // 添加闪烁效果：每隔几帧切换一次可见性（模拟受伤闪烁）
      let blink_phase = (silme.hurt_timer.to_int() / 5) % 2
      let is_visible = blink_phase == 0
      
      if is_visible {
        let rotate_transform = if should_flip {
          @math.Transform::flip_x(16.0)  // 使用slime中心点翻转
        } else {
          @math.Transform::new()
        }
        
        @sprite.play_animation(
          e,
          silme_idle_animation,
          transform=rotate_transform
        )
      }
      continue
    } else if silme.is_hurt && silme.hurt_timer <= 0.0 {
      // 受伤状态结束，回到待机，重置旋转
      silme.is_hurt = false
      silme.state = SilmeState::Idle
      silme.rotation = 0.0  // 重置旋转角度
    }
    
    // 移动逻辑：左右来回走动
    silme.idle_timer += delta
    
    let mut new_velocity_x = 0.0
    if silme.idle_timer > 2.0 {  // 每2秒改变方向
      silme.direction = match silme.direction {
        Direction2::Left => Direction2::Right
        Direction2::Right => Direction2::Left
      }
      silme.idle_timer = 0.0
      let direction_str = match silme.direction {
        Direction2::Left => "Left"
        Direction2::Right => "Right"
      }
      println("🔄 Slime 改变方向: " + direction_str)
    }
    
    // 根据方向设置速度
    match silme.direction {
      Direction2::Left => {
        new_velocity_x = -Silme_SPEED
        silme.state = SilmeState::Run
      }
      Direction2::Right => {
        new_velocity_x = Silme_SPEED
        silme.state = SilmeState::Run
      }
    }
    
    // 设置速度
    @velocity.velocities[e] = @math.Vec2D(new_velocity_x, new_velocity_y)
    
    // 播放对应动画
    let transform = match silme.direction {
      Direction2::Left => @math.Transform::flip_x(32.0)
      Direction2::Right => @math.Transform::new()
    }
    
    match silme.state {
      SilmeState::Run => {
        @sprite.play_animation(e, silme_run_animation, transform=transform)
      }
      _ => {
        @sprite.play_animation(e, silme_idle_animation, transform=transform)
      }
    }
  }
}