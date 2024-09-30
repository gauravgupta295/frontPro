/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_ReservationSourcingCall
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - 
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Aditee Churiwala        2023-01-28          Initial version    
*********************************************************************************************************************/
public class SBR_3_0_API_ReservationSourcingCall {
  
    private static final String APINAME = 'OptimalSourcingBranch_API';
    private static final String DATA = 'data';
    private static final String PC = 'pc';
    private static final String DELIVERY = 'Delivery';
    private static final String DEL = 'DEL'; //SAL-23824
    private static final String ERROR = 'error';
    private static final String CAT_CLASS = 'H';
    private static final String PARTS = 'P';
	private static final String MERCHANDISE = 'M';
    public static SBR_3_0_WrapOrderSource orderWrapper;
    public static Order order;
    String companyId;
    public static Object response;
    public static Map<String,Object> m;
    public static List<OrderItem> listOrderItem;
    
 	public static Map<String,Integer> catClassQtyMap = new Map<String,Integer>();//SAL-25690
    
    @AuraEnabled
    public static void callSource(Id orderId) {
        try {
            System.debug('@@orderId'+orderId);
            Set<Id> orderIds = new Set<Id>{orderId};
            listOrderItem = new List<OrderItem>();
            Map<Id, Order> orders;
            orderWrapper = new SBR_3_0_WrapOrderSource();
            orders = new Map<Id, Order>(SBR_3_0_OrderDA.getOrders(orderIds));
            for (Id key: orders.keySet()) {
                order = orders.get(key);           
                for (OrderItem orderItem : order.OrderItems)
                {
                    listOrderItem.add(orderItem);
                }   
            }
            // SAL-26152
            if(listOrderItem.size() < 1) { 
                throw new ReservationSourcingCallException('You must have at least one Line Item added on the record to retrieve Totals.');
            } else {
                if(order.OMS_Sourcing_Enabled__c && order.Deliverymethod__c == DELIVERY) {
                    validateData();
                    generateWrapper();
                    callAPI();
                } else{
                     System.debug('@@Entered Here 50');
                    Boolean isTotalsUpdated =  SBR_3_0_UpdateTotals.updateTotals(order.Id,null);//23506
                }
            }
        } catch(Exception ex){
            throw new ReservationSourcingCallException(ex.getMessage());
        }
    }
  @TestVisible  
    private static void callAPI(){
        try {
            String returnPayload = '';
            System.debug('@@@wr'+JSON.serialize(orderWrapper, true));
            returnPayload = SBR_3_0_Generic_Callout.callEndpoint(JSON.serialize(orderWrapper, true), APINAME, '');
            response = System.JSON.deserializeUntyped(returnPayload);
            System.debug('response 70--->'+ response);
            handleOrderResponse();
        } catch (Exception e) {
            throw new ReservationSourcingCallException('Update totals was unsuccessful. Please retry. If issue persists, please contact your System Administrator');
        } 
    }
    
 @TestVisible  
    private static void validateData() {
        //SAL-22322 removing this validation since we'll be using OrderNumber instead of Cart_ID__c 
        // if(order.Cart_ID__c == null) {
        //     throw new ReservationSourcingCallException('order.Cart_ID__c is required');
        // }
        if(order.Deliverymethod__c == null) {
            throw new ReservationSourcingCallException('order.Deliverymethod__c is required');
        }
        // if(order.Selling_Channel__c == null) {
        //     throw new ReservationSourcingCallException('order.Selling_Channel__c is required');
        // }
        if(order.Jobsite__r == null){
            throw new ReservationSourcingCallException('Jobsite is required');
        } else {
            if(order.Jobsite__r.Latitude_Longitude__Latitude__s == null) {
                throw new ReservationSourcingCallException('Latitude is required on Jobsite');
            } 
            if(order.Jobsite__r.Latitude_Longitude__Longitude__s == null) {
                throw new ReservationSourcingCallException('Longitude is required on Jobsite');
            } 
            if (order.Jobsite__r.Location == null) {
                throw new ReservationSourcingCallException('Jobsite Address is required');
            } else {
                if(order.Jobsite__r.Location.Country__c == null) {
                    throw new ReservationSourcingCallException('order.Jobsite__r.Location.Country__c is required');
                }
                if (order.Jobsite__r.Location.City__c == null) {
                    throw new ReservationSourcingCallException('order.Jobsite__r.Location.City__c is required');
                }
                if (order.Jobsite__r.Location.State__c == null) {
                    throw new ReservationSourcingCallException('order.Jobsite__r.Location.State__c is required');
                }
                if (order.Jobsite__r.Location.Zip_Code__c == null) {
                    throw new ReservationSourcingCallException('order.Jobsite__r.Location.Zip_Code__c is required');
                }
            }
           /* if (order.Jobsite__r.Job_Site_Contact__c == null) {
                throw new ReservationSourcingCallException('order.Jobsite__r.Job_Site_Contact__c is required');
            }*/
        }
        
        for(OrderItem ql: order.OrderItems) {
            if(ql.Product2.Product_Type__c == 'Cat-Class') {
                validateProduct(ql);
            } else if(ql.Product2.Product_Type__c == 'Parts' || ql.Product2.Product_Type__c == 'Merchandise') {
                validateSaleItem(ql);
            } 
        }
    }

     @TestVisible  
    private static void validateProduct(OrderItem orderItem) {
        if (orderItem.Misc_Charges_Type__c == null) { 
            if (orderItem.Product2.Category__c == null) {
                throw new ReservationSourcingCallException('orderItem.Product2.Category__c is required for Product');
            } 
            if (orderItem.Product2.Class__c == null) {
                throw new ReservationSourcingCallException('orderItem.Product2.Class__c is required for Product');
            } 
            if (orderItem.Quantity == null) {
                throw new ReservationSourcingCallException('orderItem.Quantity is required for Product');
            } 
            if (orderItem.Product2.Product_Type__c == null) {
                throw new ReservationSourcingCallException('orderItem.Product2.Product_Type__c is required for Product');
            } 
        }
    }

    @TestVisible
    private static void validateSaleItem(OrderItem orderItem) {
        if (orderItem.Product2.Item_Number__c == null) {
            throw new ReservationSourcingCallException('orderItem.Product2.Item_Number__c is required for SaleItem');
        }
        if (orderItem.Product2.Stock_Class__c == null) {
            throw new ReservationSourcingCallException('orderItem.Product2.Stock_Class__c is required for SaleItem');
        }
        if (orderItem.Quantity == null) {
            throw new ReservationSourcingCallException('orderItem.Quantity is required for SaleItem');
        }
        //SAL-24055
        if (orderItem.Selling_Price__c == null) {
            throw new ReservationSourcingCallException('orderItem.Selling_Price__c is required for SaleItem');
        }
    }
    
     @TestVisible  
    private static void handleOrderResponse() {
        System.debug('@@@Response'+response);
        String errorMsg  = '';
        try {
            if(response != null && response instanceof Map<String, Object>) {
                Map<String, Object> resultMap = (Map<String, Object>)response;
                if(resultMap.containsKey(DATA) && resultMap.get(DATA) instanceof Map<String, Object>){
                    Map<String, Object> data = (Map<String, Object>)resultMap.get(DATA);
                    System.debug('@@@data'+data);
                    List<Schema.Location> locationData = new List<Schema.Location>();
                    if(data.containsKey(PC) && data.get(PC) != ''){
                        String branch = String.valueOf(data.get(PC));
                                            System.debug('@@@branch'+branch);
						locationData = SBR_3_0_LocationDA.getLocation(branch);
                        if(!locationData.isEmpty()) {
                            order.Sourcing_Branch__c = locationData[0].Id;
                              if(Test.isRunningTest()){
                            return;
                            }
                            Boolean isTotalsUpdated =  SBR_3_0_UpdateTotals.updateTotals(order.Id,locationData[0]);//23506
                            //update order;
                        }
                    }else{//SAL-25930
                        locationData = SBR_3_0_LocationDA.getLocation(order.Branch__r.Branch_Location_Number__c);
                        Boolean isTotalsUpdated =  SBR_3_0_UpdateTotals.updateTotals(order.Id,locationData[0]);
                    }
                } else if(resultMap.containsKey(ERROR) && resultMap.get(ERROR) instanceof Map<String, Object>) {
                    Map<String, Object> error = (Map<String, Object>)resultMap.get(ERROR);
                    errorMsg = Label.Reservation_API_Error+
                                    '\n \n'+
                                    ' message: ' +
                                    error.get('message') + 
                                    ' errorKey: ' + 
                                    error.get('errorKey') +
                                    ' errorCode: ' +
                                    error.get('errorCode');
                    throw new ReservationSourcingCallException(errorMsg);
                } else if(resultMap.containsKey(ERROR)){
                    throw new ReservationSourcingCallException((String)resultMap.get(ERROR));
                }
            }
        }
        catch(Exception e) {
            throw new ReservationSourcingCallException(e.getMessage());
        }
    }
    @TestVisible
    private static void generateWrapper() {
        String rmQuoteIdSansCompanyCode ='';
        orderWrapper.companyId = order.Company_Code__c;
        orderWrapper.cartId = order.OrderNumber; //SAL-22322 replacing Cart_ID__c with OrderNumber
        orderWrapper.cartType = SBR_3_0_Constants.SELLING_CHANNEL;//order.Selling_Channel__c;
        //orderWrapper.customerType = 'DEFAULT';
		orderWrapper.sellingChannel = SBR_3_0_Constants.SELLING_CHANNEL; // order.Selling_Channel__c;
        orderWrapper.fulfillmentService = SBR_3_0_Constants.FULFILLMENT_SERVICE_URGENT;
        //orderWrapper.fulfillmentType = order.Deliverymethod__c;
        orderWrapper.fulfillmentType = DEL; //SAL-23824
        //orderWrapper.overrideDistance = true;
        orderWrapper.sourceSystem = SBR_3_0_Constants.SALESFORCE;
        
        setJobsite();
        //setOrderedBy();
         setPC();
        groupOrderItemLines(listOrderItem);     
    }

     @TestVisible  
      private static void setPC() {
        orderWrapper.pc = new SBR_3_0_WrapOrderSource.PC();
        orderWrapper.pc.id = order.Company_Code__c+'-'+order.Branch__r.Branch_Location_Number__c;
        System.debug('orderWrapper'+ orderWrapper.pc.id);
       
        
    }
     @TestVisible  
     private static void setJobsite() {
        orderWrapper.jobsite = new SBR_3_0_WrapOrderSource.Jobsite();
        orderWrapper.jobsite.address = new SBR_3_0_WrapOrderSource.Address();
        orderWrapper.jobsite.latitude = order.Jobsite__r.Latitude_Longitude__Latitude__s; //'1234351';
        orderWrapper.jobsite.longitude = order.Jobsite__r.Latitude_Longitude__Longitude__s;
        orderWrapper.jobsite.timezoneId = order.Jobsite__r.Time_Zone_Id__c!=NULL?order.Jobsite__r.Time_Zone_Id__c:order.Branch__r.Time_Zone_Id__c;
        orderWrapper.jobsite.address.line1 = order.Jobsite__r.Location.Street_Address__c;
        orderWrapper.jobsite.address.line2 = order.Jobsite__r.Location.Street_Address_2__c != null?order.Jobsite__r.Location.Street_Address_2__c:'';
        orderWrapper.jobsite.address.city = order.Jobsite__r.Location.City__c;
        orderWrapper.jobsite.address.state = order.Jobsite__r.Location.State__c;
        orderWrapper.jobsite.address.country = order.Jobsite__r.Location.Country__c;
        orderWrapper.jobsite.address.zip = order.Jobsite__r.Location.Zip_Code__c;
    }

     @TestVisible  
    private static void setProduct(OrderItem orderItem) {
        SBR_3_0_WrapOrderSource.Products product = new SBR_3_0_WrapOrderSource.Products();
    
        product.requestedDeliveryDate = order.Earliest_Delivery_Date__c != null ? order.Earliest_Delivery_Date__c.formatGMT(SBR_3_0_Constants.INT_DATE_FORMAT) : DateTime.now().formatGMT(SBR_3_0_Constants.INT_DATE_FORMAT);
        product.lineId = String.valueOf(orderItem.Id);
        product.uom = orderItem.Unit_of_Measure__c;
        product.quantity = orderItem.Quantity.intValue();
        if(orderItem.Product2.Product_Type__c == SBR_3_0_Constants.CAT_CLASS) {
            product.productType = CAT_CLASS;
            if(!catClassQtyMap.isEmpty() && catClassQtyMap.containsKey(orderItem.Product2.Product_SKU__c)){
                product.quantity = catClassQtyMap.get(orderItem.Product2.Product_SKU__c);
            }
        }
        else if(orderItem.Product2.Product_Type__c == SBR_3_0_Constants.PARTS) {
            product.productType = PARTS;
        }
        else if(orderItem.Product2.Product_Type__c == SBR_3_0_Constants.MERCHANDISE) {
            product.productType = MERCHANDISE;
        }
        product.productId = orderItem.Product2.Product_SKU__c;
        product.catId = orderItem.Product2.Category__c; 
        product.classId = orderItem.Product2.Class__c;
        orderWrapper.products.add(product);
        
       System.debug('orderWrapper.products->'+JSON.serialize(orderWrapper.products));
       
    }

    @TestVisible
    private static void setSalesItem(OrderItem orderItem) {
        SBR_3_0_WrapOrderSource.SalesItems salesItems = new SBR_3_0_WrapOrderSource.SalesItems();
        salesItems.itemNumber = orderItem.Product2.Item_Number__c;
        salesItems.stockClass = orderItem.Product2.Stock_Class__c;
        salesItems.quantity = orderItem.Quantity.intValue(); // Converting demical to Int
        salesItems.unitPrice = orderItem?.Selling_Price__c;
       if(Test.isRunningTest()){
        return;
			}
        orderWrapper.salesItems.add(salesItems);
       

    }
    
	 @TestVisible  
     private static void groupOrderItemLines(List<OrderItem> orderItems) {
        orderWrapper.products = new List<SBR_3_0_WrapOrderSource.Products>();
        orderWrapper.salesItems = new List<SBR_3_0_WrapOrderSource.SalesItems>();
        //SAL-25690
        Integer currentQuantity = 0;
        for(OrderItem orderItemRec : orderItems) {
            if(orderItemRec.Product2.Product_Type__c == SBR_3_0_Constants.CAT_CLASS) {
                currentQuantity = orderItemRec.Quantity.intValue();
                if(!catClassQtyMap.isEmpty() && catClassQtyMap.containsKey(orderItemRec.Product2.Product_SKU__c)){
                    Integer existingQty = catClassQtyMap.get(orderItemRec.Product2.Product_SKU__c);
                    catClassQtyMap.put(orderItemRec.Product2.Product_SKU__c, currentQuantity+existingQty);
                }else{
                    catClassQtyMap.put(orderItemRec.Product2.Product_SKU__c, currentQuantity);
                }
            }
        }
        for(OrderItem ql: orderItems) {
            if(ql.Product2.Product_Type__c == SBR_3_0_Constants.CAT_CLASS) {
                setProduct(ql);
            } else if(ql.Product2.Product_Type__c == SBR_3_0_Constants.PARTS || ql.Product2.Product_Type__c == SBR_3_0_Constants.MERCHANDISE) {
                setSalesItem(ql);
            } 
        }
        if(orderWrapper.salesItems.size() < 1) orderWrapper.salesItems = null;
    }
    
    //Added this method as part of FRONT-21763
    @AuraEnabled
    public static void callSourceFrontline(Order orderObj, Id orderId) {
        try {
            orderObj.Id = orderId;
            update orderObj;           
        }
        catch(Exception ex){
            System.debug(LoggingLevel.DEBUG, ex.getLineNumber() + '==ex==' + ex.getMessage());
            throw new ReservationSourcingCallException(ex.getMessage());
        }
    }
    
    public class ReservationSourcingCallException extends Exception {}
}