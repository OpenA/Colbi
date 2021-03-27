
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
	taskListBG  : ["floralwhite", "#feeddc"],
	pannelBG    : "#fefefe",

	inputFill   : "whitesmoke",
	inputBorder : "#ddd",

	textDefault : "#424242",
	checkMark   : "V",

	textColorA  : "#755151",
	textColorB  : "#4aa54a",
	textColorC  : "#424242",
	textColorD  : "#777",

	status      : status_defaults
}

const dark_mary = {
	taskListBG  : ["#292929", "#353535"],
	pannelBG    : "#853737",

	textDefault : "#150404",
	checkMark   : "X",

	inputFill   : "#944545",
	inputBorder : "#502424",

	textColorA  : "#be4e4e",
	textColorB  : "#4aa54a",
	textColorC  : "#ebe5d7",
	textColorD  : "#999",

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
