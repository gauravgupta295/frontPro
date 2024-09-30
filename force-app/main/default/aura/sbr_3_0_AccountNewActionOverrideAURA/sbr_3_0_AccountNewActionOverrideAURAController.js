({
  handleCloseTab: function (component, event, helper) {
    
      if($A.get("$Browser.formFactor") === helper.DESKTOP_BROWSER) {
          helper.handleDesktopNavigation(component, event);
      }else {
          helper.handleMobileNavigation(component, event);
      }
    
  }
});