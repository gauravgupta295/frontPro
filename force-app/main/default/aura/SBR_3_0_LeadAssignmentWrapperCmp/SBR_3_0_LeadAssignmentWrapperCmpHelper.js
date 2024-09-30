({
    handleClose : function(component, event, helper) {
        var rid = component.get("v.recordId");

        if(rid){
            var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
                "recordId": component.get("v.recordId"),
                "slideDevName": "detail"
            });
            navEvt.fire();
        }else{
            var navEvt = $A.get("e.force:navigateToObjectHome");
            navEvt.setParams({
                "scope": "Lead"
            });
            navEvt.fire();
        }
    }
})