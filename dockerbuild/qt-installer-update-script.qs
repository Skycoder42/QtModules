// http://stackoverflow.com/questions/25105269/silent-install-qt-run-installer-on-ubuntu-server

function Controller() {
    installer.autoRejectMessageBoxes();
    installer.installationFinished.connect(function() {
		if(gui.isButtonEnabled(buttons.NextButton))
			gui.clickButton(buttons.NextButton);
		else
			gui.rejectWithoutPrompt();
    });
    installer.updateFinished.connect(function() {
		if(gui.isButtonEnabled(buttons.NextButton))
			gui.clickButton(buttons.NextButton);
		else
			gui.rejectWithoutPrompt();
    });
}

// Skip the welcome page
Controller.prototype.WelcomePageCallback = function() {
    gui.clickButton(buttons.NextButton);
}

// skip the Qt Account credentials page
Controller.prototype.CredentialsPageCallback = function() {
	gui.clickButton(buttons.NextButton);
}

// select updates
Controller.prototype.IntroductionPageCallback = function() {
	var widget = gui.currentPageWidget();
	widget.findChild("UpdaterRadioButton").checked = true;
	gui.clickButton(buttons.NextButton);
}

// select the components to install
Controller.prototype.ComponentSelectionPageCallback = function() {
    var widget = gui.currentPageWidget();
    widget.selectAll();
    gui.clickButton(buttons.NextButton);
}

// accept the license agreement
Controller.prototype.LicenseAgreementPageCallback = function() {
    gui.currentPageWidget().AcceptLicenseRadioButton.setChecked(true);
    gui.clickButton(buttons.NextButton);
}

// install
Controller.prototype.ReadyForInstallationPageCallback = function() {
    gui.clickButton(buttons.NextButton);
}

Controller.prototype.FinishedPageCallback = function() {
    gui.clickButton(buttons.FinishButton);
}

