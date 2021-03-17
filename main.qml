import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Dialogs 1.0
import git.OpenA.Colbi 1.0

ApplicationWindow {
	id      : window
	title   : qsTr("Colbi")
	width   : 640; minimumWidth  : 640
	height  : 480; minimumHeight : 480
	visible : true
	color   : "floralwhite"

	property var statColors : [
		"transparent",
		"darkcyan",
		"#00C963",
		"orange",
		"#cd0000",
		"#9e9e9e"
	];
	property var bgColors : [
		"floralwhite",
		"#feeddc"
	];

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
				bgColor  : bgColors[Math.round(num / 2 % 1)],
				fileName : file_name.length > 53 ? "..."+ file_name.slice(-50) : file_name,
				fileSize : bitsMagnitude(file_size),
				statColor: statColors[status],
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
			var  task      = taskListModel.get(num);
			task.statColor = statColors[status];
			if (!status) {
				task.compress = "";
			}
		}
	}

	Rectangle {
		z       : 1
		id      : pannel
		color   : "#fefefe"
		radius  : 5
		height  : 46
		border  { color: "#ddd"; width: 2 }
		anchors { right: parent.right; left: parent.left }

		Rectangle {
			x      : 8
			y      : 8
			id     : fileButton
			color  : "#888"
			width  : 30
			height : 30
			radius : 5

			Text {
				anchors.centerIn: parent
				color : "whitesmoke"
				text  : "+"
				font  { family: "Arial"; pointSize: 12; bold: true }
			}

			MouseArea {
				anchors.fill : parent
				hoverEnabled : true
				onEntered    : { fileButton.color = "#444" }
				onExited     : { fileButton.color = "#888" }
				onClicked    : { fileDialog.open()         }
			}
		}
	}

	Rectangle {
		z      : 2
		y      : 8
		id     : settingsButton
		color  : "#888"
		width  : 30
		height : 30
		radius : 5
		anchors {
			right       : parent.right
			rightMargin : 8
		}

		Text {
			anchors.centerIn: parent
			color : "whitesmoke"
			text  : "G"
			font  { family: fonico.name; pointSize: 12 }
		}

		MouseArea {
			anchors.fill : parent
			hoverEnabled : true
			onEntered    : { parent.color = "#444" }
			onExited     : { parent.color = "#888" }
			onClicked    : { sPannel.visible ^= 1  }
		}
	}

	property int sPANNEL_BTN_WIDTH  : 100
	property int sPANNEL_BTN_HEIGHT : 42

	Rectangle {
		z       : 1
		id      : sPannel
		visible : true
		color   : "#fefefe"
		anchors.fill: parent

		property int selectIdx : 0

		Item {
			id: btnsGroup
			clip : true
			width: sPANNEL_BTN_WIDTH + 16
			anchors {
				top   : parent.top
				left  : parent.left
				bottom: parent.bottom
			}
			Rectangle {
				id: btnGeneral
				y: 2
				width: sPANNEL_BTN_WIDTH
				height: sPANNEL_BTN_HEIGHT
				color: "#fefefe"
				Text {
					text: qsTr("General")
					anchors.centerIn: parent
					font { pixelSize: 16; bold: true }
				}
				MouseArea {
					anchors.fill : parent
					onClicked    : switchPannel(0, sPannel.selectIdx)
				}
			}
			Rectangle {
				id: btnJPEG
				y      : 45
				width  : sPANNEL_BTN_WIDTH
				height : sPANNEL_BTN_HEIGHT
				color  : "#444"
				Text {
					text  : qsTr("JPEG")
					color : "whitesmoke"
					anchors.centerIn: parent
					font { pixelSize: 16; bold: true }
				}
				MouseArea {
					anchors.fill : parent
					onClicked    : switchPannel(1, sPannel.selectIdx)
				}
			}
			Rectangle {
				id: btnPNG
				y: 88
				width: sPANNEL_BTN_WIDTH
				height: sPANNEL_BTN_HEIGHT
				color: "#444"
				Text {
					text  : qsTr("PNG")
					color : "whitesmoke"
					anchors.centerIn: parent
					font { pixelSize: 16; bold: true }
				}
				MouseArea {
					anchors.fill : parent
					onClicked    : switchPannel(2, sPannel.selectIdx)
				}
			}
			Rectangle {
				id: btnGIF
				y: 131
				width: sPANNEL_BTN_WIDTH
				height: sPANNEL_BTN_HEIGHT
				color: "#444"
				Text {
					text  : qsTr("GIF")
					color : "whitesmoke"
					anchors.centerIn: parent
					font { pixelSize: 16; bold: true }
				}
				MouseArea {
					anchors.fill : parent
					onClicked    : switchPannel(3, sPannel.selectIdx)
				}
			}
			Rectangle {
				id: btnSVG
				y: 166
				width: sPANNEL_BTN_WIDTH
				height: sPANNEL_BTN_HEIGHT
				color: "#444"
				visible: false
				Text {
					text  : qsTr("SVG")
					color : "whitesmoke"
					anchors.centerIn: parent
					font { pixelSize: 16; bold: true }
				}
				MouseArea {
					anchors.fill : parent
					onClicked    : switchPannel(4, sPannel.selectIdx)
				}
			}
		}

		Item {
			id: setsGroup

			anchors {
				fill: parent
				leftMargin: sPANNEL_BTN_WIDTH + 28
			}

			Item {
				id           : setGeneral
				visible      : true
				anchors.fill : parent

				Row {
					y             : 20
					height        : 40
					anchors.right : parent.right
					anchors.left  : parent.left
					CheckBox {
					//	id               : g_moveToTemp
						text             : qsTr("Move originals to temporary dir")
						font { pixelSize : 18 }
						checked          : _Colbi.getParamBool("General/moveToTemp")
						nextCheckState   : _Colbi.setOptionBool("General/moveToTemp", checked)
					}
				}
				Row {
					y             : 75
					height        : 40
					anchors.right : parent.right
					anchors.left  : parent.left
					Text {
						verticalAlignment : Text.AlignVCenter
						font.pixelSize    : 18
						height            : 32
						text              : qsTr("Color Theme:  ")
					}
					ComboBox {
						height                : 32
						model                 : ["Light Cream", "Dark Brown", "Dark Blue"]
						currentIndex          : _Colbi.getParamInt("General/colorTheme")
						onCurrentIndexChanged : _Colbi.setOptionInt("General/colorTheme", currentIndex)
					}
				}
				Row {
					y             : 130
					height        : 40
					anchors.right : parent.right
					anchors.left  : parent.left
					Text {
						height            : 32
						text              : qsTr("original_name")
						font { pixelSize  : 18; italic: true }
						verticalAlignment : Text.AlignVCenter
					}
					TextField {
						id               : g_name_pat
						width            : 140
						height           : 32
						font { pixelSize : 18; italic: true }
						selectByMouse    : true
						placeholderText  : qsTr("__optimized__")
						text             : _Colbi.getParamStr("General/namePattern")
						onEditingFinished: _Colbi.setOptionStr("General/namePattern", text)
						selectionColor   : statColors[3]
						background       : Rectangle {
							border.color : statColors[5]
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
						height            : 32
						text              : qsTr(".jpg")
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

				Row {
					y             : 20
					height        : 40
					anchors.right : parent.right
					anchors.left  : parent.left
					CheckBox {
					//	id               : jpg_Progressive
						text             : qsTr("Progressive")
						font { pixelSize : 18 }
						checked          : _Colbi.getParamBool("JPEG/progressive")
						nextCheckState   : _Colbi.setOptionBool("JPEG/progressive", checked)
					}
				}
				Row {
					y             : 75
					height        : 40
					anchors.right : parent.right
					anchors.left  : parent.left
					Text {
						verticalAlignment : Text.AlignVCenter
						font.pixelSize    : 18
						height            : 32
						text              : qsTr("DCT Algorithm:  ")
					}
					ComboBox {
						height                : 32
						model                 : ["Huffman", "Arithmetic"]
						currentIndex          : _Colbi.getParamBool("JPEG/arithmetic")
						onCurrentIndexChanged : _Colbi.setOptionBool("JPEG/arithmetic", Boolean(currentIndex))
					}
				}
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
						color              : "gray"
						text               : jpg_max_quality.value +"%"
						font   { pixelSize : 18; italic: true }
						verticalAlignment  : Text.AlignVCenter
					}
				}
			}
			Item {
				id      : setPNG
				visible : false

				Row {
					y             : 20
					height        : 40
					anchors.right : parent.right
					anchors.left  : parent.left
					CheckBox {
					//	id               : png_8bit_colors
						text             : qsTr("Convert all to 8bit pallete")
						font { pixelSize : 18 }
						checked          : _Colbi.getParamBool("PNG/8bitColors")
						nextCheckState   : _Colbi.setOptionBool("PNG/8bitColors", checked)
					}
				}
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
						color  : "gray"
						text   : png_min_quality.value +"%"
						font   { pixelSize: 18; italic: true }
						verticalAlignment : Text.AlignVCenter
					}
				}
			}
			Item {
				id: setGIF
				visible: false

				Row {
					y             : 20
					height        : 40
					anchors.right : parent.right
					anchors.left  : parent.left
					Switch {
						id        : gif_recolor
						text      : qsTr("Rebuild Colors")
						font      { pixelSize: 18 }
						checked   : _Colbi.getParamBool("GIF/reColor")
						onClicked : _Colbi.setOptionBool("GIF/reColor", checked)
					}
				}
				Row {
					y             : 75
					height        : 40
					anchors.right : parent.right
					anchors.left  : parent.left
					Text {
						verticalAlignment : Text.AlignVCenter
						font.pixelSize    : 18
						height            : 32
						text              : qsTr("Dithering:  ")
					}
					ComboBox {
						height                : 32
						enabled               : gif_recolor.checked
						currentIndex          : _Colbi.getParamInt("GIF/ditherPlan")
						onCurrentIndexChanged : _Colbi.setOptionInt("GIF/ditherPlan", currentIndex)
						model                 : [
						  "Noise", "3x3 Quads", "4x4 Quads", "8x8 Quads", "45 Deg. Lines",
						  "64x64 Quads", "Square Halftone", "Triangle Halftone", "8x8 Halftone"
						]
					}
				}
				Row {
					y             : 140
					height        : 40
					anchors.right : parent.right
					anchors.left  : parent.left
					enabled       : gif_recolor.checked
					Text {
						height : 32
						text   : qsTr("Max Colors to Use:   ")
						font   { pixelSize: 16; italic: true }
						verticalAlignment : Text.AlignVCenter
					}
					Text {
						text: "< "; height  : 32; color: "black"
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
						height : 32; width  : 32; color  : statColors[5 - gif_recolor.checked]
						font   { pixelSize  : 18; italic :  true }
						verticalAlignment   : Text.AlignVCenter
						horizontalAlignment : Text.AlignHCenter
					}
					Text {
						text: " >"; height  : 32; color : "black"
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
						enabled        : gif_recolor.checked
						value          : _Colbi.getParamInt("GIF/maxColors")
						onValueChanged : _Colbi.setOptionInt("GIF/maxColors", value)
					}
				}
				Dial {
					id             : gif_loss_quality
					x              : 256
					y              : 42
					width          : 130
					height         : 130
					from           : 655.35
					to             : 0
					stepSize       : 0.05
					snapMode       : Dial.SnapOnRelease
					value          : _Colbi.getParamReal("GIF/lossQuality")
					onValueChanged : _Colbi.setOptionReal("GIF/lossQuality", value)
					Text {
						color : "gray"
						text  : "lossiness\n"+ (gif_loss_quality.value / 655.35 * 100).toFixed(1) +"%"
						font  { pixelSize   : 18; italic: true }
						horizontalAlignment : Text.AlignHCenter
						verticalAlignment   : Text.AlignVCenter
						anchors.centerIn    : parent
					}
				}
			}
			Item {
				id: setSVG
				visible: false
			}
		}
	}

	function switchPannel(newIdx, oldIdx) {
		if (newIdx === oldIdx)
			return;
		const oldBtn = btnsGroup.children[oldIdx];
		const oldSet = setsGroup.children[oldIdx];
		const newBtn = btnsGroup.children[newIdx];
		const newSet = setsGroup.children[newIdx];
		oldBtn.children[0].color = "whitesmoke"; newBtn.color = "#fefefe";
		newBtn.children[0].color = oldBtn.color = "#444";
		oldSet.visible = false;
		newSet.visible = true;
		sPannel.selectIdx = newIdx;
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
				color   : model.bgColor
				height  : 30
				anchors { right: parent.right; left: parent.left }

				Rectangle {
					y      : 1
					height : 28
					width  : 5
					color  : model.statColor
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
						color : "#333"
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
						color : "#4aa54a"
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
						color : "#755151"
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
						color : "#666"
						font  { family: "serif" }
					}
				}
				MouseArea {
					anchors.fill    : parent
					acceptedButtons : Qt.RightButton
					onClicked       : taskMenu.popup()
					onPressAndHold  : {
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
		MenuItem { text: "Pause"     ; onTriggered: _Colbi.waitTask(index) }
		MenuItem { text: "Cancel"    ; onTriggered: _Colbi.killTask(index) }
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
