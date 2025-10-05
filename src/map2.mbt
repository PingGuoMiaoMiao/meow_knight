// 第二关地图管理
// 这里定义第二关的布局、敌人配置和特殊机制

///| 第二关的敌人实体追踪
let level2_enemies : Map[@system.Entity, Bool] = Map::new()

///| 加载第二关
pub fn load_level2() -> Unit {
  println("🚪 正在加载第二关...")
  
  // 首先清除当前场景的所有实体
  clear_current_scene()
  
  // 重置玩家位置到第二关起始点
  @position.positions.set(game_state.player, @math.Vec2D(50.0, 100.0))
  
  // 加载第二关背景
  setup_level2_background()
  
  // 生成第二关地形
  setup_level2_terrain()
  
  // 添加第二关敌人
  setup_level2_enemies()
  
  // 添加第二关特殊物品
  setup_level2_items()
  
  println("✅ 第二关加载完成！")
}

///| 设置第二关背景
fn setup_level2_background() -> Unit {
  let background = @system.Entity::new()
  let background_sprite = @sprite.Sprite::from_animation(
    @sprite.Animation::single_frame(
      "asserts1/Background/background2.png",  // 第二关使用不同的背景
      @math.Vec2D(1056.0, 432.0),
      offset=@math.Vec2D::zero(),
    ),
    0,
  )
  @sprite.sprites.set(background, background_sprite)
  @position.positions.set(background, @math.Vec2D::zero())
  
  println("🖼️ 第二关背景设置完成")
}

///| 设置第二关地形
fn setup_level2_terrain() -> Unit {
  // 创建一个更有挑战性的地形布局
  
  // 左侧平台
  add_stone(@math.Vec2D(100.0, 350.0), "21")
  add_stone(@math.Vec2D(116.0, 350.0), "21")
  add_stone(@math.Vec2D(132.0, 350.0), "21")
  
  // 中间高台
  add_stone(@math.Vec2D(250.0, 280.0), "21")
  add_stone(@math.Vec2D(266.0, 280.0), "21")
  add_stone(@math.Vec2D(282.0, 280.0), "21")
  add_stone(@math.Vec2D(298.0, 280.0), "21")
  
  // 右侧平台
  add_stone(@math.Vec2D(450.0, 320.0), "21")
  add_stone(@math.Vec2D(466.0, 320.0), "21")
  add_stone(@math.Vec2D(482.0, 320.0), "21")
  
  // 底部地面
  for i = 0; i < 15; i = i + 1 {
    add_stone(@math.Vec2D(16.0 * i.to_double(), 400.0), "21")
  }
  
  // 添加一些草地装饰
  add_grass(@math.Vec2D(100.0, 334.0), "46")  // 左侧平台上的草
  add_grass(@math.Vec2D(250.0, 264.0), "46")  // 中间高台上的草
  add_grass(@math.Vec2D(450.0, 304.0), "46")  // 右侧平台上的草
  
  println("🗻 第二关地形设置完成")
}

///| 设置第二关敌人
fn setup_level2_enemies() -> Unit {
  // 清空敌人追踪列表
  level2_enemies.clear()
  
  // 添加更多挑战性的敌人组合
  
  // 左侧平台：1个史莱姆
  add_silme(@math.Vec2D(120.0, 0.0))
  
  // 中间高台：2个蘑菇怪
  add_mushroom(@math.Vec2D(260.0, 0.0))
  add_mushroom(@math.Vec2D(290.0, 0.0))
  
  // 右侧平台：1个史莱姆
  add_silme(@math.Vec2D(460.0, 0.0))
  
  // 最终Boss：2个Older！
  let older1 = add_Older(@math.Vec2D(350.0, 300.0))
  let older2 = add_Older(@math.Vec2D(400.0, 300.0))
  
  // 将Older注册到场景切换系统
  older_entities.set(older1, true)
  older_entities.set(older2, true)
  
  println("👹 第二关敌人设置完成：2个Older Boss需要击败！")
}

///| 设置第二关物品
fn setup_level2_items() -> Unit {
  // 在各个平台放置金币作为奖励
  add_coin(@math.Vec2D(120.0, 300.0))  // 左侧平台
  add_coin(@math.Vec2D(270.0, 230.0))  // 中间高台
  add_coin(@math.Vec2D(460.0, 270.0))  // 右侧平台
  add_coin(@math.Vec2D(375.0, 350.0))  // Boss区域附近
  
  println("💰 第二关物品设置完成")
}

///| 检查第二关是否完成
pub fn check_level2_completion() -> Unit {
  // 这个函数可以检查第二关的完成条件
  // 比如击败所有Boss、收集所有物品等
  if !older_entities.is_empty() {
    let all_bosses_defeated = older_entities.iter().all(fn(entry) {
      let boss_entity = entry.0
      !@position.positions.contains(boss_entity)
    })
    
    if all_bosses_defeated {
      println("🏆 恭喜！你已经通关了所有关卡！")
      // 可以在这里添加通关动画或返回主菜单的逻辑
    }
  }
}