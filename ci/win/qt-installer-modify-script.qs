// http://stackoverflow.com/questions/25105269/silent-install-qt-run-installer-on-ubuntu-server

function Controller() {
    installer.autoRejectMessageBoxes();
    installer.installationFinished.connect(function() {
    	gui.clickButton(buttons.FinishButton);
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
	widget.findChild("PackageManagerRadioButton").checked = true;
	gui.clickButton(buttons.NextButton);
}

// select the components to install
Controller.prototype.ComponentSelectionPageCallback = function() {
	var widget = gui.currentPageWidget();
	if(image == "Visual Studio 2017") {
		if(pfWin32)
			widget.selectComponent("qt." + qtVersion + ".win64_msvc2017_64");
		if(pfWinrt) {
			widget.selectComponent("qt." + qtVersion + ".win64_msvc2017_winrt_armv7");
			widget.selectComponent("qt." + qtVersion + ".win64_msvc2017_winrt_x64");
			widget.selectComponent("qt." + qtVersion + ".win64_msvc2017_winrt_x86");
		}
	}
	if(image == "Visual Studio 2015") {
		if(pfWin32) {
			widget.selectComponent("qt." + qtVersion + ".win64_msvc2015_64");
			widget.selectComponent("qt." + qtVersion + ".win32_msvc2015");
			widget.selectComponent("qt." + qtVersion + ".win32_mingw53");
		}
	}
	widget.selectComponent("qt." + qtVersion + ".skycoder42");
	
	if(gui.isButtonEnabled(buttons.NextButton))
		gui.clickButton(buttons.NextButton);
	else
		gui.rejectWithoutPrompt();
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

