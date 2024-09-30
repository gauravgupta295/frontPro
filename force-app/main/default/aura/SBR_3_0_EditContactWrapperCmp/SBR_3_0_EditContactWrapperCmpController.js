({
    handleClose: function (component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    
      
    handleScroll: function (component, event) {
        var modal = component.find("modal").getElement();
        modal.scrollTo(0, 0);
    }
})