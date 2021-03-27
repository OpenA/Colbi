import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Dialogs 1.0
import git.OpenA.Colbi 1.0
import "themes.js" as Themes

ApplicationWindow {
	id      : window
	title   : qsTr("Colbi")
	width   : 640; minimumWidth  : 640
	height  : 480; minimumHeight : 480
	visible : true

	property int curIdx  : 0
	property var glTheme : null

	color: glTheme.taskListBG[0]

	FontLoader { id: fonico; source: "lib/_Dist_/fonico.ttf" }

	function bitsMagnitude(size) {
		return (size < 1e3 ?  size +" b" :
				size < 1e6 ? (size / 1e3).toFixed(1) +" Kb" :
				size < 1e9 ? (size / 1e6).toFixed(1  + (size < 1e8 )) +" Mb" :
							 (size / 1e9).toFixed(1  + (size < 1e11)) +" Gb");
	}

	Colbi {
		id: _Colbi
		onTaskAdded      : {
			taskListModel.append({
				fileName : file_name.length > 53 ? "..."+ file_name.slice(-50) : file_name,
				fileSize : bitsMagnitude(file_size),
				statID   : status,
				compress : ""
			});
			_Colbi.runTask(num);
		}
		onTaskProgress   : {
			var compress  = (orig_size - new_size) / (orig_size / 100), p = compress < 1;
			var  task     = taskListModel.get(num);
			task.fileSize = bitsMagnitude(new_size);
			task.compress = compress.toFixed(1 + p).replace((p ? ".00" : ".0"), "") +"%";
		}
		onStatusUpdate   : {
			var task = taskListModel.get(num);
			if (!(task.statID = status)) {
				task.compress = "";
			}
		}
	}

	Rectangle {
		z       : 1
		id      : pannel
		color   : glTheme.pannelBG
		radius  : 5
		height  : 46
		border  { color: glTheme.inputBorder; width: 2 }
		anchors { right: parent.right; left: parent.left }
		Item {
			width  : 30; x : 8
			height : 30; y : 8
			Rectangle {
				id           : addFilesBtn
				color        : glTheme.textDefault
				radius       :  5
				opacity      : .6
				anchors.fill : parent
			}
			Text {
				anchors.centerIn: parent
				color : glTheme.inputFill
				text  : "+"
				font  { family: "Arial"; pointSize: 12; bold: true }
			}
			MouseArea {
				anchors.fill : parent
				hoverEnabled : true
				onEntered    : { addFilesBtn.opacity = .8 }
				onExited     : { addFilesBtn.opacity = .6 }
				onClicked    : { fileDialog.open() }
			}
		}
	}
	Item {
		width   : 30; z : 2
		height  : 30; y : 8
		anchors { right : parent.right; rightMargin : 8 }
		Rectangle {
			id           : toggleSettsBtn
			color        : glTheme.textDefault
			radius       :  5
			opacity      : .6
			anchors.fill : parent
		}
		Text {
			anchors.centerIn: parent
			color : glTheme.inputFill
			text  : "G"
			font  { family: fonico.name; pointSize: 12 }
		}
		MouseArea {
			anchors.fill : parent
			hoverEnabled : true
			onEntered    : { toggleSettsBtn.opacity = .8 }
			onExited     : { toggleSettsBtn.opacity = .6 }
			onClicked    : { sPannel.visible ^= 1 }
		}
	}

	Rectangle {
		z       : 1
		id      : sPannel
		visible : true
		color   : glTheme.pannelBG
		anchors.fill: parent

		Item {
			id      : btnsGroup
			width   : Themes._PANNEL_BUTTON_W + 16
			anchors {
				top   : parent.top
				left  : parent.left
				bottom: parent.bottom
			}
			Rectangle {
				id     : btnGeneral
				y      : 1
				width  : Themes._PANNEL_BUTTON_W
				height : Themes._PANNEL_BUTTON_H
				color  : setGeneral.visible ? "transparent" : glTheme.textDefault
				Text {
					text  : qsTr("General")
					color : setGeneral.visible ? glTheme.textDefault : glTheme.inputFill
					anchors.centerIn: parent
					font { pixelSize: 16; bold: true }
				}
				MouseArea {
					anchors.fill : parent
					onClicked    : switchPannel(0)
				}
			}
			Rectangle {
				id     : btnJPEG
				y      : Themes._PANNEL_BUTTON_H + 2
				width  : Themes._PANNEL_BUTTON_W
				height : Themes._PANNEL_BUTTON_H
				color  : setJPEG.visible ? "transparent" : glTheme.textDefault
				Text {
					text  : qsTr("JPEG")
					color : setJPEG.visible ? glTheme.textDefault : glTheme.inputFill
					anchors.centerIn: parent
					font { pixelSize: 16; bold: true }
				}
				MouseArea {
					anchors.fill : parent
					onClicked    : switchPannel(1)
				}
			}
			Rectangle {
				id     : btnPNG
				y      : Themes._PANNEL_BUTTON_H * 2 + 3
				width  : Themes._PANNEL_BUTTON_W
				height : Themes._PANNEL_BUTTON_H
				color  : setPNG.visible ? "transparent" : glTheme.textDefault
				Text {
					text  : qsTr("PNG")
					color : setPNG.visible ? glTheme.textDefault : glTheme.inputFill
					anchors.centerIn: parent
					font { pixelSize: 16; bold: true }
				}
				MouseArea {
					anchors.fill : parent
					onClicked    : switchPannel(2)
				}
			}
			Rectangle {
				id     : btnGIF
				y      : Themes._PANNEL_BUTTON_H * 3 + 4
				width  : Themes._PANNEL_BUTTON_W
				height : Themes._PANNEL_BUTTON_H
				color  : setGIF.visible ? "transparent" : glTheme.textDefault
				Text {
					text  : qsTr("GIF")
					color : setGIF.visible ? glTheme.textDefault : glTheme.inputFill
					anchors.centerIn: parent
					font { pixelSize: 16; bold: true }
				}
				MouseArea {
					anchors.fill : parent
					onClicked    : switchPannel(3)
				}
			}
			Rectangle {
				id     : btnSVG
				y      : Themes._PANNEL_BUTTON_H * 4 + 5
				width  : Themes._PANNEL_BUTTON_W
				height : Themes._PANNEL_BUTTON_H
				color  : setSVG.visible ? "transparent" : glTheme.textDefault
				visible: true
				Text {
					text  : qsTr("SVG")
					color : setSVG.visible ? glTheme.textDefault : glTheme.inputFill
					anchors.centerIn: parent
					font { pixelSize: 16; bold: true }
				}
				MouseArea {
					anchors.fill : parent
					onClicked    : switchPannel(4)
				}
			}
		}

		Item {
			id: setsGroup

			anchors {
				fill: parent
				leftMargin: Themes._PANNEL_BUTTON_W + 28
			}

			Item {
				id           : setGeneral
				visible      : true
				anchors.fill : parent

				property var params : [{
					_Param: "General/moveToTemp",
					_Title: qsTr("Move originals to temporary dir"),
					_Check: _Colbi.getParamBool("General/moveToTemp"),
					_Swith: false
				}, {
					_Param: "General/colorTheme",
					_Title: qsTr("Color Theme:"),
					_Model: ["Light Cream", "Dark Mary", "Dark Blue"],
					_Index: (() => {
						const thIdx = _Colbi.getParamInt("General/colorTheme");
						glTheme = Themes._COLLECTION[thIdx];
						return thIdx;
					})()
				}]

				Row {
					y             : 130
					height        : 40
					anchors.right : parent.right
					anchors.left  : parent.left
					Text {
						height : 32
						text   : qsTr("original_name")
						color  : glTheme.textDefault
						font { pixelSize  : 18; italic: true }
						verticalAlignment : Text.AlignVCenter
					}
					TextField {
						id               : g_name_pat
						width            : 140
						height           : 32
						font { pixelSize : 18; italic: true }
						selectByMouse    : true
						color            : glTheme.textColorA
						text             : _Colbi.getParamStr("General/namePattern")
						onEditingFinished: _Colbi.setOptionStr("General/namePattern", text)
						selectionColor   : "#55"+ glTheme.status[2].substr(1)
						background       : Rectangle {
							color        : glTheme.taskListBG[1]
						}
						MouseArea {
							anchors.fill    : parent
							cursorShape     : Qt.IBeamCursor
							acceptedButtons : Qt.RightButton
							hoverEnabled    : true
							onClicked       : showCpyMenu(g_name_pat)
							onPressAndHold  : {
								if (mouse.source === Qt.MouseEventNotSynthesized)
									showCpyMenu(g_name_pat);
							}
						}
					}
					Text {
						height : 32
						text   : qsTr(".jpg")
						color  : glTheme.textDefault
						font { pixelSize  : 18; italic: true }
						verticalAlignment : Text.AlignVCenter
					}
				}
			}
			Item {
				id           : setJPEG
				visible      : false
				anchors.fill : parent

				property int qmax : _Colbi.getParamInt("JPEG/maxQuality")

				property var params : [{
					_Param: "JPEG/progressive",
					_Title: qsTr("Progressive"),
					_Check: _Colbi.getParamBool("JPEG/progressive"),
					_Swith: false
				}, {
					_Param: "JPEG/algorithm",
					_Title: qsTr("DCT Algorithm:"),
					_Model: ["Huffman", "Arithmetic"],
					_Index: _Colbi.getParamInt("JPEG/algorithm"),
				}]

				Row {
					y             : 130
					height        : 40
					anchors.right : parent.right
					anchors.left  : parent.left
					RadioButton {
						id        : jpg_lossless
						height    : 32
						text      : qsTr("Lossless")
						checked   : setJPEG.qmax < 0
						onClicked : _Colbi.setOptionInt("JPEG/maxQuality", -(jpg_max_quality.value))
					}
					RadioButton {
						id        : jpg_lossy
						height    : 32
						text      : qsTr("Lossy")
						checked   : setJPEG.qmax > 0
						onClicked : _Colbi.setOptionInt("JPEG/maxQuality", jpg_max_quality.value)
					}
				}
				Row {
					y             : 175
					height        : 40
					anchors.right : parent.right
					anchors.left  : parent.left
					Slider {
						id             : jpg_max_quality
						height         : 32
						from           : 0
						to             : 100
						stepSize       : 1
						enabled        : jpg_lossy.checked
						value          : Math.abs(setJPEG.qmax)
						onValueChanged : _Colbi.setOptionInt("JPEG/maxQuality", value)
					}
					Text {
						height             : 32
						color              : jpg_lossy.checked ? glTheme.textDefault : glTheme.inputBorder
						text               : jpg_max_quality.value +"%"
						font   { pixelSize : 18; italic: true }
						verticalAlignment  : Text.AlignVCenter
					}
				}
			}
			Item {
				id      : setPNG
				visible : false

				property var params : [{
					_Param: "PNG/8bitColors",
					_Title: qsTr("Convert all to 8bit pallete"),
					_Check: _Colbi.getParamBool("PNG/8bitColors"),
					_Swith: false
				}]

				Row {
					y             : 140
					height        : 40
					anchors.right : parent.right
					anchors.left  : parent.left
					Text {
						height : 32
						text   : qsTr("Quantization quality:")
						font   { pixelSize: 16; italic: true }
						verticalAlignment : Text.AlignVCenter
					}
				}
				Row {
					y             : 175
					height        : 40
					anchors.right : parent.right
					anchors.left  : parent.left
					Slider {
						id             : png_min_quality
						height         : 32
						from           : 0
						to             : 100
						stepSize       : 1
						snapMode       : Slider.SnapAlways
						value          : _Colbi.getParamInt("PNG/minQuality")
						onValueChanged : _Colbi.setOptionInt("PNG/minQuality", value)
					}
					Text {
						height : 32
						color  : glTheme.textDefault
						text   : png_min_quality.value +"%"
						font   { pixelSize: 18; italic: true }
						verticalAlignment : Text.AlignVCenter
					}
				}
			}
			Item {
				id: setGIF
				visible: false

				property var params : [{
					_Param: "GIF/reColor",
					_Title: qsTr("Rebuild Colors"),
					_Check: _Colbi.getParamBool("GIF/reColor"),
					_Swith: true
				}, {
					_Param: "GIF/ditherPlan",
					_Title: qsTr("Dithering:"),
					_Index: _Colbi.getParamInt("GIF/ditherPlan"),
					_Model: [
					  "Noise", "3x3 Quads", "4x4 Quads", "8x8 Quads", "45 Deg. Lines",
					  "64x64 Quads", "Square Halftone", "Triangle Halftone", "8x8 Halftone"
					]
				}]

				Row {
					y             : 140
					height        : 40
					anchors.right : parent.right
					anchors.left  : parent.left
					enabled       : setGIF.params[0]._Check
					Text {
						height : 32
						text   : qsTr("Max Colors to Use:   ")
						font   { pixelSize: 16; italic: true }
						verticalAlignment : Text.AlignVCenter
					}
					Text {
						text: "< "; height  : 32; color: glTheme.textDefault
						font   { pixelSize  : 16; bold :  true }
						verticalAlignment   : Text.AlignVCenter
						MouseArea {
							anchors.fill    : parent
							cursorShape     : Qt.PointingHandCursor
							acceptedButtons : Qt.LeftButton
							onClicked       : gif_max_colors.decrease()
							onReleased      : { tim_h.running = false }
							onPressAndHold  : { tim_h.interval &= ~1; tim_h.running = true }
						}
					}
					Text {
						text   : (gif_max_colors.value + 1).toString()
						height : 32; width  : 32; color  : g_Select.enabled ? glTheme.textColorC : glTheme.inputBorder
						font   { pixelSize  : 18; italic :  true }
						verticalAlignment   : Text.AlignVCenter
						horizontalAlignment : Text.AlignHCenter
					}
					Text {
						text: " >"; height  : 32; color : glTheme.textDefault
						font   { pixelSize  : 16; bold  : true }
						verticalAlignment   : Text.AlignVCenter
						MouseArea {
							anchors.fill    : parent
							cursorShape     : Qt.PointingHandCursor
							acceptedButtons : Qt.LeftButton
							onClicked       : gif_max_colors.increase()
							onReleased      : { tim_h.running = false }
							onPressAndHold  : { tim_h.interval |= 1; tim_h.running = true }
						}
					}
					Timer {
						id          : tim_h
						interval    : 100
						running     : false
						repeat      : true
						onTriggered : gif_max_colors[`${interval & 1 ? 'in' : 'de'}crease`]()
					}
				}
				Row {
					y             : 175
					height        : 40
					anchors.right : parent.right
					anchors.left  : parent.left
					Slider {
						id             : gif_max_colors
						height         : 32
						from           : 1
						to             : 255
						stepSize       : 1
						snapMode       : Slider.SnapAlways
						enabled        : setGIF.params[0]._Check
						value          : _Colbi.getParamInt("GIF/maxColors")
						onValueChanged : _Colbi.setOptionInt("GIF/maxColors", value)
					}
				}
				Rectangle {
					x      : 256
					y      : 42
					width  : 130
					height : 130
					radius : 65
					color  : glTheme.inputFill
					Text {
						color : glTheme.textDefault
						text  : "lossiness\n"+ (gif_loss_quality.value / 655.35 * 100).toFixed(1) +"%"
						font  { pixelSize   : 18; italic: true }
						horizontalAlignment : Text.AlignHCenter
						verticalAlignment   : Text.AlignVCenter
						anchors.centerIn    : parent
					}
					Dial {
						id             : gif_loss_quality
						from           : 655.35
						to             : 0
						stepSize       : 0.05
						snapMode       : Dial.SnapOnRelease
						value          : _Colbi.getParamReal("GIF/lossQuality")
						onValueChanged : _Colbi.setOptionReal("GIF/lossQuality", value)
						palette { dark : glTheme.textDefault }
						anchors.fill   : parent
					}
				}
			}
			Item {
				id: setSVG
				visible: false
			}
		}
		Item {
			id           : setConstruct
			visible      : true

			anchors {
				fill: parent
				leftMargin: Themes._PANNEL_BUTTON_W + 28
			}

			Row {
				id            : g_Checkx
				y             : 20
				height        : 40
				anchors.left  : parent.left
				anchors.right : parent.right

				property string _Param : setGeneral.params[0]._Param
				property string _Title : setGeneral.params[0]._Title
				property bool   _Check : setGeneral.params[0]._Check
				property bool   _Swith : setGeneral.params[0]._Swith

				AbstractButton {
					padding    : 6
					spacing    : 6
					onClicked  : {
						g_Checkx._Check ^= 1;
						setsGroup.children[ curIdx ].params[0]._Check = g_Checkx._Check;
						_Colbi.setOptionBool(g_Checkx._Param, g_Checkx._Check);
					}
					indicator  : Rectangle {
						implicitHeight : 26
						implicitWidth  : g_Checkx._Swith ? 48 : 26
						radius         : g_Checkx._Swith ? 13 : 0
						color          : g_Checkx._Swith && g_Checkx._Check ? glTheme.textDefault : glTheme.inputFill
						border.color   : glTheme.inputBorder
						x              : parent.leftPadding
						y              : parent.height / 2 - height / 2
						Rectangle {
							x      : g_Checkx._Swith ? (g_Checkx._Check ? parent.width - 26 : 0) : 5.5
							y      : g_Checkx._Swith ? 0  : 5.5
							width  : g_Checkx._Swith ? 26 : 16
							height : g_Checkx._Swith ? 26 : 16
							radius : parent.radius
							color  : (
								g_Checkx._Swith && parent.parent.down ? glTheme.inputBorder :
								g_Checkx._Check && !glTheme.checkMark ? glTheme.textDefault : glTheme.inputFill)
							border.color: (
								g_Checkx._Swith                       ? glTheme.inputBorder : glTheme.inputFill)
							Text {
								visible : !g_Checkx._Swith && g_Checkx._Check
								text    : glTheme.checkMark
								color   : glTheme.textDefault
								font    { family : fonico.name; pixelSize: 16 }
								anchors.centerIn : parent
							}
						}
					}
					contentItem: Text {
						text  : g_Checkx._Title
						color : glTheme.textDefault
						font  { pixelSize : 18 }
						verticalAlignment : Text.AlignVCenter
						leftPadding       : parent.indicator.width + parent.spacing
					}
				}
			}
			Row {
				id            : g_Select
				y             : 75
				height        : 40
				anchors.right : parent.right
				anchors.left  : parent.left
				enabled       : g_Checkx._Swith ? g_Checkx._Check : true
				opacity       : enabled ? 1 : .5

				property string _Param : setGeneral.params[1]._Param
				property string _Title : setGeneral.params[1]._Title
				property var    _Model : setGeneral.params[1]._Model
				property int    _Index : setGeneral.params[1]._Index

				Text {
					height: 32
					text  : g_Select._Title
					color : glTheme.textDefault
					font  { pixelSize : 18 }
					verticalAlignment : Text.AlignVCenter
					rightPadding      : 10
				}
				ComboBox {
					id       : g_Select_Box
					width    : 145
					height   : 32
					model    : g_Select._Model
					delegate : ItemDelegate {
						anchors { right: parent.right; left: parent.left }
						contentItem : Text {
							text  : modelData
							color : g_Select_Box.highlightedIndex !== index ? glTheme.textDefault : glTheme.inputFill
							font  { pixelSize : 14; family: 'serif'; italic: true }
							verticalAlignment : Text.AlignVCenter
						}
						background: Rectangle {
							color : g_Select_Box.highlightedIndex === index ? glTheme.textDefault : 'transparent'
							opacity : 0.75
						}
						onClicked : {
							const target = setsGroup.children[ curIdx ].params[1];
							if (target._Index !== index) {
								_Colbi.setOptionInt(g_Select._Param, (target._Index = g_Select._Index = index));
								if (g_Select._Param === "General/colorTheme")
									glTheme = Themes._COLLECTION[index];
							}
						}
					}
					background: Rectangle {
						color        : glTheme.inputFill
						border.color : glTheme.inputBorder
					}
					indicator: Text {
						text  : "A"
						color : glTheme.textDefault
						font  { pixelSize   : 10; family: fonico.name }
						topPadding          : 11
						anchors.rightMargin : 10
						anchors.right       : parent.right
					}
					contentItem: Item {
						anchors.left        : parent.left
						anchors.leftMargin  : 10
						anchors.right       : parent.right;
						anchors.rightMargin : 30
						Text {
							anchors.fill: parent
							clip  : true
							text  : g_Select._Model[ g_Select._Index ] || ''
							color : glTheme.textDefault
							font  { pixelSize : 14; family: 'serif'; italic: true }
							verticalAlignment : Text.AlignVCenter
						}
					}
					popup: Popup {
						y       : parent.height - 1
						width   : parent.width
						padding : 1

						contentItem: ListView {
							clip  : true
							model : g_Select_Box.delegateModel
							implicitHeight: contentHeight
						}
						background: Rectangle {
							color        : glTheme.inputFill
							border.color : glTheme.inputBorder
						}
					}
				}
			}
		}
	}

	ListModel {
		id: taskListModel
	}

	ScrollView {

		ScrollBar.horizontal.policy : ScrollBar.AlwaysOff

		anchors.topMargin : pannel.height
		anchors.fill      : parent

		ListView {
			model : taskListModel

			anchors.fill  : parent

			delegate: Rectangle {
				id      : delegateModel
				color   : glTheme.taskListBG[index % 2]
				height  : 30
				anchors { right: parent.right; left: parent.left }

				Rectangle {
					y      : 1
					height : 28
					width  : 5
					color  : glTheme.status[model.statID]
				}
				Column {
					clip    : true
					padding : 5
					anchors {
						left        : parent.left
						right       : parent.right
						rightMargin : 100 + col_crn.width
						leftMargin  : 5
					}
					Text {
						text  : model.fileName
						color : glTheme.textColorC
						font  { family: "Arial" }
					}
				}
				Column {
					id: col_crn
					padding : 5
					anchors {
						right       : parent.right
						rightMargin : 98
					}
					Text {
						text  : model.compress
						color : glTheme.textColorB
						font  { family: "monospace"; italic: true }
						Text {
							anchors.left : parent.right;
							text  : model.compress ? "~" : ""
							color : parent.color
						}
					}
				}
				Column {
					padding : 5
					anchors {
						right       : parent.right;
						rightMargin : 35
					}
					Text {
						text  : model.fileSize.substring(0, model.fileSize.indexOf(" "))
						color : glTheme.textColorA
						font  { family: "monospace"  }
					}
				}
				Column {
					padding : 5
					anchors {
						right       : parent.right
						rightMargin : 0
					}
					Text {
						width : 30
						text  : model.fileSize.substring(model.fileSize.indexOf(" ") + 1)
						color : glTheme.textColorD
						font  { family: "serif" }
					}
				}
				MouseArea {
					anchors.fill    : parent
					acceptedButtons : Qt.RightButton
					onClicked       : { taskMenu.num = index; taskMenu.popup() }
					onPressAndHold  : { taskMenu.num = index;
						if (mouse.source === Qt.MouseEventNotSynthesized)
							taskMenu.popup()
					}
				}
			}
		}
	}

	FileDialog {
		id     : fileDialog
		title  : "Please choose a files"
		folder : shortcuts.home

		selectMultiple: true
		onRejected: { fileDialog.close(); }
		onAccepted: { fileDialog.close();
			makeTasks(fileDialog.fileUrls);
		}
	}

	DropArea {
		anchors.fill: parent

		property var passFiles : null;
		onExited : { passFiles = null; }
		onEntered: {
			if (drag.hasUrls) {
				passFiles = drag.urls.slice(0);
			}
		}
		onDropped: {
			if (passFiles != null) {
				makeTasks(passFiles);
				passFiles  = null;
			}
		}
	}

	function makeTasks(urls) {
		for (var i = 0; i < urls.length; i++) {
			_Colbi.addTask(
				decodeURI(urls[i].replace("file://",""))
			);
		}
	}

	Menu {
		id: cpyMenu
		property var hook: null;
		MenuItem { text: "Cut"  ; onTriggered: { cpyMenu.hook.cut()  ; cpyMenu.hook = null } }
		MenuItem { text: "Copy" ; onTriggered: { cpyMenu.hook.copy() ; cpyMenu.hook = null } }
		MenuItem { text: "Paste"; onTriggered: { cpyMenu.hook.paste(); cpyMenu.hook = null } }
	}
	Menu {
		id: taskMenu
		property int num: -1;
		MenuItem { text: "Show Store"; onTriggered: console.log("ok") }
		MenuItem { text: "Pause"     ; onTriggered: _Colbi.waitTask(taskMenu.num) }
		MenuItem { text: "Cancel"    ; onTriggered: _Colbi.killTask(taskMenu.num) }
	}

	function switchPannel(newIdx) {
		if (newIdx === curIdx)
			return;
		const oldSets = setsGroup.children[ curIdx ];
		const nexSets = setsGroup.children[ newIdx ];
		curIdx = newIdx;

		for (let i = 0; i < setConstruct.children.length; i++) {
			const row = setConstruct.children[i];
			const params = nexSets.params[i];
			if ((row.visible = Boolean(params))) {
				Object.assign(row, params);
			}
		}
		oldSets.visible = false;
		nexSets.visible = true;
	}

	function showCpyMenu(txtArea) {
		var start = txtArea.selectionStart,
		      end = txtArea.selectionEnd,
		      pos = txtArea.cursorPosition;
		cpyMenu.hook = txtArea;
		cpyMenu.popup();
		txtArea.cursorPosition = pos;
		txtArea.select(start,end);
	}
}
