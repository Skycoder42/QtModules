// http://stackoverflow.com/questions/25105269/silent-install-qt-run-installer-on-ubuntu-server

function Controller() {
    installer.autoRejectMessageBoxes();
    installer.installationFinished.connect(function() {
        gui.clickButton(buttons.NextButton);
    })
}

// Skip the welcome page
Controller.prototype.WelcomePageCallback = function() {
    gui.clickButton(buttons.NextButton);
}

// skip the Qt Account credentials page
Controller.prototype.CredentialsPageCallback = function() {
    gui.clickButton(buttons.NextButton);
}

// skip the introduction page
Controller.prototype.IntroductionPageCallback = function() {
    gui.clickButton(buttons.NextButton);
}

// set the installation target directory
Controller.prototype.TargetDirectoryPageCallback = function() {
    gui.currentPageWidget().TargetDirectoryLineEdit.setText("/opt/qt/");
    gui.clickButton(buttons.NextButton);
}

// select the components to install
Controller.prototype.ComponentSelectionPageCallback = function() {
    var widget = gui.currentPageWidget();
	widget.deselectAll();
	if(pfLinux)
		widget.selectComponent("qt." + qtVersion + ".gcc_64");
	if(pfAndroid) {
		widget.selectComponent("qt." + qtVersion + ".android_armv7");
		widget.selectComponent("qt." + qtVersion + ".android_x86");
	}
	widget.selectComponent("qt." + qtVersion + ".skycoder42");
    gui.clickButton(buttons.NextButton);
}

// accept the license agreement
Controller.prototype.LicenseAgreementPageCallback = function() {
    gui.currentPageWidget().AcceptLicenseRadioButton.setChecked(true);
    gui.clickButton(buttons.NextButton);
}

// leave the start menu as it is
Controller.prototype.StartMenuDirectoryPageCallback = function() {
    gui.clickButton(buttons.NextButton);
}

// install
Controller.prototype.ReadyForInstallationPageCallback = function() {
    gui.clickButton(buttons.NextButton);
}

Controller.prototype.FinishedPageCallback = function() {
    // do not launch QtCreator
    var checkBoxForm = gui.currentPageWidget().LaunchQtCreatorCheckBoxForm
    if (checkBoxForm && checkBoxForm.launchQtCreatorCheckBox) {
        checkBoxForm.launchQtCreatorCheckBox.checked = false;
    }
    gui.clickButton(buttons.FinishButton);
}

