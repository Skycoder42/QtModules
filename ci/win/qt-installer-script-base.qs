// http://stackoverflow.com/questions/25105269/silent-install-qt-run-installer-on-ubuntu-server

function Controller() {
    installer.autoRejectMessageBoxes();
    installer.installationFinished.connect(function() {
		gui.clickButton(buttons.NextButton, 1000);
    })
}

// Skip the welcome page
Controller.prototype.WelcomePageCallback = function() {
	gui.clickButton(buttons.NextButton, 3000);
}

// skip the Qt Account credentials page
Controller.prototype.CredentialsPageCallback = function() {
	gui.clickButton(buttons.NextButton, 1000);
}

// skip the introduction page
Controller.prototype.IntroductionPageCallback = function() {
	gui.clickButton(buttons.NextButton, 1000);
}

// set the installation target directory
Controller.prototype.TargetDirectoryPageCallback = function() {
	gui.currentPageWidget().TargetDirectoryLineEdit.setText("C:/projects/Qt");
	gui.clickButton(buttons.NextButton, 1000);
}

// select the components to install
Controller.prototype.ComponentSelectionPageCallback = function() {
    var widget = gui.currentPageWidget();
	widget.deselectAll();
	widget.selectComponent(prefix + qtVersion + "." + platform);
	extraMods.forEach(function(element){
		if(element.startsWith("."))
			element = prefix + qtVersion + element;
		widget.selectComponent(element);
	});

	gui.clickButton(buttons.NextButton, 1000);
}

// accept the license agreement
Controller.prototype.LicenseAgreementPageCallback = function() {
    gui.currentPageWidget().AcceptLicenseRadioButton.setChecked(true);
	gui.clickButton(buttons.NextButton, 1000);
}

// leave the start menu as it is
Controller.prototype.StartMenuDirectoryPageCallback = function() {
	gui.clickButton(buttons.NextButton, 1000);
}

// install
Controller.prototype.ReadyForInstallationPageCallback = function() {
	gui.clickButton(buttons.NextButton, 1000);
}

Controller.prototype.FinishedPageCallback = function() {
    // do not launch QtCreator
    var checkBoxForm = gui.currentPageWidget().LaunchQtCreatorCheckBoxForm
    if (checkBoxForm && checkBoxForm.launchQtCreatorCheckBox) {
        checkBoxForm.launchQtCreatorCheckBox.checked = false;
    }
    gui.clickButton(buttons.FinishButton, 1000);
}

