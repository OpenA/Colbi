
const _PANNEL_BUTTON_W = 100;
const _PANNEL_BUTTON_H = 42;

const light_cream = {
	background  : ["floralwhite", "#feeddc"],
	altDark     : "#7e7e7e",
	altLight    : "#fefefe",
	textDark    : "#424242",
	textLight   : "whitesmoke",
	textColorA  : "#755151",
	textColorB  : "#4aa54a",
	status      : [
		"transparent",
		"darkcyan",
		"#00C963",
		"orange",
		"#cd0000",
		"slategray"
	]
}

const dark_brown = {
	background: ["#292929", "#353535"],
	status: light_cream.status
}

const dark_blue = {
	background: ["#428929", "#846362"],
	status: light_cream.status
}

const _COLLECTION = [
	light_cream,
	dark_brown,
	dark_blue
];
