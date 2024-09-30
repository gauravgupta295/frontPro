({
    handleRetryClick : function(component, event, helper) {
        console.log('retry clicked');
		component.find('sbr_3_0_QuoteRateRefresh').handleRetryClick();
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
        component.set("v.isCloseDisabled", isCloseDisabled);
        component.set("v.isRetryDisabled", isRetryDisabled);
	}
})