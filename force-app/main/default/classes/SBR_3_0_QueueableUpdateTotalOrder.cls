public with sharing class SBR_3_0_QueueableUpdateTotalOrder implements Queueable, Database.AllowsCallouts {
    private Set<Id> orderRecId;
    public SBR_3_0_QueueableUpdateTotalOrder(Set<Id> orderId) {
        this.orderRecId = orderId;
    }
    public void execute(QueueableContext context) {
        if(orderRecId != null && orderRecId.size()>0 ){
            for(Id currentId :orderRecId )
            {
                SBR_3_0_API_ReservationSourcingCall.callSource(currentId);
            }
        }
    }
}