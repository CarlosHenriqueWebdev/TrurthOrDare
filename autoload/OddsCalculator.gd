## Category-odds curve for a match.
##
## Borrowed from the reviewer's Gaussian progression. Each of four tiers
## has a peak position (mu), spread (sigma) and height (amplitude). The
## sweep parameter t ∈ [0, 1] maps round 1 → t=0 and the final round →
## t=1. At the endpoints we pin to explicit entry/exit odds; between
## them we blend the four Gaussians and normalise.
##
## Level → category mapping (fixed):
##   L1 = sober, L2 = tipsy, L3 = drunk, L4 = wasted
##
## Not a Node — pure static helpers, instantiated never.
class_name OddsCalculator extends RefCounted

const TIERS: Array[Dictionary] = [
	{"mu": 0.00, "sigma": 0.28, "amplitude": 90.0},  # L1 sober
	{"mu": 0.42, "sigma": 0.26, "amplitude": 48.0},  # L2 tipsy
	{"mu": 0.80, "sigma": 0.24, "amplitude": 56.0},  # L3 drunk
	{"mu": 1.05, "sigma": 0.25, "amplitude": 54.0},  # L4 wasted
]

const ENTRY_ODDS: Array[float] = [90.0, 6.0, 3.0, 1.0]
const EXIT_ODDS:  Array[float] = [1.0, 20.0, 40.0, 39.0]


# Returns [L1, L2, L3, L4] as percentages summing to ~100.
# `t_override` lets the caller override the sweep position directly —
# used by penalty luck to nudge difficulty without changing the round.
# Pass a negative value to use the round-derived default.
static func get_odds(current_round: int, total_rounds: int, t_override: float = -1.0) -> Array[float]:
	if total_rounds <= 1:
		return ENTRY_ODDS.duplicate()

	var t: float
	if t_override >= 0.0:
		t = clampf(t_override, 0.0, 1.0)
	else:
		t = clampf(float(current_round - 1) / float(total_rounds - 1), 0.0, 1.0)

	if is_zero_approx(t):
		return ENTRY_ODDS.duplicate()
	if is_equal_approx(t, 1.0):
		return EXIT_ODDS.duplicate()

	var raw: Array[float] = [0.0, 0.0, 0.0, 0.0]
	var total := 0.0
	for i in 4:
		var d: float = (t - float(TIERS[i]["mu"])) / float(TIERS[i]["sigma"])
		raw[i] = float(TIERS[i]["amplitude"]) * exp(-0.5 * d * d)
		total += raw[i]

	var out: Array[float] = [0.0, 0.0, 0.0, 0.0]
	for i in 4:
		out[i] = (raw[i] / total) * 100.0
	return out


# Rolls a 0-based level index from an odds array (matches LEVEL_CATEGORIES).
static func roll_level_index(odds: Array[float]) -> int:
	var roll := randf() * 100.0
	var acc := 0.0
	for i in odds.size():
		acc += odds[i]
		if roll <= acc:
			return i
	return 3
