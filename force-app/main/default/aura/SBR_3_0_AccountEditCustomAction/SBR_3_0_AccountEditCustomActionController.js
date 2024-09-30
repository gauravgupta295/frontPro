({
    /** FRONT-3227, FRONT-3225 */
    fetchRecordData: function(component, event, helper) {
        var props = { recordId :  component.get("v.recordId"),
                    recordTypeName : component.get("v.record").RecordType.Name,
                    recordTypeId : component.get("v.record").RecordTypeId,
                    fromRecordPage : true
                    };
        component.set("v.props", props);
        component.set("v.initChild", true);
        
    },

    closemodal : function() {
        $A.get("e.force:closeQuickAction").fire();
    }


})