({

    doInit: function(component, event, helper) {
       var objName = component.get("v.sObjectName");
        if(objName === "Order") {
            component.set("v.isShowdynamicRecordFormCollector", false);
        } 
    },

    handleCloseAction : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    handleModalClose: function (component, event, helper) {
        const payload = event.getParam('payload') || {};
        const closemodal = payload.closeModal;
        if (closemodal) {
            $A.get("e.force:closeQuickAction").fire();
        }
    }
})