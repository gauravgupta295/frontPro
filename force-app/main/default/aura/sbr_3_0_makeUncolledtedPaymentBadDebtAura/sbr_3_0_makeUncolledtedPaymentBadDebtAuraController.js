({
    handlePaymentClick: function(component, event, helper) {
        component.set("v.isModalOpen", true);
    },
    handleModalClose: function (component, event, helper) {
        const payload = event.getParam('payload') || {};
        const closemodal = payload.closeModal;
        if (closemodal) {
            component.set("v.isModalOpen", false);
        }
    },
    checkDeviceType: function(component, event, helper) {
        var isMobile = window.matchMedia("(max-width: 480px)").matches;
        component.set("v.isMobile", isMobile);
    }
})