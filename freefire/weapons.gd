extends RefCounted

# n: nomi, s: turi (ar, smg, lmg, sniper, shotgun, pistol)
# dmg: zarar, rate: otish oraligi (s), mag: magazin, rl: zaryad (s)
# spread: sochilish, pel: oq soni (drobovik), head: bosh koeffitsiyenti
# range: samarali masofa (m), recoil: kamera tepishi, rc: qurol modeli tepishi, price: narxi
const W := [
	{"n": "M4A1", "s": "ar", "dmg": 53, "rate": 0.11, "mag": 30, "rl": 1.7, "spread": 0.012, "pel": 1, "head": 2.0, "range": 65.0, "recoil": 0.010, "rc": 0.55, "price": 1000},
	{"n": "AK47", "s": "ar", "dmg": 61, "rate": 0.13, "mag": 30, "rl": 1.9, "spread": 0.018, "pel": 1, "head": 2.0, "range": 70.0, "recoil": 0.016, "rc": 0.70, "price": 1100},
	{"n": "SCAR", "s": "ar", "dmg": 55, "rate": 0.12, "mag": 30, "rl": 1.8, "spread": 0.012, "pel": 1, "head": 2.0, "range": 70.0, "recoil": 0.011, "rc": 0.60, "price": 1000},
	{"n": "MP5", "s": "smg", "dmg": 38, "rate": 0.07, "mag": 30, "rl": 1.5, "spread": 0.024, "pel": 1, "head": 1.8, "range": 35.0, "recoil": 0.008, "rc": 0.35, "price": 600},
	{"n": "UMP", "s": "smg", "dmg": 42, "rate": 0.08, "mag": 30, "rl": 1.5, "spread": 0.020, "pel": 1, "head": 1.8, "range": 40.0, "recoil": 0.009, "rc": 0.40, "price": 650},
	{"n": "VECTOR", "s": "smg", "dmg": 34, "rate": 0.05, "mag": 35, "rl": 1.6, "spread": 0.030, "pel": 1, "head": 1.8, "range": 30.0, "recoil": 0.007, "rc": 0.30, "price": 700},
	{"n": "M1887", "s": "shotgun", "dmg": 12, "rate": 0.9, "mag": 2, "rl": 1.3, "spread": 0.050, "pel": 8, "head": 1.6, "range": 12.0, "recoil": 0.040, "rc": 2.00, "price": 800},
	{"n": "SPAS12", "s": "shotgun", "dmg": 11, "rate": 0.7, "mag": 8, "rl": 2.0, "spread": 0.045, "pel": 8, "head": 1.6, "range": 14.0, "recoil": 0.030, "rc": 1.60, "price": 750},
	{"n": "AWM", "s": "sniper", "dmg": 90, "rate": 1.3, "mag": 5, "rl": 2.3, "spread": 0.001, "pel": 1, "head": 2.5, "range": 140.0, "recoil": 0.040, "rc": 2.20, "price": 2000},
	{"n": "KAR98K", "s": "sniper", "dmg": 90, "rate": 1.1, "mag": 5, "rl": 2.1, "spread": 0.002, "pel": 1, "head": 2.2, "range": 120.0, "recoil": 0.035, "rc": 2.00, "price": 1500},
	{"n": "M249", "s": "lmg", "dmg": 55, "rate": 0.09, "mag": 100, "rl": 3.6, "spread": 0.020, "pel": 1, "head": 1.8, "range": 80.0, "recoil": 0.012, "rc": 0.50, "price": 1600},
	{"n": "USP", "s": "pistol", "dmg": 30, "rate": 0.22, "mag": 12, "rl": 1.1, "spread": 0.012, "pel": 1, "head": 2.0, "range": 35.0, "recoil": 0.020, "rc": 0.80, "price": 0},
	{"n": "DESERT EAGLE", "s": "pistol", "dmg": 62, "rate": 0.6, "mag": 7, "rl": 1.6, "spread": 0.010, "pel": 1, "head": 1.8, "range": 45.0, "recoil": 0.050, "rc": 1.50, "price": 700},
]
