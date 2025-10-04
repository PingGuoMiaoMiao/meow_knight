// Copyright 2025 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// 简化的UI系统 - 不使用@ui模块，直接用sprite显示

///| UI层级常量
const UI_Z : Int = 1000

///| 对话队列项
struct DialogueItem {
  name : String
  text : String
  avatar : @sprite.Animation?
}

///| 对话队列和当前索引
let dialogue_queue : Array[DialogueItem] = []
struct DialogueState {
  mut current_index : Int
  mut has_queue : Bool
}
let dialogue_state : DialogueState = { current_index: 0, has_queue: false }

///| UI实体存储结构
struct UIEntities {
  mut score_entity : @system.Entity
  mut health_entity : @system.Entity
}

///| 全局UI实体存储
let ui_entities : UIEntities = {
  score_entity: @system.Entity::new(),
  health_entity: @system.Entity::new(),
}

///| 检查鼠标是否在关闭按钮范围内（已废弃，现在使用空格键关闭）
pub fn is_mouse_on_close_button() -> Bool {
  false  // 不再使用鼠标关闭
}

///| 添加分数显示
pub fn add_score_box() -> Unit {
  let entity = @system.Entity::new()
  @position.positions.set(entity, @math.Vec2D(World_Width / 2.0 - 50, 20))
  let text_sprite = @sprite.Sprite::from_text(
    @sprite.Text::new("Score: 0", font="20px ThaleahFat", color="#FFFFFF"),
    UI_Z,
  )
  @sprite.sprites.set(entity, text_sprite)
  ui_entities.score_entity = entity
}

///| 添加血量显示
pub fn add_health_box() -> Unit {
  let entity = @system.Entity::new()
  @position.positions.set(entity, @math.Vec2D(20, 20))
  let text_sprite = @sprite.Sprite::from_text(
    @sprite.Text::new("HP: 3", font="20px ThaleahFat", color="#FFFFFF"),
    UI_Z,
  )
  @sprite.sprites.set(entity, text_sprite)
  ui_entities.health_entity = entity
}

///| 更新分数显示
pub fn update_score(score : Int) -> Unit {
  let entity = ui_entities.score_entity
  if entity.is_alive() {
    let text_sprite = @sprite.Sprite::from_text(
      @sprite.Text::new("Score: " + score.to_string(), font="20px ThaleahFat", color="#FFFFFF"),
      UI_Z,
    )
    @sprite.sprites.set(entity, text_sprite)
  }
}

///| 更新血量显示
pub fn update_health(health : Int) -> Unit {
  let entity = ui_entities.health_entity
  if entity.is_alive() {
    let text_sprite = @sprite.Sprite::from_text(
      @sprite.Text::new("HP: " + health.to_string(), font="20px ThaleahFat", color="#FFFFFF"),
      UI_Z,
    )
    @sprite.sprites.set(entity, text_sprite)
  }
}

///| 添加音量按钮（简化实现）
pub fn add_volume_button() -> Unit {
  // 简化实现，暂时不添加按钮
  ()
}

///| 对话实体存储
let dialogue_entities : Array[@system.Entity] = []

///| 检查对话框是否正在显示
pub fn is_dialogue_showing() -> Bool {
  dialogue_entities.length() > 0
}

///| 显示slime死亡对话序列（史莱姆说完后，玩家说话）
pub fn show_slime_death_dialogue() -> Unit {
  // 清空队列
  dialogue_queue.clear()
  dialogue_state.current_index = 0
  dialogue_state.has_queue = true
  
  // 添加对话到队列
  dialogue_queue.push(DialogueItem::{ 
    name: "史莱姆", 
    text: "咕噜咕噜...", 
    avatar: Some(silme_idle_animation) 
  })
  dialogue_queue.push(DialogueItem::{ 
    name: "玩家", 
    text: "什么东西被碾死了...", 
    avatar: None 
  })
  
  // 显示第一段对话
  show_next_dialogue()
}

///| 显示队列中的下一段对话
pub fn show_next_dialogue() -> Unit {
  if dialogue_state.current_index < dialogue_queue.length() {
    let item = dialogue_queue[dialogue_state.current_index]
    dialogue_state.current_index = dialogue_state.current_index + 1
    show_dialogue(item.name, item.text, item.avatar)
    
    // 如果已经显示完所有对话，清空队列状态
    if dialogue_state.current_index >= dialogue_queue.length() {
      dialogue_state.has_queue = false
    }
  } else {
    // 队列结束
    dialogue_state.has_queue = false
    dialogue_state.current_index = 0
    dialogue_queue.clear()
  }
}

///| 检查是否还有对话队列
pub fn has_dialogue_queue() -> Bool {
  dialogue_state.has_queue
}

///| 清除对话
pub fn clear_dialogue() -> Unit {
  dialogue_entities.iter().each(fn(entity) {
    @system.Entity::destroy(entity)
  })
  dialogue_entities.clear()
}

///| 通用对话显示函数
///| name: 角色名字（例如："史莱姆"、"小猫"、"精灵"）
///| text: 对话内容（例如："你好，勇士！"）
///| avatar_animation: 角色头像动画（可选，传 None 则不显示头像）
pub fn show_dialogue(name : String, text : String, avatar_animation : @sprite.Animation?) -> Unit {
  clear_dialogue()
  println("🎬 显示对话：[\{name}] \{text}")

  // 获取玩家位置
  let player_pos = @position.positions.get(game_state.player).unwrap_or(@math.Vec2D(250.0, 300.0))
  println("📍 玩家位置: (\{player_pos.0[X]}, \{player_pos.0[Y]})")
  
  // 对话框显示在玩家右侧：
  // X: 玩家右侧65像素（玩家宽度约32，留点间距）
  // Y: 与玩家同高度
  let base_x = player_pos.0[X] + 65.0  // 显示在玩家右侧
  let base_y = player_pos.0[Y] + 25.0  // 再往下一点
  
  println("💬 对话框位置: (\{base_x}, \{base_y})")

  // 顶部边框（缩短）
  let top_entity = @system.Entity::new()
  @position.positions.set(top_entity, @math.Vec2D(base_x, base_y))
  let top_text = "╭────────────╮"
  let top_sprite = @sprite.Sprite::from_text(
    @sprite.Text::new(top_text, font="10px ThaleahFat", color="#222222"),
    UI_Z + 100,
  )
  @sprite.sprites.set(top_entity, top_sprite)
  dialogue_entities.push(top_entity)

  // 背景行（减少到2行）
  let bg_text = "│            │"
  for i = 0; i < 2; i = i + 1 {
    let bg_entity = @system.Entity::new()
    @position.positions.set(bg_entity, @math.Vec2D(base_x, base_y + 12.0 + i.to_double() * 12.0))
    let bg_sprite = @sprite.Sprite::from_text(
      @sprite.Text::new(bg_text, font="10px ThaleahFat", color="#F8F8FF"),
      UI_Z + 100,
    )
    @sprite.sprites.set(bg_entity, bg_sprite)
    dialogue_entities.push(bg_entity)
  }

  // 底部边框（缩短）
  let bottom_entity = @system.Entity::new()
  @position.positions.set(bottom_entity, @math.Vec2D(base_x, base_y + 36.0))
  let bottom_text = "╰────────────╯"
  let bottom_sprite = @sprite.Sprite::from_text(
    @sprite.Text::new(bottom_text, font="10px ThaleahFat", color="#222222"),
    UI_Z + 100,
  )
  @sprite.sprites.set(bottom_entity, bottom_sprite)
  dialogue_entities.push(bottom_entity)

  // 头像（如果提供）- 缩小尺寸
  match avatar_animation {
    Some(animation) => {
      let avatar_entity = @system.Entity::new()
      @position.positions.set(avatar_entity, @math.Vec2D(base_x + 4.0, base_y + 14.0))
      let avatar_sprite = @sprite.Sprite::from_animation(animation, UI_Z + 101)
      @sprite.sprites.set(avatar_entity, avatar_sprite)
      dialogue_entities.push(avatar_entity)
    }
    None => ()
  }

  // 角色名字（缩小字体）
  let name_entity = @system.Entity::new()
  @position.positions.set(name_entity, @math.Vec2D(base_x + 30.0, base_y + 14.0))
  let name_sprite = @sprite.Sprite::from_text(
    @sprite.Text::new("【\{name}】", font="9px ThaleahFat", color="#FFD700"),
    UI_Z + 102,
  )
  @sprite.sprites.set(name_entity, name_sprite)
  dialogue_entities.push(name_entity)

  // 对话文本（缩小字体和位置）
  let text_entity = @system.Entity::new()
  @position.positions.set(text_entity, @math.Vec2D(base_x + 8.0, base_y + 26.0))
  let text_sprite = @sprite.Sprite::from_text(
    @sprite.Text::new(text, font="8px ThaleahFat", color="#333333"),
    UI_Z + 102,
  )
  @sprite.sprites.set(text_entity, text_sprite)
  dialogue_entities.push(text_entity)

  println("✅ 对话框创建完成，实体数量: \{dialogue_entities.length()}")
}
