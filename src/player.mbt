let player_magic_attack_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "asserts/Effect and FX Pixel Part 12 Free/566.png",
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
    "/asserts/Colour2/NoOutline/120x80_PNGSheets/_Death.png",
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
    "/asserts/Colour1/NoOutline/120x80_PNGSheets/_Idle.png",
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
    "/asserts/Colour2/NoOutline/120x80_PNGSheets/_CrouchAll.png",
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
    "/asserts/Colour2/NoOutline/120x80_PNGSheets/_Roll.png",
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
    "/asserts/Colour2/NoOutline/120x80_PNGSheets/_Attack.png",
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
    "/asserts/Colour2/NoOutline/120x80_PNGSheets/_Attack2.png",
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
    "/asserts/Colour2/NoOutline/120x80_PNGSheets/_Fall.png",
    10,
    width=120.0,
    height=80.0,
  ),
  loop_=false,
  fps=5,
)

///|
let player_fall_animation : @sprite.Animation = @sprite.Animation::new(
  @sprite.frames_from_atlas(
    "/asserts/Colour1/NoOutline/120x80_PNGSheets/_Fall.png",
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
    "/asserts/Colour2/NoOutline/120x80_PNGSheets/_Hit.png",
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
    "/asserts/Colour2/NoOutline/120x80_PNGSheets/_Jump.png",
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
    Rect(size=@math.Vec2D(120.0, 80.0), offset=@math.Vec2D(0.0, 0.0)),
  )
  @collision.collision_layers.set(game_state.player, player_collision_layer)
  @collision.colliders.set(
    game_state.player,
    @collision.Collider::new(
      @collision.CollisionMask::new([
        terrain_collision_layer, enemy_collision_layer,
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
const MAX_RUN_V = 160.0  // 降低最大跑步速度从240到160

///|
const JUMP_V = 680.0

///|
const MAX_FALL_V = 900.0

///|
const RUN_ACC = 2400.0  // 降低加速度从3600到2400，让移动更平滑

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
  println("🔥🔥🔥 开始攻击，攻击类型: " + attack_type.to_string() + " 🔥🔥🔥")
  
  let direction_str = match game_state.direction {
    Direction2::Left => "Left"
    Direction2::Right => "Right"
  }
  println("🧙 玩家朝向: " + direction_str)
  
  attack_state.is_attacking = true
  attack_state.attack_type = attack_type
  attack_state.has_hit = false
  
  // 设置攻击持续时间（攻击动画的活跃帧数）
  attack_state.attack_timer = match attack_type {
    1 => 15.0 // attack1 持续约15帧
    2 => 20.0 // attack2 持续约20帧  
    _ => 15.0
  }
  
  println("✅ 攻击状态设置完成，持续时间: " + attack_state.attack_timer.to_string() + " 帧")
  println("📊 攻击状态 - is_attacking: " + attack_state.is_attacking.to_string() + ", has_hit: " + attack_state.has_hit.to_string())
}

/// 更新攻击系统 - 基于踩踏逻辑的攻击检测
///|
fn update_attack_system(_delta : Double) -> Unit {
  if !attack_state.is_attacking {
    return
  }
  
  println("⚔️ 更新攻击系统 - timer: " + attack_state.attack_timer.to_string() + ", has_hit: " + attack_state.has_hit.to_string())
  
  // 减少攻击计时器
  attack_state.attack_timer -= 1.0
  
  // 如果还在攻击时间内且尚未命中，检测攻击
  if attack_state.attack_timer > 0.0 && !attack_state.has_hit {
    println("🔍 检测攻击碰撞...")
    check_attack_collision()
  }
  
  // 攻击时间结束，重置攻击状态
  if attack_state.attack_timer <= 0.0 {
    println("⏰ 攻击时间结束，重置攻击状态")
    attack_state.is_attacking = false
    attack_state.has_hit = false
  }
}

/// 检测攻击碰撞 - 直接范围检测，不依赖碰撞系统
///|
fn check_attack_collision() -> Unit {
  // 获取玩家位置
  let player_pos = @position.positions.get(game_state.player).unwrap_or(@math.Vec2D::zero())
  
  println("🔍 玩家位置: (" + player_pos.0[X].to_string() + ", " + player_pos.0[Y].to_string() + ")")
  
  // 设置攻击范围
  let attack_range = match attack_state.attack_type {
    1 => 120.0 // attack1 攻击范围
    2 => 150.0 // attack2 攻击范围
    _ => 120.0
  }
  
  println("🎯 攻击范围: " + attack_range.to_string())
  
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
    
    println("💀 骷髅位置: (" + skeleton_pos.0[X].to_string() + ", " + skeleton_pos.0[Y].to_string() + "), 距离平方: " + distance.to_string())
    
    // 检查是否在攻击范围内
    if distance <= max_distance {
      // 检查攻击方向是否正确
      let is_correct_direction = match game_state.direction {
        Direction2::Right => dx > 0.0 // 骷髅在玩家右侧
        Direction2::Left => dx < 0.0  // 骷髅在玩家左侧
      }
      
      if is_correct_direction {
        println("🎯 击中骷髅！攻击类型: " + attack_state.attack_type.to_string())
        
        // 对骷髅造成伤害
        let damage = match attack_state.attack_type {
          1 => 25 // attack1伤害
          2 => 40 // attack2伤害 
          _ => 25
        }
        
        println("💔 骷髅受到 " + damage.to_string() + " 点伤害")
        println("💖 骷髅血量: " + skeleton.health.to_string() + " -> " + (skeleton.health - damage).to_string())
        
        skeleton.is_hurt = true
        skeleton.hurt_timer = 60.0 // 受伤无敌时间
        skeleton.health -= damage
        
        // 给骷髅一个击退效果
        let knockback = match game_state.direction {
          Direction2::Right => @math.Vec2D(100.0, -50.0)
          Direction2::Left => @math.Vec2D(-100.0, -50.0)
        }
        @velocity.velocities[entity] = knockback
        
        if skeleton.health <= 0 {
          println("💀 骷髅死亡！")
        }
        
        attack_state.has_hit = true // 标记已命中，防止重复伤害
        
        if game_state.volume_on {
          @audio.play_audio("sounds/hurt.wav")
        }
        
        return // 只击中第一个敌人
      } else {
        let direction_str = match game_state.direction {
          Direction2::Right => "Right"
          Direction2::Left => "Left"
        }
        println("❌ 攻击方向错误 - 玩家朝向: " + direction_str + ", dx: " + dx.to_string())
      }
    }
  }
  
  println("❌ 攻击范围内没有敌人")
}

/// 创建魔法弹丸
///|
fn create_magic_projectile() -> Unit {
  println("✨ 创建魔法弹丸！")
  
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
  
  println("✅ 魔法弹丸创建完成！")
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
      println("⏰ 魔法弹丸生存时间到，销毁")
      entity.destroy()
      to_remove.push(entity)
      continue
    }
    
    // 检测弹丸与敌人的碰撞
    let projectile_collisions = @collision.get_collision_infos(entity)
    for collision in projectile_collisions {
      if skeletons.get(collision.entity) is Some(skeleton) {
        if skeleton.hurt_timer <= 0.0 {
          println("💥 魔法弹丸击中骷髅！")
          
          // 对骷髅造成伤害
          skeleton.is_hurt = true
          skeleton.hurt_timer = 60.0
          skeleton.health -= projectile.damage
          
          println("✨ 骷髅受到魔法伤害: " + projectile.damage.to_string())
          println("💖 骷髅血量: " + skeleton.health.to_string())
          
          // 给骷髅一个击退效果
          let knockback = match projectile.direction {
            Direction2::Right => @math.Vec2D(80.0, -30.0)
            Direction2::Left => @math.Vec2D(-80.0, -30.0)
          }
          @velocity.velocities[collision.entity] = knockback
          
          if skeleton.health <= 0 {
            println("💀 骷髅被魔法击杀！")
          }
          
          if game_state.volume_on {
            @audio.play_audio("sounds/hurt.wav")
          }
          
          // 销毁弹丸
          entity.destroy()
          to_remove.push(entity)
          break
        }
      } else if collision.entity != game_state.player { // 撞到地形或其他物体
        println("💥 魔法弹丸撞到障碍物")
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
  
  let player_collision = @collision.get_collision_infos(game_state.player)
  for collision in player_collision {
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
          } else {
            println("🌀 翻滚穿过敌人！")
          }
        }
      }
    }
  }
}

///|
fn player_state_system(delta : Double) -> Unit {
  let velocity = @collision.real_velocities
    .get(game_state.player)
    .unwrap_or(@math.Vec2D::zero())
  let mut new_velocity_x = velocity.0[X]
  let mut new_velocity_y = velocity.0[Y]
  if !(game_state.player_state is Hit) {
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
      if !@inputs.is_pressed(ArrowDown) || !@inputs.is_pressed(KeyS) {
        game_state.player_state = PlayerState::Idle
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
        game_state.player_state = PlayerState::Idle
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
        game_state.player_state = PlayerState::Idle
      }
    }
    MagicAttack => {
      @sprite.play_animation(
        game_state.player,
        player_attack_animation, // 使用普通攻击动画作为魔法攻击动画
        transform~,
      )
      if @sprite.is_animation_finished(game_state.player) {
        game_state.player_state = PlayerState::Idle
      }
    }
    Idle => {
      if velocity.0[X] == 0.0 {
        @sprite.play_animation(
          game_state.player,
          player_idle_animation,
          transform~,
        )
      } else {
        @sprite.play_animation(
          game_state.player,
          player_run_animation,
          transform~,
        )
      }
      if velocity.0[Y] > 0.0 {
        game_state.player_state = PlayerState::Fall
      }
      if (@inputs.is_just_pressed(ArrowUp) || @inputs.is_just_pressed(KeyW)) &&
        @collision.is_on_floor(game_state.player) {
        new_velocity_y = -JUMP_V
        game_state.player_state = PlayerState::Jump
        if game_state.volume_on {
          @audio.play_audio("sounds/jump.wav")
        }
      }
      if @inputs.is_just_pressed(ArrowDown) || @inputs.is_just_pressed(KeyS) {
        game_state.roll_count += 1
        if game_state.roll_count == 1 {
          game_state.player_state = PlayerState::Crouch
        } else if game_state.roll_count == 2 && game_state.roll_cooldown <= 0.0 {
          // 如果玩家正在移动，翻滚会朝移动方向进行
          if @inputs.is_pressed(@inputs.ArrowLeft) || @inputs.is_pressed(@inputs.KeyA) {
            game_state.direction = Direction2::Left
          } else if @inputs.is_pressed(@inputs.ArrowRight) || @inputs.is_pressed(@inputs.KeyD) {
            game_state.direction = Direction2::Right
          }
          
          game_state.player_state = PlayerState::Roll
          game_state.roll_cooldown = 90.0 // 1.5秒冷却时间 (90帧 @ 60fps)
          
          if game_state.volume_on {
            @audio.play_audio("sounds/roll.wav")
          }
          game_state.roll_count = 0
        }
      }
      if @inputs.is_just_pressed(KeyJ) {
        println("🎮🎮🎮 检测到J键按下！🎮🎮🎮")
        game_state.player_state = PlayerState::Attack
        game_state.attack_hit_count += 1
        println("📈 攻击计数增加到: " + game_state.attack_hit_count.to_string())
        
        // 开始攻击
        start_attack(game_state.attack_hit_count)
        
        if game_state.volume_on {
          @audio.play_audio("sounds/jump.wav") // 用跳跃音效来标识攻击开始
        }
      }
      if @inputs.is_just_pressed(KeyK) {
        println("✨✨✨ 检测到K键按下！魔法攻击！✨✨✨")
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
