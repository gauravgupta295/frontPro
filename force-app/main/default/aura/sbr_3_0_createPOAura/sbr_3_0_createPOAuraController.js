({
    onInit: function (component, event, helper) {

    },
    handleCloseModal: function (component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
        $A.get('e.force:refreshView').fire();
    }
})