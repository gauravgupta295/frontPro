({
    handleCancel: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire(); // Close the quick action modal
    },
    handleModalClose: function (component, event, helper) {
        var urlEvent = $A.get("e.force:navigateToURL"); //FRONT-31112 navigate to homepage.
        urlEvent.setParams({
            "url": "/home/home.jsp"
        });
        urlEvent.fire();
    }
  
})