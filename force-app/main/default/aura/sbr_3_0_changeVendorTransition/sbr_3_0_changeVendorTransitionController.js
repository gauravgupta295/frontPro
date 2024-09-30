({
	onInit : function(component, event, helper) {
        
        
		
	},
     //handleClose only handles closing the component if the x is hit and cancel, save will close it through the LWC using handleCloseFromLWC
    handleCloseModal : function (component, event, helper) {
        console.log("Cancel Sucess");
        $A.get("e.force:closeQuickAction").fire();
    }
})