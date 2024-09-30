({
    getValueFromLwc : function(component, event, helper) {
		let isCancelClicked = event.getParam('isCancelClicked');
        if(isCancelClicked){ 
            $A.get("e.force:closeQuickAction").fire();
        }       
	},
})