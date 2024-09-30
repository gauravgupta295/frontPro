({
    handleRetryClick : function(component, event, helper) {
        console.log('retry clicked');
		component.find('sbr_3_0_submitQuoteCmp').handleRetryClick();
	},

    handleCloseClick : function(component, event, helper) {
        console.log('close clicked');
		$A.get("e.force:closeQuickAction").fire();
        $A.get('e.force:refreshView').fire();
	},

    getValueFromLwc : function(component, event, helper) {
        console.log('value changed');
		var isCloseDisabled = event.getParam('isCloseDisabled');
        var isRetryDisabled = event.getParam('isRetryDisabled');
        //FRONT-21763: commented as these attributes are not declared in the component
        //component.set("v.isCloseDisabled", isCloseDisabled);
        //component.set("v.isRetryDisabled", isRetryDisabled);
	}
})