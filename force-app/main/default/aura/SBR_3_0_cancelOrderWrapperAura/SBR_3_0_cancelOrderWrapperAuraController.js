({
	fetchRecordData: function(component, event, helper) {
        var props = { recordId :  component.get("v.recordId"),
                    //recordTypeName : component.get("v.record").RecordType.Name,
                    recordTypeId : component.get("v.record").RecordTypeId,
                    fromRecordPage : true
                    };
        component.set("v.props", props);
        component.set("v.initChild", true);
        
    },


    closemodal : function() {
        $A.get("e.force:closeQuickAction").fire();
        $A.get("e.force:refreshView").fire();// FRONT - 20094
    }
})