
const _PANNEL_BUTTON_W = 100;
const _PANNEL_BUTTON_H = 42;

const toPreferStr = (size = 0, rate = 0) => [`${
	size < 1e3  ? size : // ~ 320 b
	size < 1e4  ? Math.floor(size / 1e1) / 100 : // ~ 7.23  Kb
	size < 1e6  ? Math.floor(size / 1e2) / 10  : // ~ 640.5 Kb
	size < 1e7  ? Math.floor(size / 1e4) / 100 : // ~ 1.52  Mb
	size < 1e9  ? Math.floor(size / 1e5) / 10  : // ~ 48.3  Mb
	size < 1e11 ? Math.floor(size / 1e7) / 100 : // ~ 12.54 Gb
	/* >= 100Gb */Math.floor(size / 1e8) / 10
}`, `${
	size < 1e3 ? '' : size < 1e6 ? 'K' : size < 1e9 ? 'M' : 'G'
}b`, `${
	!rate || rate === 100 ? Math.floor(rate) : Math.round(rate * (rate < 1 ? 100 : 10)) / (rate < 1 ? 100 : 10)
}%`];

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
	pannelButton: "#777",

	inputFill   : "whitesmoke",
	inputBorder : "#ddd",

	textDefault : "#424242",
	checkMark   : "V",

	textColorA  : "#755151",
	textColorB  : "#4aa54a",
	textColorC  : "#424242",
	textColorD  : "#777",

	taskStatus  : status_defaults
}

const dark_mary = {
	taskListBG  : ["#292929", "#353535"],
	pannelBG    : "#853737",
	pannelButton: "#150404",

	textDefault : "#150404",
	checkMark   : "X",

	inputFill   : "#944545",
	inputBorder : "#502424",

	textColorA  : "#be4e4e",
	textColorB  : "#4aa54a",
	textColorC  : "#ebe5d7",
	textColorD  : "#999",

	taskStatus  : status_defaults
}

const blue_ash = {
	taskListBG  : ["#212830", "#2b333b"],
	pannelBG    : "#273a56",
	pannelButton: "#96a4a3",

	textDefault : "#718f89",
	checkMark   : "",

	inputFill   : "#324354",
	inputBorder : "#4b5b6b",

	textColorA  : "#927908",
	textColorB  : "#608660",
	textColorC  : "#cecece",
	textColorD  : "#617eb2",

	taskStatus  : status_defaults
}

const _COLLECTION = [
	light_cream,
	dark_mary,
	blue_ash
];
