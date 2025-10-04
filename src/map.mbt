///|
fn tile_to_vec2d(tile : @tilemap.Tile, tile_size : Int) -> @math.Vec2D {
  @math.Vec2D(
    tile.x.to_double() * tile_size.to_double(),
    tile.y.to_double() * tile_size.to_double(),
  )
}

///|
struct UnknownBlock {
  entity : @system.Entity
  original_pos : @math.Vec2D
  mut is_moving : Bool
  mut move_timer : Double
  mut current_phase : Int // 0=原位, 1=向上移动, 2=停留, 3=向下移动
}

///|
let unknown_blocks : Map[@system.Entity, UnknownBlock] = Map::new()

///|
let coins : Map[@system.Entity, Bool] = Map::new()  // 存储所有金币实体

fn add_Unknown(pos : @math.Vec2D, sprite_id : String) -> Unit {
  let src_pos: @math.Vec2D = match sprite_id {
    "43" => @math.Vec2D(16.0 * 4, 16.0 * 5)
    "44" => @math.Vec2D(16.0 * 3, 16.0 * 5)
    _ => panic()
  }
  let sprite = @sprite.Sprite::from_animation(
    @sprite.Animation::single_frame(
      "sprite_fusion/spritesheet.png",
      @math.Vec2D(16.0, 16.0),
      offset=src_pos,
    ),
    10,
  )
  let unknown = @system.Entity::new()
  @sprite.sprites.set(unknown, sprite)
  @position.positions.set(unknown, pos)
  // 移除碰撞体积 - Unknown blocks 现在是装饰性的
  
  // 注册到Unknown块管理系统
  unknown_blocks[unknown] = UnknownBlock::{
    entity: unknown,
    original_pos: pos,
    is_moving: false,
    move_timer: 0.0,
    current_phase: 0
  }
}

fn add_platform(pos : @math.Vec2D, sprite_id : String) -> Unit {
  let src_pos: @math.Vec2D = match sprite_id {
    "27" => @math.Vec2D(16.0 * 3, 3 * 16.0)
    "28" => @math.Vec2D(16.0 * 4, 3 * 16.0)
    _ => panic()
  }
  let sprite = @sprite.Sprite::from_animation(
    @sprite.Animation::single_frame(
      "sprite_fusion/spritesheet.png",
      @math.Vec2D(16.0, 16.0),
      offset=src_pos,
    ),
    10,
  )
  let platform = @system.Entity::new()
  @sprite.sprites.set(platform, sprite)
  @position.positions.set(platform, pos)
  // 移除碰撞体积 - Platform 现在是装饰性的
}

///|
fn add_grass(pos : @math.Vec2D, sprite_id : String) -> Unit {
  let src_pos = match sprite_id {
    "45" => @math.Vec2D(16.0 * 5, 16.0 * 5)
    "46" => @math.Vec2D(16.0 * 6, 16.0 * 5)
    _ => panic()
  }
  let sprite = @sprite.Sprite::from_animation(
    @sprite.Animation::single_frame(
      "sprite_fusion/spritesheet.png",
      @math.Vec2D(16.0, 16.0),
      offset=src_pos,
    ),
    10,
  )
  let grass = @system.Entity::new()
  @sprite.sprites.set(grass, sprite)
  @position.positions.set(grass, pos)
  @collision.shapes.set(
    grass,
    Rect(size=@math.Vec2D(16.0, 4.0), offset=@math.Vec2D(0.0, 0.0)),
  )
  @collision.collision_layers.set(grass, terrain_collision_layer)
}

///|
fn add_coin(pos : @math.Vec2D) -> Unit {
  let coin = @system.Entity::new()
  let coin_sprite = @sprite.Sprite::from_animation(
    @sprite.Animation::new(
      @sprite.frames_from_atlas(
        "asserts1/Coin/coin.png",
        12,
        width=16.0,
        height=16.0,
      ),
      loop_=true,
      fps=12,
    ),
    20,
  )
  @sprite.sprites.set(coin, coin_sprite)
  @position.positions.set(coin, pos)
  @collision.shapes.set(
    coin,
    Rect(size=@math.Vec2D(16.0, 16.0), offset=@math.Vec2D::zero()),
  )
  
  // 将金币添加到集合中，等待玩家按E拾取
  coins[coin] = true
}

///|
pub fn try_pickup_coin() -> Unit {
  // 如果没有金币，直接返回
  if coins.is_empty() {
    return
  }
  
  let player_pos = @position.positions.get(game_state.player).unwrap_or(@math.Vec2D::zero())
  let coins_to_remove : Array[@system.Entity] = []
  
  // 遍历所有金币，检查是否在拾取范围内
  coins.iter().each(fn(entry) {
    let coin = entry.0
    if @position.positions.contains(coin) {
      let coin_pos = @position.positions.get(coin).unwrap_or(@math.Vec2D::zero())
      
      // 只计算X方向的距离
      let dx = coin_pos.0[X] - player_pos.0[X]
      let distance_x = if dx < 0.0 { -dx } else { dx }
      
      // 拾取范围50像素
      if distance_x <= 50.0 {
        // 增加分数
        set_score(game_state.score + 10)
        // 播放音效
        @audio.play_audio("sounds/coin.wav")
        // 销毁金币
        @system.Entity::destroy(coin)
        // 标记从集合中移除
        coins_to_remove.push(coin)
      }
    }
  })
  
  // 从集合中移除已收集的金币
  coins_to_remove.iter().each(fn(coin) { coins.remove(coin) })
}

fn add_sand(pos : @math.Vec2D, sprite_id : String) -> Unit {
  let src_pos: @math.Vec2D = match sprite_id {
    "30" => @math.Vec2D(16.0 * 6, 3 * 16.0)
    "31" => @math.Vec2D(16.0 * 7, 3 * 16.0)
    _ => panic()
  }
  let sprite = @sprite.Sprite::from_animation(
    @sprite.Animation::single_frame(
      "sprite_fusion/spritesheet.png",
      @math.Vec2D(16.0, 16.0),
      offset=src_pos,
    ),
    10,
  )
  let sand = @system.Entity::new()
  @sprite.sprites.set(sand, sprite)
  @position.positions.set(sand, pos)
  @collision.shapes.set(
    sand,
    Rect(size=@math.Vec2D(16.0, 16.0), offset=@math.Vec2D::zero()),
  )
  @collision.collision_layers.set(sand, terrain_collision_layer)
}

fn add_trees(pos : @math.Vec2D, sprite_id : String) -> Unit {
  let src_pos: @math.Vec2D = match sprite_id {
    "32" => @math.Vec2D(16.0 * 0, 4 * 16.0)
    "33" => @math.Vec2D(16.0 * 1, 4 * 16.0)
    "34" => @math.Vec2D(16.0 * 2, 4 * 16.0)
    "35" => @math.Vec2D(16.0 * 3, 4 * 16.0)
    "36" => @math.Vec2D(16.0 * 4, 4 * 16.0)
    "37" => @math.Vec2D(16.0 * 5, 4 * 16.0)
    "38" => @math.Vec2D(16.0 * 6, 4 * 16.0)
    "39" => @math.Vec2D(16.0 * 7, 4 * 16.0)
    "40" => @math.Vec2D(16.0 * 0, 5 * 16.0)
    "41" => @math.Vec2D(16.0 * 1, 5 * 16.0)
    "42" => @math.Vec2D(16.0 * 2, 5 * 16.0)
    _ => panic()
  }
  let sprite = @sprite.Sprite::from_animation(
    @sprite.Animation::single_frame(
      "sprite_fusion/spritesheet.png",
      @math.Vec2D(16.0, 16.0),
      offset=src_pos,
    ),
    10,
  )
  let trees = @system.Entity::new()
  @sprite.sprites.set(trees, sprite)
  @position.positions.set(trees, pos)
  // trees 不需要碰撞体积，只是装饰
}

fn add_stone(pos : @math.Vec2D, sprite_id : String) -> Unit {
  let src_pos: @math.Vec2D = match sprite_id {
    "20" => @math.Vec2D(16.0 * 4, 2 * 16.0)
    "21" => @math.Vec2D(16.0 * 5, 2 * 16.0)
    "22" => @math.Vec2D(16.0 * 6, 2 * 16.0)
    "23" => @math.Vec2D(16.0 * 7, 2 * 16.0)
    "24" => @math.Vec2D(16.0 * 0, 3 * 16.0)
    "25" => @math.Vec2D(16.0 * 1, 3 * 16.0)
    "26" => @math.Vec2D(16.0 * 2, 3 * 16.0)
    _ => panic()
  }
  let sprite = @sprite.Sprite::from_animation(
    @sprite.Animation::single_frame(
      "sprite_fusion/spritesheet.png",
      @math.Vec2D(16.0, 16.0),
      offset=src_pos,
    ),
    10,
  )
  let stone = @system.Entity::new()
  @sprite.sprites.set(stone, sprite)
  @position.positions.set(stone, pos)
  @collision.shapes.set(
    stone,
    Rect(size=@math.Vec2D(16.0, 16.0), offset=@math.Vec2D::zero()), 
  )
  @collision.collision_layers.set(stone, terrain_collision_layer)
}

///|
fn generate_map() -> Unit {
  let tilemap = @tilemap.TileMap::from_json(tilemap)
  let world_width = tilemap.map_width.to_double() * tilemap.tile_size.to_double()
  let world_height = tilemap.map_height.to_double() * tilemap.tile_size.to_double()
  
  // 背景装饰图片已移除
  
  @camera.set_limits(top=0.0, bottom=world_height, left=0.0, right=world_width)
  
  // 生成玩家
  let role = tilemap.get_tiles_first("Role")[0]
  let player_pos = tile_to_vec2d(role, tilemap.tile_size)
  add_player(player_pos)
  println("👤 玩家位置: \{player_pos}")
  
  // 生成地形
  let grasses = tilemap.get_tiles("Grass")
  for grass in grasses {
    add_grass(tile_to_vec2d(grass, tilemap.tile_size), grass.id)
  }
  
  let stones = tilemap.get_tiles("Stone")
  for stone in stones {
    add_stone(tile_to_vec2d(stone, tilemap.tile_size), stone.id)
  }
  
  let sands = tilemap.get_tiles("Sand")
  for sand in sands {
    add_sand(tile_to_vec2d(sand, tilemap.tile_size), sand.id)
  }
  
  let platforms = tilemap.get_tiles("Platform")
  for platform in platforms {
    add_platform(tile_to_vec2d(platform, tilemap.tile_size), platform.id)
  }
  
  let trees = tilemap.get_tiles("Trees")
  for tree in trees {
    add_trees(tile_to_vec2d(tree, tilemap.tile_size), tree.id)
  }
  
  let unknowns = tilemap.get_tiles("Unknown")
  for unknown in unknowns {
    add_Unknown(tile_to_vec2d(unknown, tilemap.tile_size), unknown.id)
  }
  
  // 生成金币
  let coin_tiles = tilemap.get_tiles("Coin")
  for coin in coin_tiles {
    add_coin(tile_to_vec2d(coin, tilemap.tile_size))
  }
  
  // 生成敌人 - 临时将它们放在玩家附近便于测试
  let olders = tilemap.get_tiles("Older")
  if !olders.is_empty() {
    let pos = tile_to_vec2d(olders[0], tilemap.tile_size)
    println("👴 添加 Older，放在 stone 上面")
    add_Older(@math.Vec2D(pos[X] + 200.0, 400.0 - 96.0))  // 400是stone的Y位置，96是Older的高度
  }

  let sprites_tiles = tilemap.get_tiles("Sprites")
  if !sprites_tiles.is_empty() {
    let pos = tile_to_vec2d(sprites_tiles[0], tilemap.tile_size)
    println("🎭 添加 Sprite (飞行精灵)，原始位置: \{pos}，调整到空中")
    add_sprite(@math.Vec2D(180.0, 50.0), "Hello!")  // 飞在空中，Y=50，在 slime 右上方
  } else {
    println("⚠️ 地图中没有找到 Sprites 图层")
  }

  let mushrooms = tilemap.get_tiles("Mushroom")
  if !mushrooms.is_empty() {
    let pos = tile_to_vec2d(mushrooms[0], tilemap.tile_size)
    println("🍄 添加 Mushroom，原始位置: \{pos}，调整到 slime 附近")
    add_mushroom(@math.Vec2D(120.0, 0.0))  // 放在 slime 左边，从顶部落下
  } else {
    println("⚠️ 地图中没有找到 Mushroom 图层")
  }

  let slimes = tilemap.get_tiles("Slime")
  if !slimes.is_empty() {
    // 把 slime 放在草地上 (y=5的位置，也就是80像素，让它自由落下)
    add_silme(@math.Vec2D(150.0, 0.0))  // 从顶部落下，重力会让它站在 grass 上
  }

  let cats = tilemap.get_tiles("Cat")
  if !cats.is_empty() {
    // 从地图中读取 Cat 的位置并添加
    let pos = tile_to_vec2d(cats[0], tilemap.tile_size)
    println("🐱 添加 Cat，原始位置: \{pos}")
    // 把 cat 放在玩家右侧 80 像素的位置
    add_cat(@math.Vec2D(player_pos[X] + 80.0, player_pos[Y]))
  } else {
    println("⚠️ 地图中没有找到 Cat 图层")
  }
}