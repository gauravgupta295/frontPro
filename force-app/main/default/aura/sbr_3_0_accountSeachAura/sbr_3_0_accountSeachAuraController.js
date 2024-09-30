({
  handleCloseTab: function (component, event, helper) {
    
      if($A.get("$Browser.formFactor") === helper.DESKTOP_BROWSER) {
          helper.handleDesktopNavigation(component, event);
      }else {
          helper.handleMobileNavigation(component, event);
      } 
  },
    handleSetTabName: function (cmp, event, helper) {
    let flowName = event.getParam("tabName");
     console.log('calleventhandler');
    let workspaceAPI = cmp.find("workspaceAPI");
    if (workspaceAPI) {
      workspaceAPI
        .isConsoleNavigation()
        .then((isConsole) => {
          if (isConsole) {
            return workspaceAPI.getFocusedTabInfo();
          }
        })
        .then(function (response) {
          let focusedTabId = response.tabId;
          workspaceAPI.setTabLabel({
            tabId: focusedTabId,
            label: flowName
          });
        })
        .then(function (response) {
          workspaceAPI.setTabIcon({
            icon: "standard:default"
          });
        })
        .catch(function (error) {
          console.log(error);
        });
    }
  }
});