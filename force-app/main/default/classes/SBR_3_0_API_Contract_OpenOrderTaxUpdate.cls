/**
 * @description This class is called by the CreateOrder API (Custom Apex REST Service... e.g. SBR_3_0_CreateOrder)
 * As well as a lightnign web component on the Order page / Order Items related list.
 * This class calls out to the contract details API through Mulesoft over to Rentalman,
 * and then sets the tax results on the order / order item records.
 * @author Who knows
 * @date Also, who knows
 * @lastmodified 3/20 for order optimization
 */
public with sharing class SBR_3_0_API_Contract_OpenOrderTaxUpdate {

    private static final String APINAME = 'Contracts';
    private static final String COMPANY_ID = '01';
    private static final String X_CORRELATION_ID = SBR_3_0_Generic.generateRandomString(10);
    private static final String OPEN_STATUS = 'Open Rental';
    private static WrapOrderResponse wrapOrderResp = new WrapOrderResponse();

    /**
     * @description Invoked by the LWC to update order item tax information
     */
    @AuraEnabled
    public static OrderWrapper updateOrderItemTaxes(String recordId){
        
        if(!Schema.sObjectType.OrderItem.isCreateable() ||
            !Schema.sObjectType.OrderItem.isUpdateable() ||
            !Schema.sObjectType.Order.isCreateable() ||
           !Schema.sObjectType.Order.isUpdateable()){
            //For AuraHandled exceptions, you have to call the setMessage method on it explicity for odd reasons.
            String message = 'Insufficent permissions on Order or Order Item records. Need create and update access on both objects to continue.';
            AuraHandledException insufficientEx = new AuraHandledException(message);
            insufficientEx.setMessage(message);
            throw insufficientEx;
        }
        
        String relatedToId;
        
        try{

            List<Order>  orders = SBR_3_0_OrderDA.getOrderDtlsForTotalTaxUpdate(recordId);
            
            if(orders == null || orders.isEmpty()){
                return  new OrderWrapper();
            }
    
            Order orderRecd = orders[0];
            
            Map<String,OrderItem> orderItemMap = new Map<String,OrderItem>();
            for(OrderItem oi : orderRecd.OrderItems){
                if(String.isEmpty(oi.Line_Composite_Key__c)){
                    orderItemMap.put(oi.Line_Composite_Key__c, oi);
                }
            }
            
            OrderWrapper result = updateOrderAndOrderItemTaxes(orderRecd, orderItemMap);
            
            //This order / order items came over from the "SBR_3_0_CreateOrder" class, and we should create the order, regardless
            //of an exception occuring.
            upsert orderRecd Id;
            
            for(OrderItem oi : orderItemMap.values()){
                oi.OrderId = orderRecd.Id;
            }
            
            upsert orderItemMap.values() Line_Composite_Key__c;
            
            return result;
        }catch(Exception ex){
            //For AuraHandled exceptions, you have to call the setMessage method on it explicity for odd reasons.
            AuraHandledException auraEx = new AuraHandledException(ex.getMessage());
            auraEx.setMessage(ex.getMessage());
            throw auraEx;
        }
    }
    
    /**
     * @description Called by SBR_3_0_CreateOrder, and also the related method above,
     * to do the actual callout logic and setting the tax values on both the order and order items.
     * If a callout exception happens (e.g. API times out), it should be caught and logged as a Exception_Log__c record.
     * @param order - The order for which taxes should be calculated
     * @param orderItemMap A map of order item's line_composite_key__c field to order items, used to 
     * lookup tax results and set tax information on the order items.
     * @return An instance of orderwrapper.
     */
    public static OrderWrapper updateOrderAndOrderItemTaxes(Order order, Map<String,OrderItem> orderItemMap){

        OrderWrapper orderWrapped = new OrderWrapper();
        orderWrapped.isValidOrderRecord = 'N';
        orderWrapped.orderNumber = order.OrderNumber;
        orderWrapped.seqNum = '0';
        orderWrapped.companyId = order.Company_Code__c;
        
        boolean isContractOrder = (order.RecordTypeId == Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Contract_Order').getRecordTypeId());
        if((order.Status != 'Cancelled Reservation' || order.Status != 'Filled' ) && !String.isBlank(order.Reservation_Order_Number__c) && !isContractOrder){
            orderWrapped.contractNumber = order.Reservation_Order_Number__c;
            orderWrapped.isValidOrderRecord = 'Y';
        }else if((order.Status != 'Closed' || order.Status != 'Invoiced') && !String.isBlank(order.Contract_Order_Number__c)){
            orderWrapped.contractNumber = order.Contract_Order_Number__c;
            orderWrapped.isValidOrderRecord = 'Y';
        }
        else if(order.Rentalman_Quote_Id__c != null){
            String quoteRMID = order.Rentalman_Quote_Id__c;
            orderWrapped.contractNumber = quoteRMID.substring(3);
            orderWrapped.isValidOrderRecord = 'Y';
        }

        //Adding for SAL-25720  
        if(order.Aggregated_Status_Invoiced_Qty__c != null && order.Aggregated_Status_Invoiced_Qty__c > 0) {
            orderWrapped.seqNum = '1';
        }
        
        // Invoke Contract API
        //added addtional lock total condition for SAL-26179
        if(orderWrapped.isValidOrderRecord == 'Y'  && (!order.Lock_Initial_Totals__c)){
            WrappedResponse response;
            
            try{
                response = buildRequest(orderWrapped.contractNumber, orderWrapped.companyId, orderWrapped.seqNum);
                // parse the resonse and update taxes
                parseResponseAndUpdateTaxes(orderWrapped.contractNumber, orderItemMap, response.body,order);
            }catch(Exception ex){
                
                //Handle any callout or parsing related exceptions here.
                String request = 'GET to <condetails API>/' + (orderWrapped.contractNumber ?? '') + '/' + (orderWrapped.seqNum ?? '');
                SBR_3_0_LogException.LogIt(ex, orderWrapped.contractNumber, request);
            }
        }
        
        return orderWrapped;
    }

    public static WrappedResponse buildRequest(String rentanlManId, String companyCode, String seqNum){
        try {
            SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(APINAME);
            if(String.isEmpty(companyCode)){
                companyCode = COMPANY_ID;
            }
            WrappedResponse response = new WrappedResponse();
                     
            HttpRequest req = httpCallout.getRequest();
            req.setMethod('GET');
            req.setEndpoint(req.getEndpoint()+'/'+rentanlManId+'/'+seqNum);
            req.setHeader('companyId', companyCode);
            //req.setHeader('thresholdWaitTime', '1');
            req.setHeader('X-Correlation-ID', X_CORRELATION_ID);
            req.setHeader('Content-Type', SBR_3_0_Constants.APP_JSON);  
            req.setTimeout(120000);
			
            Http http = new Http();
            
            HTTPResponse res = http.send(req);
            
            response.headers = res.getHeaderKeys();
            response.body = res.getBody();
            
            if((res.getStatusCode() == 200 || res.getStatus()== 'OK')){
                response.status = 'Complete';
            }else {
                response.status = 'InComplete';
                //PS-4171/SD/01/04/24: Handle the case where the response is empty (No Content)
                String payLoad = 'GET request to: ' + httpCallout.endpointURL +' ** Response: ' + res.getBody();
                TaxUpdateException ex = new TaxUpdateException(Label.Contract_number_not_found_in_contracts_service);
                SBR_3_0_LogException.logIt(ex,rentanlManId, payLoad);
            }
            return response;      
        } catch (Exception e) {
            System.debug('exception buidreq >> '+e.getMessage());
            AuraHandledException ex = new AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage());
            throw ex;
        }
    }
    
    private static void parseResponseAndUpdateTaxes(String contractNumber, Map<String,OrderItem> orderItemMap, String body, Order orderRecord){
        if(String.isNotBlank(body)) {
            wrapOrderResp = (WrapOrderResponse) JSON.deserialize(body, WrapOrderResponse.class);
            
            String lineItemCompKey = contractNumber + '-';
           
            WrapTotals totals = wrapOrderResp.totals;
            WrapSubTotals salesOrderSubtotals = new WrapSubTotals();
            Decimal salesItemsSubtotal = 0.0 ;
            Decimal equipmentSalesSubtotal = 0.0 ;
            Decimal rentalPurchaseSubtotal = 0.0 ;

            Id salesRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Sales_Order').getRecordTypeId();
            boolean isSalesOrder = (salesRecordTypeId == orderRecord.RecordTypeId);
            if(isSalesOrder && wrapOrderResp.subTotals != null){
                salesOrderSubtotals = wrapOrderResp.subTotals;
                salesItemsSubtotal = getDecimalVal(salesOrderSubtotals.salesItemsSubtotal);
                equipmentSalesSubtotal = getDecimalVal(salesOrderSubtotals.equipmentSalesSubtotal);
                rentalPurchaseSubtotal = getDecimalVal(salesOrderSubtotals.rentalPurchaseSubtotal);
            }
        
            Decimal fuel = getDecimalVal(totals?.fuel);
            Decimal environmental = getDecimalVal(totals?.environmental);
            Decimal deliveryAndPickup =  getDecimalVal(totals?.deliveryAndPickup);
            Decimal miscValue = getDecimalVal(totals?.misc);
            
            
            //BD SAL-26545
            if(isSalesOrder){
                salesItemsSubtotal = salesItemsSubtotal - deliveryAndPickup;
            }
            
            orderRecord.Total_Misc__c =  miscValue + fuel + environmental + deliveryAndPickup;
            orderRecord.Total_Rental_Amount__c = getDecimalVal(totals?.rentals);
            orderRecord.Total_Sales_Amount__c = getDecimalVal(totals?.salesAmount) + salesItemsSubtotal + equipmentSalesSubtotal + rentalPurchaseSubtotal;
            orderRecord.RPP_Amount__c = getDecimalVal(totals?.rpp, orderRecord.RPP_Amount__c);
            orderRecord.Total_Sales_Taxes__c = getDecimalVal(totals?.tax, orderRecord.Total_Sales_Taxes__c);
            orderRecord.Total_Ordered_Amount__c = orderRecord.Total_Misc__c + orderRecord.Total_Rental_Amount__c + orderRecord.Total_Sales_Amount__c + orderRecord.RPP_Amount__c + orderRecord.Total_Sales_Taxes__c;
            
            // SF-6318 - Start
             //SF-7658
             if(orderRecord.Deliverymethod__c == SBR_3_0_Constants.FULFILLMENT_TYPE_PICKUP){
                orderRecord.Total_Delivery_Pickup__c = 0;
            } else {
                orderRecord.Total_Delivery_Pickup__c = getDecimalVal(totals?.deliveryAndPickup);
            }
            orderRecord.Total_Ancillary__c = miscValue + environmental + fuel;
            orderRecord.Total_Estimated_Revenue__c = getDecimalVal(totals?.finalTotal);
            
            // SF-6318 - End
            calculateTax(orderItemMap, lineItemCompKey, wrapOrderResp.products, 'Rental_Tax__c');
            calculateTax(orderItemMap, lineItemCompKey, wrapOrderResp.salesItems, 'Sales_Tax__c');
            calculateTax(orderItemMap, lineItemCompKey, wrapOrderResp.miscItems, 'Misc_Charges_Tax__c');
        }
    }
    
    private static Decimal getDecimalVal(String value){
        return getDecimalVal(value, 0);
    }
    
    private static Decimal getDecimalVal(String value, Decimal defaultDecimal){
        return String.isBlank(value) ? (defaultDecimal ?? 0) : Decimal.valueOf(value);
    }
    
    private static void calculateTax(Map<String,OrderItem> orderItemMap, String keyPrefix, List<WrapOrderItem> wrapOrderItems, String field){
        if(wrapOrderItems == null){
            return;
        }
        for(WrapOrderItem woi : wrapOrderItems){
            OrderItem oi = orderItemMap.get(keyPrefix + woi.lineNumber); 
            if(oi != null){
                oi.put(field, getDecimalVal(woi.getTax(),(Decimal)(oi.get(field) ?? 0)));
                oi.Total_Price__c = getDecimalVal(woi.getCost(),oi.Total_Price__c);
            }
        }
    }
    
    public class OrderWrapper{       
        @AuraEnabled public String orderNumber {get; set;}
        @AuraEnabled public String contractNumber {get; set;}
        @AuraEnabled public String isValidOrderRecord{get; set;}
        @AuraEnabled public String companyId {get; set;}
        @AuraEnabled public String seqNum {get; set;}
        public OrderWrapper(){}
    }
    
    public class WrappedResponse{
        @AuraEnabled public String body {get; set;}
        @AuraEnabled public String status {get; set;} 
        @AuraEnabled public List<String> headers {get; set;}
    }

    public class WrapOrderResponse{
        public String companyId = '';
        public String contractNumber = '';
        public String sequenceNumber ='';
        public String type ='';
        public String channel ='';
        public String contractStartDateTime ='';
        public String contractReturnDateTime ='';
        public String numberOfRentalDays ='';
        public String numberOfRentalHours ='';
        public String isDeliveryAndPickupCharge = ''; 
        public String isRPPCharge = ''; 
        public String assignedToEmployeeID = ''; 
        public String assignedToEmployeeName = ''; 
        public String fulfillmentStatus = ''; 
        public String stagingStatus = ''; 
        public String customerOnSite = '';  
        public List<WrapOrderItem> products = new List <WrapOrderItem>();
        public List<WrapOrderItem> salesItems = new List <WrapOrderItem>();
        public List<WrapOrderItem> miscItems = new List <WrapOrderItem>();
        public WrapTotals totals = new WrapTotals();
        public WrapSubTotals subTotals = new WrapSubTotals();
    }

    public class WrapOrderItem {
        public String  lineNumber = ''; 
        public String  rentalTax;
        public String  tax; 
        public String  salesTax;
        public String  rentalCost;
        public String  cost;
        
        public String getTax(){
            return rentalTax ?? (salesTax ?? tax);
        }
        
        public String getCost(){
            return cost ?? rentalCost;
        }
    }
    
    
    
    public class WrapTotals {
        public String  rentals = ''; 
        public String  salesAmount = ''; 
        public String  rpp = ''; 
        public String  fuel = ''; 
        public String  environmental = ''; 
        public String  deliveryAndPickup = ''; 
        public String  misc = ''; 
        public String  tax = ''; 
        public String  finalTotal = ''; 
    }

    public class WrapSubTotals {
        public String  salesItemsSubtotal = ''; 
        public String equipmentSalesSubtotal  = ''; 
        public String rentalPurchaseSubtotal  = ''; 
        public String miscItemsSubtotal  = '';
        public String rentalPurchasePlusMiscItemSubtotal  = '';
        public String equipmentSalesPlusSalesItemSubtotal  = '';
    }
    
    public class TaxUpdateException extends Exception {}
}