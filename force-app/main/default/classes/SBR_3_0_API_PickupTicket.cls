/**
 * @description       : Helper class to create Pickup Tickets
 * @group             : 
 * @last modified on  : 02-07-2024
 * @last modified by  : Hashem Abdul
**/
public without sharing class SBR_3_0_API_PickupTicket {
    private static final String APINAME = 'PickupTicket_API';

    /**
    * @description Make API Call to create Pickup Ticket
    * @param pickupDetails 
    * @return String 
    **/
    @AuraEnabled(cacheable=false)
    public static String getPickupTicketNumberNew(String pickupDetails) {
        try {
            PickupDetails pickupDetailsWrp = (PickupDetails)JSON.deserialize(pickupDetails, PickupDetails.class); 
            String apiResponse;
            SBR_3_0_PickupTicketRequestWrap requestWrapper = new SBR_3_0_PickupTicketRequestWrap();
            requestWrapper.channel = 'SLSFRC';
            requestWrapper.updateMode = 'C';
            //Date pickupDate = Date.valueOf(pickupDetailsWrp.pickupDate);
            Datetime pickupDate = (DateTime)JSON.deserialize('"' +pickupDetailsWrp.pickupDate+ '"', DateTime.class);
            requestWrapper.pickupDateTime =GMTPickupRequestDate(pickupDate);
            System.debug('\n pickup datetime GMTx = ' + requestWrapper.pickupDateTime);
            SBR_3_0_Log.logInfo('\n pickup datetime GMTx = ' + requestWrapper.pickupDateTime );
            requestWrapper.pickupComment = pickupDetailsWrp.comments;
            User reqByUser;
            if(String.isNotBlank(pickupDetailsWrp.requestedById)){
                reqByUser = SBR_3_0_UserDA.getUserById(pickupDetailsWrp.requestedById);
                SBR_3_0_Log.setRelatedRecordId(pickupDetailsWrp.requestedById);
                requestWrapper.pickupRequestedBy = reqByUser.lastName + ', ' + reqByUser.firstName;
            }
            requestWrapper.equipment = new List<SBR_3_0_PickupTicketRequestWrap.Equipment>();
            Set<String> lineItemIds = new Set<String>();
            Set<String> assetNumbers = new Set<String>();
            Map<String, Equipment> equipmentsToOrderItemMap = new Map<String, Equipment>();
            for(Equipment eq : pickupDetailsWrp.equipments) {
                equipmentsToOrderItemMap.put(eq.lineItemId, eq);
                lineItemIds.add(eq.lineItemId);
                assetNumbers.add(eq.equipmentNumber);
                SBR_3_0_PickupTicketRequestWrap.Equipment eqpWrap = new SBR_3_0_PickupTicketRequestWrap.Equipment();
                eqpWrap.number_Z = eq.equipmentNumber; // This is marked as number which is reserved
                eqpWrap.quantity = eq.quantity; 
                requestWrapper.equipment.add(eqpWrap);
            }

            Map<Id,OrderItem> ois = new Map<Id,OrderItem>(SBR_3_0_OrderItemDA.getOrderItem(lineItemIds));
            Map<String, Asset> assets = SBR_3_0_AssetDA.getAssetsByNumbers(assetNumbers);
            if(!ois.isEmpty()) {
                OrderItem ordItm = ois.values()[0];
                String companyId = ordItm.Order.Account.Company_Code__c;
                requestWrapper.contractNumber = ordItm.Order.Contract_Order_Number__c;
                if(ordItm.Order.Sourcing_Branch__c != null) {
                    requestWrapper.timezone = ordItm.Order.Sourcing_Branch__r.Time_Zone_Id__c;
                }
                else if(ordItm.Order.Branch__c != null)
                {
                    requestWrapper.timezone = ordItm.Order.Branch__r.Time_Zone_Id__c; 
                }

                String body = JSON.serializePretty(requestWrapper);
                body = body.replace('number_Z', 'number');
                body = body.replace('null', '\"\"');
                system.debug('Request: ');
                system.debug(body);
                apiResponse = SBR_3_0_Generic_Callout.callEndpoint(body, APINAME, companyId);
                SBR_3_0_Log.logAPIDetails(body,apiResponse,APINAME);
                SBR_3_0_PickupTicketResponseWrap apiRespWrapper = (SBR_3_0_PickupTicketResponseWrap)JSON.deserialize(apiResponse, SBR_3_0_PickupTicketResponseWrap.class); 
                if(String.isNotBlank(apiRespWrapper?.Data?.pickupTicketNumber)){
                    // Create Order Item Details
                    CreateOrderItemDetails(pickupDetailsWrp, ois, equipmentsToOrderItemMap, assets, reqByUser, apiRespWrapper);
                    //BD
                    updatePickupQty(pickupDetailsWrp.equipments,ois);
                }
            }
            return apiResponse;
        } catch (Exception ex) {
            SBR_3_0_Log.logException(ex);
            throw new AuraHandledException(ex.getMessage() + ' | ' + ex.getStackTraceString());

        }finally{
            SBR_3_0_Log.saveLog();
         }
    }
    //BD
    
    public static void updatePickupQty(List<Equipment> equipmentList,Map<Id,OrderItem> orderItemMap)
    {
            List<OrderItem> orderItemList = new List<OrderItem>();
            OrderItem currentOrder;
            OrderItem updatedOrderItem;
            for(Equipment currentEquipment : equipmentList)
            {
                if(!orderItemMap.keySet().isEmpty() &&  orderItemMap.containsKey(currentEquipment.lineItemId) )
                {
                    currentOrder = orderItemMap.get(currentEquipment.lineItemId) ;
                    if(currentOrder.Product2.Bulk_Item__c && !currentOrder.Product2.IsSerialized)
                    {
                        updatedOrderItem = new OrderItem();
                        updatedOrderItem.Id = currentOrder.Id;
                        System.debug('$$'+updatedOrderItem);
                        SBR_3_0_Log.logInfo('updatedOrderItem' + updatedOrderItem );
                        updatedOrderItem.Status_Pick_Created_Qty__c = Integer.valueOf(currentEquipment.quantity);
                       /* if(currentOrder.Status_Pick_Created_Qty__c !=null &&  currentOrder.Status_Pick_Created_Qty__c>0)
                        {
                                           updatedOrderItem.Status_Pick_Created_Qty__c = currentOrder.Status_Pick_Created_Qty__c +Integer.valueOf(currentEquipment.quantity);

                        }
                        else {
                            	          updatedOrderItem.Status_Pick_Created_Qty__c = Integer.valueOf(currentEquipment.quantity);
                        }*/
                        orderItemList.add(updatedOrderItem);
                    }
                }
            }
            if(orderItemList!=null && orderItemList.size()>0)
            {
                Database.update(orderItemList);
            }
    }
    /**
    * @description Created Pickup Ticket for Order Item
    * @author Hashem Abdul | 02-07-2024 
    * @param pickupDtls 
    * @param orderItems 
    * @param eqpmntsMap 
    * @param assets 
    * @param loggedInUser 
    * @param pickupResp 
    **/
    public static void CreateOrderItemDetails(PickupDetails pickupDtls, Map<Id, OrderItem> orderItems, Map<String, Equipment> eqpmntsMap,  Map<String, Asset> assets, User loggedInUser, SBR_3_0_PickupTicketResponseWrap pickupResp){
        List<Order_Item_Detail__c> ordItmsToCreate = new List<Order_Item_Detail__c>();
        for(OrderItem ordItm: orderItems.values()){
            Order_Item_Detail__c OID = new Order_Item_Detail__c();
            OID.Name = ordItm.Id+'_OID';
            OID.Pickup_Ticket__c = pickupResp.Data.pickupTicketNumber;
            OID.Order_Item_Comments__c = pickupDtls.comments;
            //Time t = Time.newInstance(0, 0, 0, 0);
            Datetime pickupDate = (DateTime)JSON.deserialize('"' +pickupDtls.pickupDate+ '"', DateTime.class);
            OID.Pickup_Requested_Date__c = pickupDate;
            OID.Pickup_Ticket_Request_By__c = loggedInUser?.Name; //13808
            //OID.Pickup_Ticket_Requested_By__c = loggedInUser?.Id;
            OID.Line_Item__c=ordItm.Id;
            if (ordItm.Is_Bulk_Item__c && ordItm.SBQQ__Asset__c <> NULL){
                OID.Asset_Number__c = ordItm.SBQQ__Asset__c;
            }
            if(ordItm.Global_Line_Number__c != null){
                OID.OMS_Order_ID__c = OID.Pickup_Ticket__c+'-'+ordItm.Global_Line_Number__c;
            }

            if(!eqpmntsMap.isEmpty() && eqpmntsMap.containsKey(ordItm.Id) && eqpmntsMap.get(ordItm.Id) <> NULL){
                OID.Created_Qty__c = Integer.valueOf(eqpmntsMap.get(ordItm.Id).quantity);
            }

            ordItmsToCreate.add(OID);
        }

        insert ordItmsToCreate;

        for(Order_Item_Detail__c ordItmDtl: ordItmsToCreate){
            OrderITem ordItm = orderItems.get(ordItmDtl.Line_Item__c);
            ordItm.Order_Item_Detail__c = ordItmDtl.Id;
        }
        update orderItems.values();
    }

    private static String GMTPickupRequestDate(Datetime requestedDate) {
        

        String frmtted = requestedDate.formatGMT(SBR_3_0_Constants.INT_DATE_FORMAT);
        return frmtted;
    }

    public class PickupDetails {
        @AuraEnabled
        public String pickupDate {get; set;}
        @AuraEnabled
        public String requestedById {get;set;}
        @AuraEnabled
        public String comments {get;set;}
        @AuraEnabled
        public List<Equipment> equipments {get;set;}
    }

    public class Equipment {
        @AuraEnabled
        public String quantity {get;set;}
        @AuraEnabled
        public String equipmentNumber {get;set;}
        @AuraEnabled
        public String lineItemId {get;set;}
    }    
}