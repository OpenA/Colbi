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

	property var statColors : {
		0: "transparent",
		1: "darkcyan",
		2: "#00C963",
		3: "#cd0000"
	};
	property var bgColors : [
		"floralwhite",
		"#feeddc"
	];

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
			var compress   = ((orig_size - new_size) / (orig_size / 100)).toFixed(1);
			var  task      = taskListModel.get(num);
			task.fileSize  = bitsMagnitude(new_size);
			task.compress  = compress.replace(".0", "") +"%";
		}
		onStatusUpdate   : {
			var  task      = taskListModel.get(num);
			task.statColor = statColors[status];
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
			color  : "#aaa"
			width  : 30
			height : 30
			radius : 5

			Text {
				anchors.centerIn: parent
				color : "#fefefe"
				text  : "+"
				font  { family: "Arial"; pointSize: 12; bold: true }
			}

			MouseArea {
				anchors.fill : parent
				hoverEnabled : true
				onEntered    : { fileButton.color = "#777" }
				onExited     : { fileButton.color = "#aaa" }
				onClicked    : { fileDialog.open()         }
			}
		}

		Rectangle {
			y      : 8
			id     : settingsButton
			color  : "#aaa"
			width  : 30
			height : 30
			radius : 5
			anchors {
				right       : parent.right
				rightMargin : 8
			}

			Text {
				anchors.centerIn: parent
				color : "#fefefe"
				text  : "S"
				font  { family: "Arial"; pointSize: 12; bold: true }
			}

			MouseArea {
				anchors.fill : parent
				hoverEnabled : true
				onEntered    : { parent.color = "#777" }
				onExited     : { parent.color = "#aaa" }
				onClicked    : { hpannel.visible ^= 1  }
			}
		}
	}

	Rectangle {
		z       : 1
		id      : hpannel
		color   : "#fefefe"
		visible : false
		anchors.fill: parent

		Button {
			id: button
			x: 0
			y: 54
			text: qsTr("Button")
		}

		Button {
			id: button1
			x: 0
			y: 8
			text: qsTr("Button")
		}


  TabBar {
	  id: tabBar
	  x: 98
	  y: 0
	  width: 542
	  height: 480
  }
  StackView {
	  id: stackView
	  x: 98
	  y: 0
	  width: 548
	  height: 480
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
						text  : model.fileSize.substring(0, model.fileSize.indexOf(" "));
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
						text  : model.fileSize.substring(model.fileSize.indexOf(" ") + 1);
						color : "#666"
						font  { family: "serif" }
					}
				}
			}
			/*Component.onCompleted: {
				taskListModel.append({
					fileName: "test.png",
					bgColor: bgColors[0],
					statColor: "transparent",
					fileSize: bitsMagnitude(480),
					compress: "99.5%"
				});
				var jpg = "teh6hh4rh646h4h646rh6426h6hh4rh4h4h646h4h64hs4hst.jpg"
				taskListModel.append({
					fileName: jpg.length > 53 ? "..."+ jpg.slice(-50) : jpg,
					bgColor: bgColors[1],
					statColor: "transparent",
					fileSize: bitsMagnitude(882465288465),
					compress: "35.0%"
				});
				var gif = "teseh6hh4rh4h4h646h4h64hseh6hh4rh4h4h646h4h64hseh6hh4rh4h4h646h4h64hseh6hh4rh4h4h646h4h64hseh6hh4rh4h4h646h4h64hst.gif"
				taskListModel.append({
					fileName: gif.length > 53 ? "..."+ gif.slice(-50) : gif,
					bgColor: bgColors[0],
					statColor: "transparent",
					fileSize: bitsMagnitude(511882465),
					compress: "78.2%"
				});
			}*/
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
}
