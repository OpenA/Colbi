
const _PANNEL_BUTTON_W = 100;
const _PANNEL_BUTTON_H = 42;
const _MARGINS_        = 8;
const _EMBEDS_COUNT    = 4;

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

const default_stat = {
	statIdle    : "transparent",
	statWorking : "orange",
	statComplete: "#00C963",
	statPaused  : "darkcyan",
	statError   : "#cd0000",
	statUnknown : "slategray"
}

const light_cream = Object.assign({
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

	selectColor : "#5500C963"
}, default_stat);

const dark_mary = Object.assign({
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

	selectColor : "gray"
}, default_stat);

const blue_ash = Object.assign({
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

	selectColor : "#4e8e9e"
}, default_stat);

const charm_green = Object.assign({
	taskListBG  : ["#f1ffde", "#e1efce"],
	pannelBG    : "#537347",
	pannelButton: "white",

	textDefault : "floralwhite",
	checkMark   : "o",

	inputFill   : "brown",
	inputBorder : "#eed",

	textColorA  : "#a44c4c",
	textColorB  : "#609501",
	textColorC  : "#313f1e",
	textColorD  : "#717f5e",

	selectColor : "#55ffaf14"
}, default_stat);

const _NamesList = ["Light Cream", "Dark Mary", "Blue Ash", "Charm Green"];
const _StyleList = [ light_cream ,  dark_mary,   blue_ash ,  charm_green ];

const genSafeName = (name = '') => {
	if(!name || name.length < 3)
		name = 'MyTheme №1';
	for (let i = 1; _NamesList.includes(name); i++)
		name = name.replace(/(?:\s([№\#\&\$\-_\@А-яA-z])?\d+)?$/, ' $1'+ i.toString());
	return name;
}

const toTextFormat = (obj_style = {}, style_name = '') => {

	const _PSTR_MAX = 12;

	let out_txt = `[${ style_name || genSafeName() }]\n`;

	for (const key in obj_style)
		out_txt += key + ' '.repeat(_PSTR_MAX - key.length) +': '+ obj_style[key] +'\n';
	return out_txt;
}

const toObjFormat = (txt_style = '') => {
	if (!/[\w]+\s*\:/.test(txt_style))
		return null;

	const out_obj  = {};
	let has_params = false;

	for (const line of txt_style.trim().split(/\s*\n\s*/g)) {
		const [key, val] = line.split(/\s*\:\s*/);
		if (key in light_cream) {
			out_obj[key] = val.includes(',') ? val.split(/\s*\,\s*/g) : val;
			has_params = true;
		}
	}
	return has_params ? out_obj : null;
}

const collectFromArray = (arr_styles = [], name = '') => {

	let obj_style = null;

	for (let i = 0; i < arr_styles.length; i++) {
		const slot = arr_styles[i].trim();
		if ( !slot ) {
			obj_style = null;
			continue;
		}
		if (!obj_style) {
			_StyleList.push(( obj_style = {} ));
			_NamesList.push(slot);
		} else {
			const [key, val] = slot.split(/\s*\:\s*/);
			if (key in light_cream)
				obj_style[key] = val.includes(',') ? val.split(/\s*\,\s*/g) : val;
		}
	}
	return _StyleList[Math.max(0, _NamesList.indexOf(name))];
}

const collectFromText = (txt_style = '', repl_idx = -1) => {

	const obj_style = toObjFormat(txt_style);

	if (!obj_style) {
		if (repl_idx >= _EMBEDS_COUNT) {
			_StyleList.splice(repl_idx, 1);
			_NamesList.splice(repl_idx, 1);
			return repl_idx - 1;
		}
		return -1;
	}
	let m    = /\[\s*(.+)\s*\]/.exec(txt_style),
		name = m ? m[1].trim() : '';

	if (repl_idx >= _EMBEDS_COUNT) {
		if (name !== _NamesList[repl_idx])
			_NamesList[repl_idx] = genSafeName(name);
		_StyleList[repl_idx] = obj_style;
	} else {
		repl_idx = _StyleList.push( obj_style ) - 1;
				   _NamesList.push( genSafeName(name) );
	}
	return repl_idx;
}
