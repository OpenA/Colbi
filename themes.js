
const _PANNEL_BUTTON_W = 100;
const _PANNEL_BUTTON_H = 42;

const status_defaults = [
	"transparent",
	"darkcyan",
	"#00C963",
	"orange",
	"#cd0000",
	"slategray"
]

const light_cream = {
	inputFill   : "whitesmoke",
	inputBorder : "#ddd",
	taskListBG  : ["floralwhite", "#feeddc"],
	pannelBG    : "#fefefe",
	textDefault : "#424242",
	checkMark   : "V",

	altDark     : "#7e7e7e",
	altLight    : "#fefefe",
	textDark    : "#424242",
	textLight   : "whitesmoke",
	textColorA  : "#755151",
	textColorB  : "#4aa54a",
	status      : status_defaults
}

const dark_mary = {
	inputFill   : "#944545",
	inputBorder : "#502424",
	taskListBG  : ["#292929", "#353535"],
	pannelBG    : "#853737",
	textDefault : "#150404",
	checkMark   : "X",

	altDark     : "#5c1f1f",
	altLight    : "#853737",//"#ebe5d7",
	textDark    : "#eeeeee",
	textLight   : "#999999",
	textColorA  : "#755151",
	textColorB  : "#4aa54a",
	status      : status_defaults
}

const dark_blue = {
	background: ["#428929", "#846362"],
	status: status_defaults
}

const _COLLECTION = [
	light_cream,
	dark_mary,
	dark_blue
];
