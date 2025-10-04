struct SpriteInfo {
  mut health : Int
  mut direction : Direction2
  dialog : String
  mut idle_timer : Double  // 用于控制方向切换
  mut is_near_player : Bool  // 是否靠近玩家
}
let sprites_idle_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts1/Fairy/Fairy1.png",
    8,
    width=32,
    height=32,
  ),
  loop_=true,
  fps=12,
)


// ...existing code...


fn add_sprite(pos : @math.Vec2D, dialog: String) -> Unit {
  let entity = @system.Entity::new()
  let sprite = @sprite.Sprite::from_animation(sprites_idle_animation, 10)
  @sprite.sprites.set(entity, sprite)
  @velocity.velocities.set(entity, @math.Vec2D::zero())
  @position.positions.set(entity, pos)
  
  // Sprite 是飞行的精灵，不需要碰撞体积，只需要交互区域
  // 保留交互区域 - Sprites 可以与玩家交互
  let area = @collision.Area::new(
    @collision.CollisionMask::new([player_collision_layer])
  )
  @collision.areas.set(entity, area)
  
  sprites.set(entity, SpriteInfo::{
    health: 3,
    direction: Direction2::Left,
    dialog: dialog,
    idle_timer: 0.0,
    is_near_player: false,
  })
}

let sprites: Map[@system.Entity, SpriteInfo] = Map::new()

fn sprite_ai_system(delta : Double) -> Unit {
  for e, sprite_info in sprites {
    guard e.is_alive() else { continue }
    
    // 获取 sprite 的位置
    guard @position.positions.get(e) is Some(sprite_pos) else { continue }
    
    // 检测玩家是否在附近（100像素范围内）
    let detection_range = 100.0
    let mut is_near_player = false
    
    match @position.positions.get(game_state.player) {
      Some(player_pos) => {
        let dx = player_pos.0[X] - sprite_pos.0[X]
        let dy = player_pos.0[Y] - sprite_pos.0[Y]
        let distance_squared = dx * dx + dy * dy
        
        if distance_squared < detection_range * detection_range {
          is_near_player = true
          
          // 如果玩家靠近并按下F键，显示对话
          if @inputs.is_just_pressed(@inputs.KeyF) && not(is_dialogue_showing()) {
            show_dialogue("精灵", "你好，勇敢的冒险者！\n我在这里守护着古老的秘密...", Some(sprites_idle_animation))
          }
        }
      }
      None => ()
    }
    
    sprite_info.is_near_player = is_near_player
    
    if is_near_player {
      // 看到玩家，停下来
      @velocity.velocities[e] = @math.Vec2D(0.0, 0.0)
    } else {
      // 没有玩家，左右巡逻
      sprite_info.idle_timer += delta
      
      // 每 3 秒改变一次方向
      if sprite_info.idle_timer > 3.0 {
        sprite_info.idle_timer = 0.0
        sprite_info.direction = match sprite_info.direction {
          Direction2::Left => Direction2::Right
          Direction2::Right => Direction2::Left
        }
      }
      
      // 缓慢移动
      let speed = 20.0
      let direction_multiplier = match sprite_info.direction {
        Direction2::Left => -1.0
        Direction2::Right => 1.0
      }
      @velocity.velocities[e] = @math.Vec2D(speed * direction_multiplier, 0.0)
    }
    
    // 播放待机动画，根据方向翻转
    let transform = match sprite_info.direction {
      Direction2::Left => @math.Transform::flip_x(16.0)
      Direction2::Right => @math.Transform::new()
    }
    @sprite.play_animation(
      e,
      sprites_idle_animation,
      transform=transform
    )
  }
}