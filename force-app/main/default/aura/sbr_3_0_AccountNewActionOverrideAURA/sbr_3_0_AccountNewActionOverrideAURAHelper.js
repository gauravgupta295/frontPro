({
  DESKTOP_BROWSER: "DESKTOP",
  MOBILE_BROWSER: "MOBILE",
  handleDesktopNavigation: function (component, event) {
    const workspaceAPI = component.find("workspaceAPI");
    const delegatorCmp = component.find("delegator");
    if (workspaceAPI) {
      workspaceAPI
        .isConsoleNavigation()
        .then((isConsole) => {
          if (isConsole) {
            this.handleConsoleNavigation(
              component,
              event,
              workspaceAPI,
              delegatorCmp
            );
          } else {
            this.handleNonConsoleNavigation(
              component,
              event,
              workspaceAPI,
              delegatorCmp
            );
          }
        })
        .catch(function (error) {
          console.log(error);
        });
    }
  },
  handleConsoleNavigation: function (
    component,
    event,
    workspaceAPI,
    delegatorCmp
  ) {
    let navigateToAccountPage = event.getParam("navigateToAccountPage");
    workspaceAPI
      .getFocusedTabInfo()
      .then(function (response) {
        var focusedTabId = response.tabId;
        console.log(focusedTabId);
        workspaceAPI.closeTab({ tabId: focusedTabId });
      })
      .catch(function (error) {
        console.log(error);
      });
    if (navigateToAccountPage) {
      delegatorCmp.navigateToPreviousPage({ replace: false });
    }
  },
  handleNonConsoleNavigation: function (
    component,
    event,
    workspaceAPI,
    delegatorCmp
  ) {
    delegatorCmp.navigateToPreviousPage();
  },
  handleMobileNavigation: function (component, event) {
    const delegatorCmp = component.find("delegator");
    delegatorCmp.navigateToPreviousPage({ replace: false });
  }
});