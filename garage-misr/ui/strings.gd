## Every player-facing string, in Egyptian Arabic. One place to edit or translate.
class_name Strings
extends RefCounted

const T := {
	"play": "يلا نشتغل",
	"win": "الجراج فضي! عاش يا أسطى",
	"lose": "الجراج اتقفل!",
	"retry": "تاني؟",
	"next": "اللي بعده",
	"continue_ad": "كمّل بإعلان",
	"extreme": "جراج المعلم — صعب جدًا",
	"waiting": "مستنية عربياتها…",
	"bays_full": "الأرصفة كلها مليانة",
	"hint": "تلميح",
	"hint_wait": "استنى… العربيات طالعة",
	"level": "مرحلة %d",
	"tow": "ونش",
	"tutorial": "عم سعيد: دوس على التريلا اللي لونها عربياتها قدام البوابة",
	"speed_1": "١×",
	"speed_2": "٢×",
	"gate": "البوابة",
	"queue_empty": "—",
}


static func t(key: String) -> String:
	return T.get(key, key)
