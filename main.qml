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

	function bytesMagnitude(size) {
		return (size < 1024 ? size +" b" :
				size < 1024 * 1024 ? (size / 1024).toFixed(2) +" kb" :
				size < 1024 * 1024 * 1024 ? (size / 1024 / 1024).toFixed(2) +" Mb" :
											(size / 1024 / 1024 / 1024).toFixed(2) +" Gb");
	}

	Colbi {
		id: _Colbi
		onTaskAdded      : {
			taskListModel.append({
				bgColor  : bgColors[Math.round(num / 2 % 1)],
				fileName : file_name,
				fileSize : bytesMagnitude(file_size),
				statColor: statColors[status],
				compress : "0%"
			});
			_Colbi.runTask(num);
		}
		onTaskProgress   : {
			var compress   = (new_size / orig_size * 100).toFixed(1);
			var  task      = taskListModel.get(num);
			task.fileSize  = bytesMagnitude(new_size);
			task.compress  = (compress.substr(-1) === "0" ? compress.slice(0,-2) : compress) +"%";
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
						rightMargin : 140
						leftMargin  : 5
					}
					Text {
						text  : model.fileName
						color : "#333"
						font  { family: "Arial" }
					}
				}
				Column {
					padding : 5
					anchors {
						right       : parent.right;
						rightMargin : 50
					}
					Text {
						text  : model.fileSize
						color : "#666"
						font  { family: "monospace" }
					}
				}
				Column {
					padding : 5
					anchors {
						right       : parent.right
						rightMargin : 0
					}
					Text {
						text  : model.compress
						color : "gray"
						font  { family: "monospace" }
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
}
