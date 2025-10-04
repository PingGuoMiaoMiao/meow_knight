let player_magic_attack_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts1/Effect and FX Pixel Part 12 Free/566.png",
    13,
    width=64.0,
    height=64.0,
  ),
  loop_=false,
  fps=2,
)
///|
let player_death_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts/Colour2/NoOutline/120x80_PNGSheets/_Death.png",
    10,
    width=120.0,
    height=80.0,
  ),
  loop_=false,
  fps=2,
)

///|
let player_idle_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts/Colour1/NoOutline/120x80_PNGSheets/_Idle.png",
    10,
    width=120.0,
    height=80.0,
  ),
  loop_=false,
  fps=12,
)

///|
let player_crouch_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts/Colour2/NoOutline/120x80_PNGSheets/_CrouchAll.png",
    3,
    width=120.0,
    height=80.0,
  ),
  loop_=true,
  fps=1,
)

///|
let player_roll_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts/Colour2/NoOutline/120x80_PNGSheets/_Roll.png",
    12,
    width=120.0,
    height=80.0,
  ),
  loop_=false,
  fps=12,
)

///|
let player_attack_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts/Colour2/NoOutline/120x80_PNGSheets/_Attack.png",
    4,
    width=120.0,
    height=80.0,
  ),
  loop_=false,
  fps=12,
)

///|
let player_attack2_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts/Colour2/NoOutline/120x80_PNGSheets/_Attack2.png",
    6,
    width=120.0,
    height=80.0,
  ),
  loop_=false,
  fps=12,
)

///|
let player_run_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts/Colour2/NoOutline/120x80_PNGSheets/_Run.png",
    10,
    width=120.0,
    height=80.0,
  ),
  loop_=true,  // 跑步动画应该循环播放
  fps=12,
)

///|
let player_fall_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts/Colour1/NoOutline/120x80_PNGSheets/_Fall.png",
    3,
    width=120.0,
    height=80.0,
  ),
  loop_=false,
  fps=1,
)

///|
let player_hit_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts/Colour2/NoOutline/120x80_PNGSheets/_Hit.png",
    1,
    width=120.0,
    height=80.0,
  ),
  loop_=false,
  fps=1,
)

///|
let player_jump_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts/Colour2/NoOutline/120x80_PNGSheets/_Jump.png",
    3,
    width=120.0,
    height=80.0,
  ),
  loop_=false,
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
    Rect(size=@math.Vec2D(120.0, 80.0), offset=@math.Vec2D(20, 0.0)),
  )
  @collision.collision_layers.set(game_state.player, player_collision_layer)
  @collision.colliders.set(
    game_state.player,
    @collision.Collider::new(
      @collision.CollisionMask::new([
        terrain_collision_layer,  // 与地形碰撞
        enemy_collision_layer,    // 与敌人碰撞（检测slime等敌人）
      ]),
    ),
  )
  @camera.attach_entity(game_state.player, @math.Vec2D(16.0, 16.0))
}

///|
enum PlayerState {
  Death
  Attack
  Idle
  Hit
  Jump
  Roll
  Fall
  Crouch
  MagicAttack
  
} derive(Show)

///|
const GRAVITY = 1800.0

///|
const MAX_RUN_V = 120.0  // 最大跑步速度（从160降低到120）

///|
const JUMP_V = 680.0

///|
const MAX_FALL_V = 900.0

///|
const RUN_ACC = 1800.0  // 加速度（从2400降低到1800），让步伐更小

///|
const BUMP_V : Double = JUMP_V / 2.0

///|
const ROLL_SPEED = 300.0  // 翻滚时的前进速度

///|
struct AttackState {
  mut is_attacking : Bool
  mut attack_type : Int // 1 for attack1, 2 for attack2
  mut attack_timer : Double
  mut has_hit : Bool // 防止一次攻击多次伤害
}

///|
let attack_state : AttackState = {
  is_attacking: false,
  attack_type: 0,
  attack_timer: 0.0,
  has_hit: false
}

///|
struct MagicProjectile {
  entity : @system.Entity
  mut timer : Double
  damage : Int
  direction : Direction2
}

///|
let magic_projectiles : Map[@system.Entity, MagicProjectile] = Map::new()

///|
const MAGIC_SPEED = 400.0  // 魔法弹丸飞行速度

///|
const MAGIC_DAMAGE = 30  // 魔法弹丸伤害

///|
const MAGIC_LIFETIME = 180.0  // 魔法弹丸存在时间（3秒）

/// 开始攻击 - 设置攻击状态
///|
fn start_attack(attack_type : Int) -> Unit {
  attack_state.is_attacking = true
  attack_state.attack_type = attack_type
  attack_state.has_hit = false
  
  // 设置攻击持续时间（攻击动画的活跃帧数）
  attack_state.attack_timer = match attack_type {
    1 => 15.0 // attack1 持续约15帧
    2 => 20.0 // attack2 持续约20帧  
    _ => 15.0
  }
}

/// 更新攻击系统 - 基于踩踏逻辑的攻击检测
///|
fn update_attack_system(_delta : Double) -> Unit {
  if !attack_state.is_attacking {
    return
  }
  
  // 减少攻击计时器
  attack_state.attack_timer -= 1.0
  
  // 如果还在攻击时间内且尚未命中，检测攻击
  if attack_state.attack_timer > 0.0 && !attack_state.has_hit {
    check_attack_collision()
  }
  
  // 攻击时间结束，重置攻击状态
  if attack_state.attack_timer <= 0.0 {
    attack_state.is_attacking = false
    attack_state.has_hit = false
  }
}

/// 检测攻击碰撞 - 直接范围检测，不依赖碰撞系统
///|
fn check_attack_collision() -> Unit {
  // 获取玩家位置
  let player_pos = @position.positions.get(game_state.player).unwrap_or(@math.Vec2D::zero())
  
  // 设置攻击范围
  let attack_range = match attack_state.attack_type {
    1 => 120.0 // attack1 攻击范围
    2 => 150.0 // attack2 攻击范围
    _ => 120.0
  }
  
  // 遍历所有骷髅，检查是否在攻击范围内
  for entity, skeleton in skeletons {
    if skeleton.hurt_timer > 0.0 { 
      continue // 跳过无敌状态的骷髅
    }
    
    let skeleton_pos = @position.positions.get(entity).unwrap_or(@math.Vec2D::zero())
    
    // 计算距离
    let dx = skeleton_pos.0[X] - player_pos.0[X]
    let dy = skeleton_pos.0[Y] - player_pos.0[Y]
    let distance = dx * dx + dy * dy // 使用平方距离避免开方计算
    let max_distance = attack_range * attack_range
    
    // 检查是否在攻击范围内
    if distance <= max_distance {
      // 检查攻击方向是否正确
      let is_correct_direction = match game_state.direction {
        Direction2::Right => dx > 0.0 // 骷髅在玩家右侧
        Direction2::Left => dx < 0.0  // 骷髅在玩家左侧
      }
      
      if is_correct_direction {
        // 对骷髅造成伤害
        let damage = match attack_state.attack_type {
          1 => 25 // attack1伤害
          2 => 40 // attack2伤害 
          _ => 25
        }
        
        skeleton.is_hurt = true
        skeleton.hurt_timer = 60.0 // 受伤无敌时间
        skeleton.health -= damage
        
        // 给骷髅一个击退效果
        let knockback = match game_state.direction {
          Direction2::Right => @math.Vec2D(100.0, -50.0)
          Direction2::Left => @math.Vec2D(-100.0, -50.0)
        }
        @velocity.velocities[entity] = knockback
        
        attack_state.has_hit = true // 标记已命中，防止重复伤害
        
        if game_state.volume_on {
          @audio.play_audio("sounds/hurt.wav")
        }
        
        return // 只击中第一个敌人
      }
    }
  }
  
  // 遍历所有slime，检查是否在攻击范围内
  for entity, silme in silmes {
    if silme.hurt_timer > 0.0 { 
      continue // 跳过无敌状态的slime
    }
    
    let silme_pos = @position.positions.get(entity).unwrap_or(@math.Vec2D::zero())
    
    // 计算距离
    let dx = silme_pos.0[X] - player_pos.0[X]
    let dy = silme_pos.0[Y] - player_pos.0[Y]
    let distance = dx * dx + dy * dy // 使用平方距离避免开方计算
    let max_distance = attack_range * attack_range
    
    // 检查是否在攻击范围内
    if distance <= max_distance {
      // 检查攻击方向是否正确
      let is_correct_direction = match game_state.direction {
        Direction2::Right => dx > 0.0 // slime在玩家右侧
        Direction2::Left => dx < 0.0  // slime在玩家左侧
      }
      
      if is_correct_direction {
        // 对slime造成伤害
        let damage = match attack_state.attack_type {
          1 => 25 // attack1伤害
          2 => 40 // attack2伤害 
          _ => 25
        }
        
        silme.is_hurt = true
        silme.hurt_timer = 60.0 // 受伤无敌时间
        silme.health -= damage
        
        // 给slime一个更强的击退效果，让它飞起来
        let knockback = match game_state.direction {
          Direction2::Right => @math.Vec2D(150.0, -300.0)  // 增加水平和垂直击退力度
          Direction2::Left => @math.Vec2D(-150.0, -300.0)
        }
        @velocity.velocities[entity] = knockback
        
        attack_state.has_hit = true // 标记已命中，防止重复伤害
        
        if game_state.volume_on {
          @audio.play_audio("sounds/hurt.wav")
        }
        
        return // 只击中第一个敌人
      }
    }
  }
}

/// 创建魔法弹丸
///|
fn create_magic_projectile() -> Unit {
  // 获取玩家位置
  let player_pos = @position.positions.get(game_state.player).unwrap_or(@math.Vec2D::zero())
  
  // 创建弹丸实体
  let projectile_entity = @system.Entity::new()
  
  // 设置弹丸位置（从玩家前方发射）
  let projectile_pos = match game_state.direction {
    Direction2::Right => @math.Vec2D(player_pos.0[X] + 80.0, player_pos.0[Y] + 20.0)
    Direction2::Left => @math.Vec2D(player_pos.0[X] - 80.0, player_pos.0[Y] + 20.0)
  }
  
  // 设置弹丸速度
  let projectile_velocity = match game_state.direction {
    Direction2::Right => @math.Vec2D(MAGIC_SPEED, 0.0)
    Direction2::Left => @math.Vec2D(-MAGIC_SPEED, 0.0)
  }
  
  // 设置弹丸动画和属性
  let projectile_sprite = @sprite.Sprite::from_animation(player_magic_attack_animation, 10)
  @sprite.sprites.set(projectile_entity, projectile_sprite)
  @position.positions.set(projectile_entity, projectile_pos)
  @velocity.velocities.set(projectile_entity, projectile_velocity)
  
  // 设置弹丸碰撞检测
  @collision.shapes.set(
    projectile_entity,
    Rect(size=@math.Vec2D(32.0, 32.0), offset=@math.Vec2D(0.0, 0.0))
  )
  @collision.collision_layers.set(projectile_entity, player_collision_layer)
  @collision.colliders.set(
    projectile_entity,
    @collision.Collider::new(
      @collision.CollisionMask::new([enemy_collision_layer, terrain_collision_layer])
    )
  )
  
  // 添加到弹丸管理列表
  magic_projectiles[projectile_entity] = {
    entity: projectile_entity,
    timer: MAGIC_LIFETIME,
    damage: MAGIC_DAMAGE,
    direction: game_state.direction
  }
}

/// 更新魔法弹丸系统
///|
fn update_magic_projectiles(_delta : Double) -> Unit {
  let to_remove : Array[@system.Entity] = []
  
  for entity, projectile in magic_projectiles {
    // 检查弹丸是否还存活
    if !entity.is_alive() {
      to_remove.push(entity)
      continue
    }
    
    // 减少生存时间
    projectile.timer -= 1.0
    if projectile.timer <= 0.0 {
      entity.destroy()
      to_remove.push(entity)
      continue
    }
    
    // 检测弹丸与敌人的碰撞
    let projectile_collisions = @collision.get_collision_infos(entity)
    for collision in projectile_collisions {
      // 检测骷髅
      if skeletons.get(collision.entity) is Some(skeleton) {
        if skeleton.hurt_timer <= 0.0 {
          // 对骷髅造成伤害
          skeleton.is_hurt = true
          skeleton.hurt_timer = 60.0
          skeleton.health -= projectile.damage
          
          // 给骷髅一个击退效果
          let knockback = match projectile.direction {
            Direction2::Right => @math.Vec2D(80.0, -30.0)
            Direction2::Left => @math.Vec2D(-80.0, -30.0)
          }
          @velocity.velocities[collision.entity] = knockback
          
          if game_state.volume_on {
            @audio.play_audio("sounds/hurt.wav")
          }
          
          // 销毁弹丸
          entity.destroy()
          to_remove.push(entity)
          break
        }
      } else if silmes.get(collision.entity) is Some(silme) {
        // 检测slime
        if silme.hurt_timer <= 0.0 {
          // 对slime造成伤害
          silme.is_hurt = true
          silme.hurt_timer = 60.0
          silme.health -= projectile.damage
          
          // 给slime一个更强的击退效果
          let knockback = match projectile.direction {
            Direction2::Right => @math.Vec2D(120.0, -250.0)  // 增加击退力度
            Direction2::Left => @math.Vec2D(-120.0, -250.0)
          }
          @velocity.velocities[collision.entity] = knockback
          
          if game_state.volume_on {
            @audio.play_audio("sounds/hurt.wav")
          }
          
          // 销毁弹丸
          entity.destroy()
          to_remove.push(entity)
          break
        }
      } else if collision.entity != game_state.player { // 撞到地形或其他物体
        entity.destroy()
        to_remove.push(entity)
        break
      }
    }
  }
  
  // 清理已销毁的弹丸
  for entity in to_remove {
    magic_projectiles.remove(entity)
  }
}

///|
fn player_collision_system(_delta : Double) -> Unit {
  if game_state.hurt_timer > 0.0 {
    game_state.hurt_timer -= 1.0
  }
  
  // 更新翻滚冷却时间
  if game_state.roll_cooldown > 0.0 {
    game_state.roll_cooldown -= 1.0
  }
  
  // 更新攻击系统
  update_attack_system(_delta)
  
  // 更新魔法弹丸系统
  update_magic_projectiles(_delta)
  
  // // 更新Unknown块移动
  // update_unknown_blocks(_delta)
  
  let player_collision = @collision.get_collision_infos(game_state.player)
  for collision in player_collision {
    // 处理骷髅碰撞
    if skeletons.get(collision.entity) is Some(skeleton) {
      // 只有当骷髅不在受伤状态时才能伤害玩家
      if skeleton.hurt_timer <= 0.0 {
        if collision.direction[Y] > 0.0 {
          // 踩踏攻击 - 始终有效
          skeleton.is_hurt = true
          skeleton.hurt_timer = 60.0
          skeleton.health -= 50 // 踩踏伤害
          guard @velocity.velocities.get(game_state.player) is Some(velocity)
          @velocity.velocities[game_state.player] = velocity.0.update(Y, -BUMP_V)
        } else {
          // 侧面碰撞 - 翻滚时可以穿过敌人
          if !(game_state.player_state is Roll) {
            hurt_player()
          }
        }
      }
    }
    
    // 处理slime碰撞
    if silmes.get(collision.entity) is Some(silme) {
      // 只有当slime不在受伤状态时才能伤害玩家
      if silme.hurt_timer <= 0.0 {
        if collision.direction[Y] > 0.0 {
          // 踩踏攻击 - 始终有效
          silme.is_hurt = true
          silme.hurt_timer = 60.0
          silme.health -= 50 // 踩踏伤害
          
          // 给slime一个向下的压力，然后会自然弹起
          @velocity.velocities[collision.entity] = @math.Vec2D(0.0, 100.0)
          
          guard @velocity.velocities.get(game_state.player) is Some(velocity)
          @velocity.velocities[game_state.player] = velocity.0.update(Y, -BUMP_V)
          
          if game_state.volume_on {
            @audio.play_audio("sounds/hurt.wav")
          }
        } else {
          // 侧面碰撞 - 翻滚时可以穿过敌人
          if !(game_state.player_state is Roll) {
            hurt_player()
          }
        }
      }
    }
    
    // // 处理Unknown块碰撞
    // if unknown_blocks.get(collision.entity) is Some(unknown_block) {
    //   // 获取玩家和Unknown块的位置信息
    //   let player_pos = @position.positions.get(game_state.player).unwrap_or(@math.Vec2D::zero())
    //   let unknown_pos = @position.positions.get(collision.entity).unwrap_or(@math.Vec2D::zero())
    //   let player_velocity = @velocity.velocities.get(game_state.player).unwrap_or(@math.Vec2D::zero())
      
    //   println("🔍 碰撞检测: 玩家Y=" + player_pos.0[@math.Axis::Y].to_string() + ", Unknown Y=" + unknown_pos.0[@math.Axis::Y].to_string() + ", 玩家速度Y=" + player_velocity.0[@math.Axis::Y].to_string())
    //   println("🔍 碰撞方向: " + collision.direction[@math.Axis::Y].to_string())
      
    //   // 检查条件：玩家从下方向上撞击Unknown块的底部
    //   // 1. 玩家在Unknown块下方 (player_y + player_height > unknown_y)
    //   // 2. 玩家向上运动 (velocity_y < 0)
    //   // 3. 碰撞方向是向上撞击 (collision.direction[Y] > 0.0 表示玩家从下往上撞)
    //   // 4. Unknown块没有在移动
    //   let player_bottom = player_pos.0[@math.Axis::Y] + 80.0 // 玩家高度80
    //   let unknown_bottom = unknown_pos.0[@math.Axis::Y] + 16.0 // Unknown高度16
      
    //   if player_bottom > unknown_pos.0[@math.Axis::Y] && // 玩家底部在Unknown顶部下方
    //      player_pos.0[@math.Axis::Y] < unknown_bottom && // 玩家顶部在Unknown底部上方
    //      player_velocity.0[@math.Axis::Y] < 0.0 && // 玩家向上移动
    //      collision.direction[@math.Axis::Y] > 0.0 && // 碰撞方向向上
    //      !unknown_block.is_moving {
    //     // 玩家从下方跳跃顶到Unknown块！
    //     println("🟫 玩家从下方顶到Unknown块！触发动画！")
    //     unknown_block.is_moving = true
    //     unknown_block.current_phase = 1 // 开始向上移动
    //     unknown_block.move_timer = 0.0
        
    //     // 给玩家一个反弹效果
    //     guard @velocity.velocities.get(game_state.player) is Some(velocity)
    //     @velocity.velocities[game_state.player] = velocity.0.update(@math.Axis::Y, -BUMP_V)
    //   }
    // }
  }
}

///|
fn player_state_system(delta : Double) -> Unit {
  // 检查E键拾取金币
  if @inputs.is_just_pressed(@inputs.KeyE) {
    try_pickup_coin()
  }
  
  let velocity = @collision.real_velocities
    .get(game_state.player)
    .unwrap_or(@math.Vec2D::zero())
  let mut new_velocity_x = velocity.0[X]
  let mut new_velocity_y = velocity.0[Y]
  
  // 更新上次按键时间计时器（只在有效范围内增加）
  if game_state.last_down_press_time > 0.0 && game_state.last_down_press_time < 100.0 {
    game_state.last_down_press_time += 1.0
  }
  
  // 只有在非受伤、非攻击、非翻滚状态时才能控制移动
  if !(game_state.player_state is Hit) && 
     !(game_state.player_state is Attack) && 
     !(game_state.player_state is MagicAttack) &&
     !(game_state.player_state is Roll) {
    if @inputs.is_pressed(@inputs.ArrowLeft) || @inputs.is_pressed(@inputs.KeyA) {
      new_velocity_x -= RUN_ACC * delta
      if new_velocity_x < -MAX_RUN_V {
        new_velocity_x = -MAX_RUN_V
      }
      game_state.direction = Direction2::Left
    } else if @inputs.is_pressed(@inputs.ArrowRight) ||
      @inputs.is_pressed(@inputs.KeyD) {
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
    Death => {
      @sprite.play_animation(
        game_state.player,
        player_death_animation,
        transform~,
      )
      if @sprite.is_animation_finished(game_state.player) {
        if game_state.volume_on {
          @audio.play_audio("sounds/death.wav")
        }
      }
    }
    Crouch => {
      @sprite.play_animation(
        game_state.player,
        player_crouch_animation,
        transform~,
      )
      
      // 检查双击触发翻滚
      if (@inputs.is_just_pressed(ArrowDown) || @inputs.is_just_pressed(KeyS)) &&
         game_state.roll_cooldown <= 0.0 {
        // 在下蹲状态下再次按下，触发翻滚
        if @inputs.is_pressed(@inputs.ArrowLeft) || @inputs.is_pressed(@inputs.KeyA) {
          game_state.direction = Direction2::Left
        } else if @inputs.is_pressed(@inputs.ArrowRight) || @inputs.is_pressed(@inputs.KeyD) {
          game_state.direction = Direction2::Right
        }
        
        game_state.player_state = PlayerState::Roll
        game_state.roll_cooldown = 90.0
        game_state.last_down_press_time = -999.0
        
        if game_state.volume_on {
          @audio.play_audio("sounds/roll.wav")
        }
      } else if !@inputs.is_pressed(ArrowDown) && !@inputs.is_pressed(KeyS) {
        // 两个键都没按才退出下蹲状态
        game_state.player_state = PlayerState::Idle
        game_state.last_down_press_time = -999.0  // 重置计时器
      }
    }
    Roll => {
      @sprite.play_animation(
        game_state.player,
        player_roll_animation,
        transform~,
      )
      
      // 翻滚时给玩家一个向前的速度
      new_velocity_x = match game_state.direction {
        Direction2::Right => ROLL_SPEED
        Direction2::Left => -ROLL_SPEED
      }
      
      // 翻滚时修改碰撞掩码，让玩家不会与敌人发生物理碰撞
      @collision.colliders.set(
        game_state.player,
        @collision.Collider::new(
          @collision.CollisionMask::new([terrain_collision_layer]) // 只与地形碰撞，忽略敌人
        )
      )
      
      if @sprite.is_animation_finished(game_state.player) {
        // 翻滚结束后检查是否在空中
        if @collision.is_on_floor(game_state.player) {
          game_state.player_state = PlayerState::Idle
        } else if velocity.0[Y] > 0.0 {
          game_state.player_state = PlayerState::Fall
        } else {
          game_state.player_state = PlayerState::Jump
        }
        
        // 翻滚结束，恢复正常的碰撞掩码
        @collision.colliders.set(
          game_state.player,
          @collision.Collider::new(
            @collision.CollisionMask::new([
              terrain_collision_layer, enemy_collision_layer,
            ])
          )
        )
      }
    }
    Attack => {
      // 攻击时停止水平移动
      new_velocity_x = 0.0
      
      if game_state.attack_hit_count == 1 {
        @sprite.play_animation(
          game_state.player,
          player_attack_animation,
          transform~,
        )
      } else if game_state.attack_hit_count == 2 {
        @sprite.play_animation(
          game_state.player,
          player_attack2_animation,
          transform~,
        )
        game_state.attack_hit_count = 0
      }
      if @sprite.is_animation_finished(game_state.player) {
        // 攻击结束后检查是否在空中
        if @collision.is_on_floor(game_state.player) {
          game_state.player_state = PlayerState::Idle
        } else if velocity.0[Y] > 0.0 {
          game_state.player_state = PlayerState::Fall
        } else {
          game_state.player_state = PlayerState::Jump
        }
      }
    }
    MagicAttack => {
      // 魔法攻击时停止水平移动
      new_velocity_x = 0.0
      
      @sprite.play_animation(
        game_state.player,
        player_attack_animation, // 使用普通攻击动画作为魔法攻击动画
        transform~,
      )
      if @sprite.is_animation_finished(game_state.player) {
        // 魔法攻击结束后检查是否在空中
        if @collision.is_on_floor(game_state.player) {
          game_state.player_state = PlayerState::Idle
        } else if velocity.0[Y] > 0.0 {
          game_state.player_state = PlayerState::Fall
        } else {
          game_state.player_state = PlayerState::Jump
        }
      }
    }
    Idle => {
      // 检查是否有水平输入来决定动画
      let has_horizontal_input = @inputs.is_pressed(@inputs.ArrowLeft) ||
                                  @inputs.is_pressed(@inputs.KeyA) ||
                                  @inputs.is_pressed(@inputs.ArrowRight) ||
                                  @inputs.is_pressed(@inputs.KeyD)
      
      if has_horizontal_input && velocity.0[X].abs() > 10.0 {
        @sprite.play_animation(
          game_state.player,
          player_run_animation,
          transform~,
        )
      } else {
        @sprite.play_animation(
          game_state.player,
          player_idle_animation,
          transform~,
        )
      }
      
      // 检查是否离开地面
      if velocity.0[Y] > 0.0 {
        game_state.player_state = PlayerState::Fall
      }
      
      // 跳跃输入
      if (@inputs.is_just_pressed(ArrowUp) || @inputs.is_just_pressed(KeyW)) &&
        @collision.is_on_floor(game_state.player) {
        new_velocity_y = -JUMP_V
        game_state.player_state = PlayerState::Jump
        if game_state.volume_on {
          @audio.play_audio("sounds/jump.wav")
        }
      }
      
      // 下蹲/翻滚输入（支持两种方式）
      if @inputs.is_just_pressed(ArrowDown) || @inputs.is_just_pressed(KeyS) {
        // 检查是否在双击时间窗口内（20帧 ≈ 0.33秒）
        if game_state.last_down_press_time > 0.0 && 
           game_state.last_down_press_time < 20.0 && 
           game_state.roll_cooldown <= 0.0 {
          // 双击检测成功，直接触发翻滚
          if @inputs.is_pressed(@inputs.ArrowLeft) || @inputs.is_pressed(@inputs.KeyA) {
            game_state.direction = Direction2::Left
          } else if @inputs.is_pressed(@inputs.ArrowRight) || @inputs.is_pressed(@inputs.KeyD) {
            game_state.direction = Direction2::Right
          }
          
          game_state.player_state = PlayerState::Roll
          game_state.roll_cooldown = 90.0 // 1.5秒冷却时间 (90帧 @ 60fps)
          game_state.last_down_press_time = -999.0  // 重置计时器
          
          if game_state.volume_on {
            @audio.play_audio("sounds/roll.wav")
          }
        } else {
          // 第一次按下或超时，进入下蹲状态
          game_state.player_state = PlayerState::Crouch
          game_state.last_down_press_time = 1.0  // 开始计时（从1开始，避免和0冲突）
        }
      }
      
      // 攻击输入
      if @inputs.is_just_pressed(KeyJ) {
        game_state.player_state = PlayerState::Attack
        game_state.attack_hit_count += 1
        
        // 开始攻击
        start_attack(game_state.attack_hit_count)
        
        if game_state.volume_on {
          @audio.play_audio("sounds/jump.wav") // 用跳跃音效来标识攻击开始
        }
      }
      
      // 魔法攻击输入
      if @inputs.is_just_pressed(KeyK) {
        game_state.player_state = PlayerState::MagicAttack
        
        // 创建魔法弹丸
        create_magic_projectile()
        
        if game_state.volume_on {
          @audio.play_audio("sounds/power_up.wav") // 用能量音效来标识魔法攻击
        }
      }
    }
    Fall => {
      @sprite.play_animation(
        game_state.player,
        player_fall_animation,
        transform~,
      )
      if @collision.is_on_floor(game_state.player) {
        game_state.player_state = PlayerState::Idle
      }
    }
    Jump => {
      @sprite.play_animation(
        game_state.player,
        player_jump_animation,
        transform~,
      )
      if velocity.0[Y] > 0.0 {
        game_state.player_state = PlayerState::Fall
      }
    }
    Hit => {
      @sprite.play_animation(
        game_state.player,
        player_hit_animation,
        transform~,
      )
      if @collision.is_on_floor(game_state.player) {
        new_velocity_x = 0.0
      }
      if @sprite.is_animation_finished(game_state.player) {
        if @collision.is_on_floor(game_state.player) {
          game_state.player_state = PlayerState::Idle
        } else if velocity.0[Y] < 0.0 {
          game_state.player_state = PlayerState::Fall
        } else {
          game_state.player_state = PlayerState::Jump
        }
      }
    }
  }
  new_velocity_y += GRAVITY * delta
  if new_velocity_y > MAX_FALL_V {
    new_velocity_y = MAX_FALL_V
  }
  @velocity.velocities[game_state.player] = @math.Vec2D(
    new_velocity_x, new_velocity_y,
  )
}

/// 更新Unknown块的移动系统
// ///|
// fn update_unknown_blocks(_delta : Double) -> Unit {
//   for entity, unknown_block in unknown_blocks {
//     if !unknown_block.is_moving {
//       continue
//     }
    
//     unknown_block.move_timer += _delta * 60.0 // 转换为帧数
    
//     match unknown_block.current_phase {
//       1 => {
//         // 向上移动阶段
//         let progress = unknown_block.move_timer / 15.0 // 15帧完成向上移动
//         if progress >= 1.0 {
//           // 移动完成，设置到目标位置
//           let target_pos = @math.Vec2D(
//             unknown_block.original_pos[@math.Axis::X],
//             unknown_block.original_pos[@math.Axis::Y] - 8.0  // 向上移动半个Unknown位置 (16/2=8)
//           )
//           @position.positions[entity] = target_pos
//           unknown_block.current_phase = 2 // 进入停留阶段
//           unknown_block.move_timer = 0.0
//         } else {
//           // 平滑向上移动
//           let current_y = unknown_block.original_pos[@math.Axis::Y] - (8.0 * progress)
//           let current_pos = @math.Vec2D(
//             unknown_block.original_pos[@math.Axis::X],
//             current_y
//           )
//           @position.positions[entity] = current_pos
//         }
//       }
//       2 => {
//         // 停留阶段
//         if unknown_block.move_timer >= 30.0 { // 停留30帧 (0.5秒)
//           unknown_block.current_phase = 3 // 进入向下移动阶段
//           unknown_block.move_timer = 0.0
//         }
//       }
//       3 => {
//         // 向下移动阶段
//         let progress = unknown_block.move_timer / 15.0 // 15帧完成向下移动
//         if progress >= 1.0 {
//           // 移动完成，回到原位
//           @position.positions[entity] = unknown_block.original_pos
//           unknown_block.current_phase = 0
//           unknown_block.is_moving = false
//           unknown_block.move_timer = 0.0
//         } else {
//           // 平滑向下移动
//           let start_y = unknown_block.original_pos[@math.Axis::Y] - 8.0
//           let current_y = start_y + (8.0 * progress)
//           let current_pos = @math.Vec2D(
//             unknown_block.original_pos[@math.Axis::X],
//             current_y
//           )
//           @position.positions[entity] = current_pos
//         }
//       }
//       _ => ignore(()) // 默认情况，不做任何操作
//     }
//   }
// }
