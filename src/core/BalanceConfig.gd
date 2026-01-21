extends RefCounted
class_name BalanceConfig
## 数值平衡配置
## 集中管理所有游戏平衡相关的数值

# ========== 等级成长 ==========
const LEVEL_MAX = 50

static func get_exp_required(level: int) -> int:
	"""计算升级所需经验"""
	if level <= 1:
		return 0
	return int(100 * pow(level, 1.5))

# 属性成长率
const GROWTH_RATES = {
	"hp": 40,
	"mp": 8,
	"attack": 4,
	"defense": 3,
	"magic": 4,
	"magic_defense": 3,
	"speed": 2,
	"luck": 1
}

static func calculate_stat(base: int, growth_rate: int, level: int) -> int:
	return base + (growth_rate * (level - 1)) + int(pow(level - 1, 1.1))

# ========== 战斗平衡 ==========
const BATTLE_TURNS = {
	"normal": 3,
	"elite": 6,
	"boss": 12
}

# ========== 经济平衡 ==========
const DAILY_INCOME = {
	"early": 300,
	"mid": 1000,
	"late": 2500
}

const DAYS_FOR_BIG_PURCHASE = 3

# ========== 夜袭平衡 ==========
const RAID_CHANCE = {
	"normal": 0.15,
	"full_moon": 0.50,
	"story": 1.0
}

const NEWBIE_PROTECTION_DAYS = 7
const NEWBIE_RAID_CHANCE = 0.05

static func calculate_raid_difficulty(day: int, player_power: float, defense_value: float) -> float:
	"""计算夜袭难度"""
	var base_difficulty = 10.0 + (day * 2.0)
	
	var power_ratio = player_power / base_difficulty if base_difficulty > 0 else 1.0
	if power_ratio > 1.5:
		base_difficulty *= 1.3
	elif power_ratio < 0.7:
		base_difficulty *= 0.8
	
	var effective_difficulty = base_difficulty - (defense_value * 0.5)
	return maxf(effective_difficulty, 5.0)

static func should_raid_occur(day: int, is_full_moon: bool = false) -> bool:
	"""判断是否发生夜袭"""
	var chance = RAID_CHANCE["normal"]
	
	if day <= NEWBIE_PROTECTION_DAYS:
		chance = NEWBIE_RAID_CHANCE
	elif is_full_moon:
		chance = RAID_CHANCE["full_moon"]
	
	return randf() < chance
