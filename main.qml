import QtQuick 2.14
import QtQuick.Controls 2.14
import Qt.labs.platform 1.1
import git.OpenA.Colbi 1.0
import "themes.js" as Themes

ApplicationWindow {
	id      : window
	title   : qsTr("Colbi")
	width   : 640; minimumWidth  : 640
	height  : 480; minimumHeight : 480
	visible : true

	property int curIdx  : 0
	property var glTheme : Themes.collectFromArray(
		_Colbi.loadTheme(""),
		_Colbi.getParamStr("colorTheme")
	);

	color: glTheme.taskListBG[0]

	FontLoader { id: fonico; source: "build/lib/fonico.ttf" }

	Colbi {
		id: _Colbi
		onTaskAdded      : {
			const [fileSize, sizeEx] = Themes.toPreferStr(file_size);
			taskListModel.append({
				fileName : file_name.length > 53 ? "..."+ file_name.slice(-50) : file_name,
				fileSize , sizeEx,
				statID   : Object.keys(Themes.default_stat)[status],
				compress : ""
			});
			_Colbi.runTask(num);
		}
		onTaskProgress   : {
			const task = taskListModel.get(num);
			[task.fileSize, task.sizeEx, task.compress] = Themes.toPreferStr(
				new_size, (orig_size - new_size) / (orig_size / 100)
			);
		}
		onStatusUpdate   : {
			const task = taskListModel.get(num);
			task.statID = Object.keys(Themes.default_stat)[status]
			if (!status) {
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
			width  : 30; x : Themes._MARGINS_
			height : 30; y : Themes._MARGINS_
			Rectangle {
				id           : addFilesBtn
				color        : glTheme.pannelButton
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
		height  : 30; y : Themes._MARGINS_
		anchors { right : parent.right; rightMargin : Themes._MARGINS_ }
		Rectangle {
			id           : toggleSettsBtn
			color        : glTheme.pannelButton
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
		visible : false
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
				color  : setGeneral.visible ? "transparent" : glTheme.pannelButton
				Text {
					text  : qsTr("General")
					color : setGeneral.visible ? glTheme.pannelButton : glTheme.inputFill
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
				color  : setJPEG.visible ? "transparent" : glTheme.pannelButton
				Text {
					text  : qsTr("JPEG")
					color : setJPEG.visible ? glTheme.pannelButton : glTheme.inputFill
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
				color  : setPNG.visible ? "transparent" : glTheme.pannelButton
				Text {
					text  : qsTr("PNG")
					color : setPNG.visible ? glTheme.pannelButton : glTheme.inputFill
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
				color  : setGIF.visible ? "transparent" : glTheme.pannelButton
				Text {
					text  : qsTr("GIF")
					color : setGIF.visible ? glTheme.pannelButton : glTheme.inputFill
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
				color  : setSVG.visible ? "transparent" : glTheme.pannelButton
				visible: false
				Text {
					text  : qsTr("SVG")
					color : setSVG.visible ? glTheme.pannelButton : glTheme.inputFill
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
			id: optsGroup

			anchors {
				fill: parent
				leftMargin: Themes._PANNEL_BUTTON_W + 28
			}
			Item {
				id           : setGeneral
				visible      : true
				anchors.fill : parent

				Row {
					y       : 130
					height  : 40
					anchors { left: parent.left; right : parent.right }

					Text {
						height : 32
						text   : qsTr("original_name")
						color  : glTheme.textDefault
						font { pixelSize  : 18; italic: true }
						verticalAlignment : Text.AlignVCenter
					}
					TextField {
						width            : 140
						height           : 32
						font { pixelSize : 18; italic: true }
						selectByMouse    : true
						color            : glTheme.textColorA
						text             : _Colbi.getParamStr("namePattern")
						selectionColor   : glTheme.selectColor
						background       : Rectangle {
							color        : glTheme.taskListBG[1]
						}
						onTextChanged    : {
							if (_Ext === "\n") {
								_Ext = text;
							} else {
								fin_timer.running = false;
								if (_Ext !== text) {
									fin_timer.doWork = _Func;
									fin_timer.running = true;
								}
							}
						}
						property string _Ext : "\n"
						property var   _Func : () => {
							_Colbi.setOptionStr("namePattern", (_Ext = text))
						}
						MouseArea {
							anchors.fill    : parent
							cursorShape     : Qt.IBeamCursor
							acceptedButtons : Qt.RightButton
							hoverEnabled    : true
							onClicked       : cpyMenu.showOn(parent);
							onPressAndHold  : {
								if (mouse.source === Qt.MouseEventNotSynthesized)
									cpyMenu.showOn(parent);
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

				property var irate: _Colbi.getParamInt("JPEG/maxQuality")

				Row {
					y             : 130
					height        : 40

					anchors.right : parent.right
					anchors.left  : parent.left
					RadioButton {
						id        : jpg_lossless
						height    : 32
						text      : qsTr("Lossless")
						checked   : setJPEG.irate < 0
						palette   {
							base : glTheme.inputFill;  light : glTheme.inputBorder
							mid  : glTheme.inputBorder; text : glTheme.textDefault
						}
						contentItem: Text {
							text  : parent.text
							color : glTheme.textDefault
							font  { pixelSize : 16; italic: true }
							verticalAlignment : Text.AlignVCenter
							leftPadding       : parent.indicator.width + parent.spacing
						}
						onToggled : setCurRange(setJPEG.irate > 0 ? -setJPEG.irate : setJPEG.irate, true)
					}
					RadioButton {
						id        : jpg_lossy
						height    : 32
						text      : qsTr("Quality:")
						checked   : setJPEG.irate > 0
						palette   : jpg_lossless.palette
						contentItem: Text {
							text  : parent.text
							color : jpg_lossy.checked ? glTheme.textDefault : glTheme.inputBorder
							font  { pixelSize : 16; italic: true }
							verticalAlignment : Text.AlignVCenter
							leftPadding       : parent.indicator.width + parent.spacing
						}
						onToggled : setCurRange(setJPEG.irate < 0 ? -setJPEG.irate : setJPEG.irate, true)
					}
					Text {
						height : 32
						color  : jpg_lossy.checked ? glTheme.textDefault : glTheme.inputBorder
						text   : Math.abs(setJPEG.irate) +"%"
						font   { pixelSize : 16; italic: true; bold: true }
						verticalAlignment  : Text.AlignVCenter
					}
				}
			}
			Item {
				id      : setPNG
				visible : false

				property int irate : _Colbi.getParamInt("PNG/minQuality")

				Row {
					y             : 140
					height        : 40
					anchors.right : parent.right
					anchors.left  : parent.left
					Text {
						height : 32
						color  : glTheme.textDefault
						text   : qsTr("Quantization quality:")
						font   { pixelSize : 16; italic: true }
						verticalAlignment  : Text.AlignVCenter
					}
					Text {
						height : 32
						color  : glTheme.textDefault
						text   : setPNG.irate +"%"
						font   { pixelSize : 18; italic: true; bold: true }
						leftPadding        : 10
						verticalAlignment  : Text.AlignVCenter
					}
				}
			}
			Item {
				id: setGIF
				visible: false

				property int irate : _Colbi.getParamInt("GIF/maxColors")

				Row {
					y             : 140
					height        : 40
					anchors.right : parent.right
					anchors.left  : parent.left
					opacity       : g_Select.opacity
					Text {
						height : 32
						text   : qsTr("Max Colors to Use:")
						color  : glTheme.textDefault
						font   { pixelSize : 16; italic: true }
						verticalAlignment  : Text.AlignVCenter
					}
					Text {
						text   : Math.abs(setGIF.irate)
						color  : glTheme.textDefault
						height : 32; width : 32
						font   { pixelSize : 18; italic : true; bold : true }
						horizontalAlignment: Text.AlignHCenter
						verticalAlignment: Text.AlignVCenter
						leftPadding : 20
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
						onPressedChanged : {
							if ( !pressed )
								_Colbi.setOptionReal("GIF/lossQuality", Math.round(value * 100) / 100);
						}
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
			id      : setConstruct
			visible : true

			anchors {
				fill: parent
				leftMargin: Themes._PANNEL_BUTTON_W + 28
			}

			Row {
				id      : g_Checkx
				y       : 20
				height  : 40
				anchors { left: parent.left; right : parent.right }

				property string _Title : glParams[0][0]._Title
				property bool   _Check : glParams[0][0]._Check
				property bool   _Swith : glParams[0][0]._Swith

				AbstractButton {
					padding    : 6
					spacing    : 6
					onClicked  : { glParams[ curIdx ][0]._Check = (g_Checkx._Check ^= 1) }
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
				id      : g_Select
				y       : 75
				height  : 40
				anchors { left: parent.left; right : parent.right }
				enabled : g_Checkx._Swith ? g_Checkx._Check : true
				opacity : enabled ? 1 : .5

				property string _Title : glParams[0][1]._Title
				property var    _Model : glParams[0][1]._Model
				property int    _Index : glParams[0][1]._Index

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
							const target = glParams[ curIdx ][1];
							if (target._Index !== index) {
								target._Index = g_Select._Index = index;
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
			Row {
				id      : g_Range
				y       : 175
				height  : 40
				anchors { left: parent.left; right : parent.right }
				enabled : g_Select.enabled && g_Range._Value > 0
				opacity : enabled ? 1 : .5
				visible : false

				property int _Value : 1
				property int _Maxiv : 1
				property int _Minov : 1

				Slider {
					id       : g_Range_slider
					height   : 32
					from     : g_Range._Minov
					to       : g_Range._Maxiv
					stepSize : 1
					onVisualPositionChanged: {
						if ( pressed && value !== g_Range._Value )
							setCurRange(value);
						/*setCurRange(Math.max(Math.floor(
							g_Range._Maxiv * 0.01 * g_Range_slider.visualPosition * 100
						),  g_Range._Minov));*/
					}
					onPressedChanged: {
						if ( !pressed )
							setCurRange(g_Range._Value, true);
					}
					background : Rectangle {
						x      : g_Range_slider.leftPadding
						y      : g_Range_slider.height / 2 - 2
						width  : g_Range_slider.availableWidth
						height : 4
						radius : 2
						color  : glTheme.inputFill

						border.color   : glTheme.inputBorder
						implicitWidth  : 200
						implicitHeight : 4

						Rectangle {
							width  : Math.abs(g_Range._Value / g_Range._Maxiv) * parent.width
							height : parent.height
							radius : parent.radius
							color  : glTheme.textDefault
						}
					}
					handle: Rectangle {
						x      : g_Range_slider.leftPadding + Math.abs(g_Range._Value / g_Range._Maxiv) * (g_Range_slider.availableWidth - width)
						y      : g_Range_slider.topPadding + g_Range_slider.availableHeight / 2 - radius
						color  : g_Range_slider.pressed ? glTheme.inputBorder : glTheme.inputFill
						radius : 13

						border.color   : glTheme.inputBorder
						implicitWidth  : 26
						implicitHeight : 26
					}
				}

				Text {
					padding: 5 ; text  : "<"
					height : 32; color : glTheme.textDefault
					font   { pixelSize : 16; bold: true }
					verticalAlignment  : Text.AlignVCenter
					MouseArea {
						anchors.fill    : parent
						cursorShape     : Qt.PointingHandCursor
						acceptedButtons : Qt.LeftButton
						onPressAndHold  : { g_Range_timr.interval &= ~1;  g_Range_timr.running = true }
						onReleased      : { g_Range_timr.running = false; setCurRange(g_Range._Value, true) }
						onClicked       : {
							if (g_Range._Value > g_Range._Minov)
								setCurRange(g_Range._Value - 1, true);
						}
					}
				}
				Text {
					padding: 5 ; text  : ">"
					height : 32; color : glTheme.textDefault
					font   { pixelSize : 16; bold: true }
					verticalAlignment  : Text.AlignVCenter
					MouseArea {
						anchors.fill    : parent
						cursorShape     : Qt.PointingHandCursor
						acceptedButtons : Qt.LeftButton
						onPressAndHold  : { g_Range_timr.interval |= 1;   g_Range_timr.running = true }
						onReleased      : { g_Range_timr.running = false; setCurRange(g_Range._Value, true) }
						onClicked       : {
							if (g_Range._Value < g_Range._Maxiv)
								setCurRange(g_Range._Value + 1, true);
						}
					}
				}
				Timer {
					id          : g_Range_timr
					interval    : 100
					running     : false
					repeat      : true
					onTriggered : {
						const idc = interval & 1 ? (g_Range._Value < g_Range._Maxiv) : -(g_Range._Value > g_Range._Minov);
						if (idc) setCurRange(g_Range._Value + idc);
					}
				}
			}
		}

		Item {
			visible : setGeneral.visible
			anchors {
				fill        : parent
				topMargin   : 75
				leftMargin  : Themes._PANNEL_BUTTON_W + 28
				rightMargin : Themes._MARGINS_
				bottomMargin: Themes._MARGINS_
			}
			Rectangle {
				id             : th_Editor
				anchors.fill   : parent
				implicitWidth  : g_Select.implicitWidth + 22
				implicitHeight : 250
				border.color   : glTheme.inputBorder
				visible        : false
				radius         : 5
				color          : glTheme.taskListBG[1]

				ScrollView {
					anchors.fill       : parent
					TextArea {
						id             : th_TxtArea
						color          : glTheme.textColorC
						font { family  : 'monospace'; pixelSize : 16 }
						selectionColor : glTheme.selectColor
						selectByMouse  : true
						onTextChanged  : {
							fin_timer.running = false;
							if (fin_timer.doWork !== __func) {
								fin_timer.doWork = __func;
							} else if (!visible) {
								fin_timer.doWork = null;
							} else if (/[\w]+\s*\:/.test(text))
								fin_timer.running = true;
						}
						MouseArea {
							anchors.fill    : parent
							cursorShape     : Qt.IBeamCursor
							acceptedButtons : Qt.RightButton
							hoverEnabled    : true
							onClicked       : cpyMenu.showOn(th_TxtArea)
							onPressAndHold  : {
								if (mouse.source === Qt.MouseEventNotSynthesized)
									cpyMenu.showOn(th_TxtArea);
							}
						}
						property bool modif : false
						property var __func : () => {
							glTheme = Themes.toObjFormat(text);
						}
					}
				}
			}
			Rectangle {
				x      : th_Editor.visible ? th_Editor.width - 35 : g_Select.implicitWidth + 5
				y      : th_Editor.visible ? 5 : 2
				width  : 30
				height : 30
				radius : 100
				color  : th_AddBtn.pressed ? glTheme.inputBorder : (th_Editor.visible ? glTheme.taskListBG[0] : glTheme.inputFill)
				Text {
					color   : th_AddBtn.pressed ? glTheme.textColorC : (th_Editor.visible ? glTheme.textColorB : glTheme.textDefault)
					text    : th_Editor.visible ? "V" : "+"
					font    { pixelSize : 18; family: fonico.name }
					anchors { centerIn  : parent }
				}
				MouseArea {
					id           : th_AddBtn
					anchors.fill : parent
					onClicked    : toggleStyleEditor(false)
				}
			}
			Rectangle {
				x      : th_Editor.visible ? th_Editor.width - 35 : g_Select.implicitWidth + 10 + width
				y      : th_Editor.visible ? height + 10 : 2
				visible: th_Editor.visible || g_Select._Index >= Themes._EMBEDS_COUNT
				width  : 30
				height : 30
				radius : 100
				color  : th_EditBtn.pressed ? glTheme.inputBorder : (th_Editor.visible ? glTheme.taskListBG[0] : glTheme.inputFill)
				Text {
					color   : th_EditBtn.pressed ? glTheme.textColorC : (th_Editor.visible ? glTheme.textColorA : glTheme.textDefault)
					text    : th_Editor.visible  ? "X" : "E"
					font    { pixelSize : 18; family: fonico.name }
					anchors { centerIn  : parent }
				}
				MouseArea {
					id           : th_EditBtn
					anchors.fill : parent
					onClicked    : toggleStyleEditor(true)
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
					color  : glTheme[model.statID]
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
						text  : model.fileSize
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
						text  : model.sizeEx
						color : glTheme.textColorD
						font  { family: "serif" }
					}
				}
				MouseArea {
					anchors.fill    : parent
					acceptedButtons : Qt.RightButton
					onClicked       : taskMenu.showOn(index)
					onPressAndHold  : {
						if (mouse.source === Qt.MouseEventNotSynthesized)
							taskMenu.showOn(index)
					}
				}
			}
		}
	}

	FileDialog {
		id         : fileDialog
		title      : "Please choose a files"
		folder     : StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
		fileMode   : FileDialog.OpenFiles
		options    : FileDialog.ReadOnly
		onRejected : { fileDialog.close(); }
		onAccepted : { fileDialog.close(); makeTasks(files); }
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

		property var editor : null
		property var showOn : txtA => {
			editor = txtA; open();
		}
		MenuItem {
			text        : qsTr("C&ut")
			shortcut    : StandardKey.Cut
			onTriggered : cpyMenu.editor.cut()
		}
		MenuItem {
			text        : qsTr("&Copy")
			shortcut    : StandardKey.Copy
			onTriggered : cpyMenu.editor.copy()
		}
		MenuItem {
			text        : qsTr("&Paste")
			shortcut    : StandardKey.Paste
			onTriggered : cpyMenu.editor.paste()
		}
	}
	Menu {
		id: taskMenu

		property int num    : -1
		property var showOn : idx => { num = idx; open(); }

		MenuItem { text: "Show Store"; onTriggered: console.log("ok") }
		MenuItem { text: "Pause"     ; onTriggered: _Colbi.waitTask(taskMenu.num) }
		MenuItem { text: "Cancel"    ; onTriggered: _Colbi.killTask(taskMenu.num) }
	}
	Timer {
		id: fin_timer
		interval: 1500
		property var doWork : null
		onTriggered: doWork()
	}

	property var glParams : [
		[/* Global Opts - 0 */ {
			get _Title() { return qsTr("Move originals to temporary dir") },
			get _Swith() { return false },
			get _Check() { return _Colbi.getParamBool("moveToTemp") },
			set _Check(flag) {   _Colbi.setOptionBool("moveToTemp", flag) }
		}, {
			get _Title() { return qsTr("Color Theme:") },
			get _Model() { return Themes._NamesList },
			get _Index() { return Themes._NamesList.indexOf(_Colbi.getParamStr("colorTheme")) },
			set _Index(num) {     _Colbi.setOptionStr("colorTheme", Themes._NamesList[num]);
				glTheme = Themes._StyleList[num];
			}
		}],
		[/* JPEG Opts - 1 */ {
			get _Title() { return qsTr("Progressive") },
			get _Swith() { return false },
			get _Check() { return _Colbi.getParamBool("JPEG/progressive") },
			set _Check(flag) {   _Colbi.setOptionBool("JPEG/progressive", flag) }
		}, {
			get _Title() { return qsTr("DCT Algorithm:") },
			get _Model() { return ["Huffman", "Arithmetic"] },
			get _Index() { return  _Colbi.getParamInt("JPEG/arithmetic") },
			set _Index(num) {     _Colbi.setOptionInt("JPEG/arithmetic", num) }
		}, {
			get _Maxiv() { return 100 },
			get _Value() { return  _Colbi.getParamInt("JPEG/maxQuality") },
			set _Value(rate) {   _Colbi.setOptionInt("JPEG/maxQuality", rate) }
		}],
		[/* PNG Opts - 2 */ {
			get _Title() { return qsTr("Convert all to 8bit pallete") },
			get _Swith() { return false },
			get _Check() { return _Colbi.getParamBool("PNG/rgb8bit") },
			set _Check(flag) {   _Colbi.setOptionBool("PNG/rgb8bit", flag) }
		},,{
			get _Maxiv() { return 100 },
			get _Value() { return  _Colbi.getParamInt("PNG/minQuality") },
			set _Value(rate) {    _Colbi.setOptionInt("PNG/minQuality", rate) }
		}],
		[/* GIF Opts - 3 */ {
			get _Title() { return qsTr("Rebuild Colors") },
			get _Swith() { return true },
			get _Check() { return _Colbi.getParamInt("GIF/maxColors") > 0 },
			set _Check(flag) { setCurRange(flag && 0 < setGIF.irate ? setGIF.irate : -setGIF.irate, true) }
		}, {
			get _Title() { return qsTr("Dithering:") },
			get _Model() { return [
			  "Noise", "3x3 Quads", "4x4 Quads", "8x8 Quads", "45 Deg. Lines",
			  "64x64 Quads", "Square Halftone", "Triangle Halftone", "8x8 Halftone"]},
			get _Index() { return  _Colbi.getParamInt("GIF/ditherPlan") },
			set _Index(num) {     _Colbi.setOptionInt("GIF/ditherPlan", num) }
		 }, {
			get _Maxiv() { return 256 },
			get _Minov() { return 2   },
			get _Value() { return  _Colbi.getParamInt("GIF/maxColors") },
			set _Value(rate) {    _Colbi.setOptionInt("GIF/maxColors", rate) }
		}]
	]

	function setCurRange(newVal, store = false) {
		if ( store )
			glParams[ curIdx ][2]._Value = newVal;
		optsGroup.children[ curIdx ].irate = g_Range._Value = newVal;
	}

	function switchPannel(newIdx) {
		if (newIdx === curIdx)
			return;
		const oldSets = optsGroup.children[ curIdx ];
		const nexSets = optsGroup.children[ newIdx ];
		curIdx = newIdx;

		for (let i = 0; i < setConstruct.children.length; i++) {
			const row = setConstruct.children[i];
			const params = glParams[ curIdx ][i];
			if ((row.visible = Boolean(params))) {
				Object.assign(row, params);
			}
		}
		oldSets.visible = false;
		nexSets.visible = true;
	}

	function toggleStyleEditor(xfl) {

		const gIdx    = glParams[0][1]._Index,
			 curName  = Themes._NamesList[gIdx],
			 curStyle = Themes._StyleList[gIdx];

		if ((th_Editor.visible ^= 1)) {
			th_TxtArea.text = Themes.toTextFormat(curStyle, xfl ? curName : '');
			th_TxtArea.modif = xfl;
		} else if (xfl) {
			glTheme = curStyle;
			th_TxtArea.text = '';
		} else {
			const th_style = th_TxtArea.text,
				  is_modif = th_TxtArea.modif,
				  up_index = Themes.collectFromText(th_style, is_modif ? gIdx : -1);

			if (up_index !== -1) {
				g_Select._Model = Themes._NamesList;
						glTheme = Themes._StyleList[up_index];
				g_Select._Index = glParams[0][1]._Index = up_index;
				if (is_modif)
					_Colbi.saveTheme( curName, [] );
				if (!is_modif || gIdx === up_index)
					_Colbi.saveTheme( Themes._NamesList[up_index], th_style.split('\n') );
			} else
				glTheme = curStyle;
			th_TxtArea.text = '';
		}
	}
}
