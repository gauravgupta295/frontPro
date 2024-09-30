({
    handleModalClose: function (component, event, helper) {
        const payload = event.getParam('payload') || {};
        const closemodal = payload.closeModal;
        if (closemodal) {
            $A.get("e.force:closeQuickAction").fire();
        }
    },
})