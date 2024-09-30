public with sharing class SBR_3_0_QueueableUpdateRelatedOrder implements Queueable {
    private String orderRecdId;
    private String reservationId;
    

    public SBR_3_0_QueueableUpdateRelatedOrder(String orderRecdId, String reservationId) {
        this.orderRecdId = orderRecdId;
        this.reservationId = reservationId;
    }

    public void execute(QueueableContext context) {
        if(orderRecdId != null){
            List<Order> contractsToUpdate = new List<Order>();
            for(Order o:[Select id from Order Where id =: orderRecdId FOR UPDATE]) {
                o.Reservation_Order__c = reservationId;
                contractsToUpdate.add(o);
            }
            if(!contractsToUpdate.isEmpty()) {
                update contractsToUpdate;
            }
            /*
            Order contract = new Order(
                Id = orderRecdId,
                Reservation_Order__c = reservationId
                );
            update contract; */
        }
    }
}