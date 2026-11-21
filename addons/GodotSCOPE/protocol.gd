const CHANNEL: String = "debugger_pl"

const INITIALIZE: String = "initialize"
const CONFIG: String = "config"
const BATCH: String = "batch"
const ALARM: String = "alarm"

const MSG_INITIALIZE: String = CHANNEL + ":" + INITIALIZE
const MSG_BATCH: String = CHANNEL + ":" + BATCH
const MSG_ALARM: String = CHANNEL + ":" + ALARM
const MSG_CONFIG: String = CHANNEL + ":" + CONFIG

const OPERATORS: Array[String] = ["<", "<=", "==", ">=", ">"]
const OPERATOR_LABELS: Array[String] = [
    "is below (<)",
	"is below or equal (<=)",
	"is equal (==)",
	"is above or equal (>=)",
	"is above (>)",
]


static func compare(value: float, op: String, limit: float) -> bool:
    match op:
        "<":
            return value < limit
        "<=":
            return value <= limit
        "==":
            return is_equal_approx(value, limit)
        ">=":
            return value >= limit
        ">":
            return value > limit
    
    return false