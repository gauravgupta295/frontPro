/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_CreateOrders
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Send Order to Rentalman (via Mulesoft) when it is created in Salesforce
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Aditee Churiwala          2022-11-08             Initial version    
*********************************************************************************************************************/
public with sharing class SBR_3_0_API_CreateOrders {
    private static final String APINAME = 'Create_Orders_API_V2';
    private static final String DATA = 'data';
    private static final String RM_RESERVATION_ID = 'rmReservationId';
    private static final String LINES = 'lines';
    private static final String SF_LINE_NUMBER = 'sfLineNumber';
    private static final String RM_LINE_NUMBER = 'rmLineNumber';
    private static final String GLOBAL_LINE_NUMBER = 'lineNumber';
    private static final String RM_LINE_TYPE = 'rmLineType';
    private static final String ERROR = 'error';
    private static final String SUCCESS = 'success';
    private static final String ORDERLINEITEM_MESSAGE = 'Line item is not present for this Order';
    private static final String USEREDIT_MESSAGE = 'User does not have access for this record';
    private static final String RMERROR_MESSAGE = 'Record is already sent to RentalMan';
    private Id orderId;
    private String companyId;
    private SBR_3_0_WrapOrder orderWrapper;
    private Order order;
    @TestVisible
    private Object response;
    private Map<Integer, OrderItem> mapOrderItem;
    public static String makeADepositDetails = '';  //Added for  FRONT- 14560
    public static Id TransactionIdN;
    @AuraEnabled
    public static SBR_3_0_API_CreateOrders createOrders(Id orderId , String recordDetailsJsonString,Id TransactionID) {        
        makeADepositDetails = recordDetailsJsonString; //Added for  FRONT- 14560
        TransactionIdN = TransactionID;
       return new SBR_3_0_API_CreateOrders(orderId);
    }
 
    public SBR_3_0_API_CreateOrders(Id orderId) {
        Set<Id> orderIds;
        Map<Id, Order> orders;
        mapOrderItem = new Map<Integer, OrderItem>();
        orderWrapper = new SBR_3_0_WrapOrder();
        this.orderId = orderId;

        orderIds = new Set<Id>();
        orderIds.add(orderId);

        orders = new Map<Id, Order>(SBR_3_0_OrderDA.getOrders(orderIds));
        for (Id key: orders.keySet()) {
            order = orders.get(key);
            this.companyId = order.Company_Code__c;
            if(order.Reservation_Order_Number__c != null) {
                throw new CreateOrderException(RMERROR_MESSAGE);
            }
            else {
                for (OrderItem orderItem : order.OrderItems)
                {
                    Integer mapOrderItemKey;
                    if(isConvertQuoteToOrder()){
                        mapOrderItemKey = Integer.valueOf(orderItem.Global_Line_Number__c);
                    } else {
                        mapOrderItemKey = Integer.valueOf(orderItem.OrderItemNumber);
                    }

                    if(!mapOrderItem.containsKey(mapOrderItemKey)) {
                        mapOrderItem.put(mapOrderItemKey, orderItem);
                        System.debug('@@mapOrderItem'+orderItem.OrderItemNumber);
                    }
                }
            }
            
        }
        validateData();
        generateWrapper();
        System.debug('@@@Wrap'+ JSON.serialize(this.orderWrapper, true));
        createOrder();
        handleOrderResponse();
       
    }

    private void createOrder(){
        String returnPayload = '';
        System.debug('\n @@ request =' + JSON.serializePretty(this.orderWrapper));
        returnPayload = SBR_3_0_Generic_Callout.callEndpoint(JSON.serialize(this.orderWrapper, true), APINAME, this.companyId);
        System.debug('\n @@ response =' + returnPayload);
        
        response = JSON.deserializeUntyped(returnPayload);
    }

    private void validateData() {
        if(order.Account.Record_Type_Text__c == null) {
            throw new CreateOrderException('Account Record type is missing. Please update Account and Resubmit.');
        }
        if(order.Id == null) {
            throw new CreateOrderException('Order Id is required');
        }
        if (order.Account != null) {
            // change suggested by viren
            if (order.Account.RM_Account_Number__c == null) {
                throw new CreateOrderException('Order related Account is missing RM Account Number. Please update Account and Resubmit');
            }
            if (order.Account.Phone == null) {
                throw new CreateOrderException('Order related Account is missing Phone. Please update Account and Resubmit');
            }
        } else {
            throw new CreateOrderException('Order related Account is missing. Please update Account and Resubmit.');
        }
        if(order.Deliverymethod__c == null) {
            throw new CreateOrderException('Order Delivery Method is required');
        }
        if (order.Deliverymethod__c == SBR_3_0_Constants.FULFILLMENT_TYPE_DELIVERY) {
            // SAL-23118 Related Fix, made these 2 validations conditional

            if (order.Delivery_Charge__c == null || order.Delivery_Charge__c == 0) {
                //SAL-26027
                throw new CreateOrderException('Order Delivery Charge is required');
            } 
           
            //Start, SAL-26027
            if (order.Pickup_Charge__c == null || order.Pickup_Charge__c == 0) {
                throw new CreateOrderException('Order Pickup Charge is required');
            }
            //End, SAL-26027
            if (order.Earliest_Delivery_Date__c == null) {
                throw new CreateOrderException('Order Earliest Delivery Date is required');
            }
        }        
        if (order.Order_By__r.Email == null) {
            throw new CreateOrderException('Ordered By Contact is missing email.  Please update Contact and Resubmit.');
        }
        if (order.Order_By__r.Phone == null && order.Order_By__r.MobilePhone == null){
            throw new CreateOrderException('Ordered By Contact is missing phone number.  Please update Contact and Resubmit.');
        }
        if (order.Return_Date__c == null) {
            throw new CreateOrderException('Order Return Date is required');
        }
	// SF-7224 Commented
        /*if (order.Opt_Out_RPP__c == null) {
            throw new CreateOrderException('Order Opt Out RPP is required');
        } */
        if (order.Opt_Out_Fuel_Charge__c == null) {
            throw new CreateOrderException('Order Opt Out Fuel Charge is required');
        }
        if(order.Jobsite__r == null){
            throw new CreateOrderException('Jobsite is required');
        } else {
            if (order.Jobsite__r.Branch__r == null) {
                throw new CreateOrderException('JobSite Branch is required');
            } else {
                if (order.Jobsite__r.Branch__r.Branch_Location_Number__c == null) {
                    throw new CreateOrderException('Branch Location Number is required');
                }
                /* change from order.Jobsite__r.Branch__r.Time_Zone_Name__c to order.Jobsite__r.Branch__r.Time_Zone_Id__c  for SAL-14376 */
                if (order.Jobsite__r.Branch__r.Time_Zone_Id__c == null) {
                    throw new CreateOrderException('Location Time Zone Id is required');
                }
            }
            if (order.Jobsite__r.Location == null) {
                throw new CreateOrderException('Jobsite Address is required');
            } else {
                if (order.Jobsite__r.Location.OMS_Sourcing_Enabled__c == null) {
                    throw new CreateOrderException('Order Jobsite\'s Location OMS Sourcing Enabled is required');
                }
                if (order.Jobsite__r.LocationId == null) {
                    throw new CreateOrderException('Order Jobsite\'s Location Id is required');
                }
                if (order.Jobsite__r.Job_Number__c == null) {
                    throw new CreateOrderException('Order Jobsite\'s Job Number is required');
                }
            }
        }

        for (OrderItem orderItemRec : order.OrderItems) {
            if (orderItemRec.Product2.Product_Type__c == 'Cat-Class') {
                validateProduct(orderItemRec);
            } else if (orderItemRec.Product2.Product_Type__c == SBR_3_0_Constants.PARTS || orderItemRec.Product2.Product_Type__c == SBR_3_0_Constants.MERCHANDISE || (orderItemRec.is_User_Added__c && (orderItemRec.Product2.Product_Type__c == 'MISC Charge Items' || orderItemRec.Product2.Product_Type__c == 'Misc-Charge'))) {
                //SAL-25828

                validateSaleItem(orderItemRec);
            } else {
                validateMiscItem(orderItemRec);
            }
        }
    }

    private void validateProduct(OrderItem orderItem) {
        if (orderItem.Misc_Charges_Type__c == null) {
            if (orderItem.Product2.Product_SKU__c == null) {
                throw new CreateOrderException('Order item product is missing Product SKU.  Please update product and Resubmit.');
            } 
            if (orderItem.Product2.Category__c == null) {
                throw new CreateOrderException('Order item product is missing Category .  Please update product and Resubmit.');
            } 
            if (orderItem.Product2.Class__c == null) {
                throw new CreateOrderException('Order item product is missing Class .  Please update product and Resubmit.');
            } 
            if (orderItem.Quantity == null) {
                throw new CreateOrderException('Order item is missing Quantity .  Please update Order Item and Resubmit.');
            } 
            if (orderItem.Free_Flag__c == null) {
                throw new CreateOrderException('Order item is missing Free Flag .  Please update Order Item and Resubmit.');
            } 
            if (orderItem.Product2.ToolFlex__c == null) {
                throw new CreateOrderException('Order item product is missing ToolFlex .  Please update product and Resubmit.');
            } 
            if (orderItem.Hourly_Rate__c == null) {
                throw new CreateOrderException('Order item is  missing Hourly Rate .  Please update Order Item and Resubmit.');
            } 
            if (orderItem.Min_Rate__c == null) {
                throw new CreateOrderException('Order item is missing Min Rate .  Please update Order Item and Resubmit.');
            }
            if (orderItem.Suggested_Daily_Rate__c == null) {
                throw new CreateOrderException('Order item is missing Suggested Daily Rate .  Please update Order Item and Resubmit.');
            }
            if (orderItem.Suggested_Weekly_Rate__c == null) {
                throw new CreateOrderException('Order item is missing Suggested Weekly Rate .  Please update Order Item and Resubmit.');
            }
            if (orderItem.Suggested_Monthly_Rate__c == null) {
                throw new CreateOrderException('Order item is missing Suggested Monthly Rate .  Please update Order Item and Resubmit.');
            }
            if (orderItem.Daily_Rate__c == null) {
                throw new CreateOrderException('Order item is missing Daily Rate .  Please update Order Item and Resubmit.');
            }
            if (orderItem.Hourly_Rate__c == null) {
                throw new CreateOrderException('Order item is missing Hourly Rate .  Please update Order Item and Resubmit.');
            }
            if (orderItem.Weekly_Rate__c == null) {
                throw new CreateOrderException('Order item is missing Weekly Rate .  Please update Order Item and Resubmit.');
            }
            if (orderItem.Monthly_Rate__c == null) {
                throw new CreateOrderException('Order item is missing Montly Rate .  Please update Order Item and Resubmit.');
            }
            // if (orderItem.Rates_Overriden__c == null) {
            //     throw new CreateOrderException('Rates Overriden is required for Product');
            // }
            // if (orderItem.Item_Number__c == null) {
            //     throw new CreateOrderException('orderItem.Item_Number__c is required for Product');
            // }
        }
    }

    private void validateSaleItem(OrderItem orderItem) {
        if (orderItem.Product2.Item_Number__c == null) {
            throw new CreateOrderException('Order Item product is missing Item Number. Please update product and Resubmit.');
        }
        if (orderItem.Product2.Stock_Class__c == null) {
            throw new CreateOrderException('Order Item product is missing Stock Class. Please update product and Resubmit.');
        }
        if (orderItem.Quantity == null) {
            throw new CreateOrderException('Order Item is missing Quantity. Please update Order Item and Resubmit.');
        }
        if (orderItem.Selling_Price__c == null || orderItem.Selling_Price__c == 0) {
            throw new CreateOrderException('Order Item is missing Selling price. Please update Order Item and Resubmit.');
        }
    }

    private void validateMiscItem(OrderItem orderItem) {
        if (orderItem.Misc_Charges_Type__c == null) {
            throw new CreateOrderException('Order Item is missing Misc Charges Type. Please update Order Item and Resubmit.');
        }
        if (orderItem.Selling_Price__c == null) {
            throw new CreateOrderException('Order Item is missing Selling price. Please update Order Item and Resubmit.');
        }
        if (orderItem.Product2.Item_Number__c == null) {
            throw new CreateOrderException('Order Item Product is missing Item Number. Please update Product and Resubmit.');
        }
        if (orderItem.Product2.Stock_Class__c == null) {
            throw new CreateOrderException('Order Item Product is missing Stock Class. Please update Product and Resubmit.');
        }
    }

    public Boolean isConvertQuoteToOrder(){
        if(order.Rentalman_Quote_Id__c != null && order.SBQQ__Quote__c != null) {
            return true;
        }else {
            return false;
        }
    }

    private void generateWrapper() {
        String rmQuoteIdSansCompanyCode ='';
        if (!String.IsBlank(order.Rentalman_Quote_Id__c)) {
            if(order.Rentalman_Quote_Id__c.contains('-')) {
                rmQuoteIdSansCompanyCode = order.Rentalman_Quote_Id__c.substringAfter('-');
            }
            else {
                rmQuoteIdSansCompanyCode = order.Rentalman_Quote_Id__c;
            }
        }
        
        if(isConvertQuoteToOrder()) {
            //Convert Quote to Order - on RM side this is Conver to Order API
            orderWrapper.convertQuoteToOrder = 'Y';
            orderWrapper.rmQuoteId = rmQuoteIdSansCompanyCode;
            orderWrapper.sfQuoteId = order.SBQQ__Quote__r.Name;
        }
        else {
            //Submit an Order which is not converted from Quote to Order first - on RM side this is Order creation API
            orderWrapper.convertQuoteToOrder = 'N';
            orderWrapper.sfQuoteId = '';
        }
        orderWrapper.chronos = order.Jobsite__r.Location.OMS_Sourcing_Enabled__c ? 'Y' : 'N';
        orderWrapper.userType = order.Account.Record_Type_Text__c == 'Credit' || order.Account.Record_Type_Text__c == 'Corp Link'? 'credit' : order.Account.Record_Type_Text__c == 'Non-Credit' ? 'cash' : ''; // FRONT-14560 added 'cash' scenario
        orderWrapper.sfOrderId = order.OrderNumber;
        orderWrapper.rmQuoteId = rmQuoteIdSansCompanyCode;
        /*

        String acctNum =  order.Account.RM_Account_Number__c;
        if(acctNum != null && acctNum.contains('-')) {
            acctNum = acctNum.subStringAfter('-');
        } 
        orderWrapper.accountNumber = acctNum;*/
        String accountNumber;
        Account currentAccount = new Account();
        if(order.Account != null)
        {
                    if(order.Account.Record_Type_Text__c == 'Non-Credit'){   // FRONT-14560 
                        orderWrapper.accountNumber = '0';
                    }else {
                        if(order.Account.RM_Account_Number__c!= null)
                        {
                            accountNumber = order.Account.RM_Account_Number__c;
                            if(accountNumber.contains('-')) {
                                accountNumber = accountNumber.subStringAfter('-');
                            }
                            orderWrapper.accountNumber = accountNumber;
                        }
                        else
                        {
                            currentAccount = SBR_3_0_AccountDA.getAccountRMNumberAndType(order.AccountId, true);
                            if(currentAccount != null && currentAccount.RM_Account_Number__c!=null ) {
                                if(currentAccount.RM_Account_Number__c.contains('-')) {
                                    accountNumber = currentAccount.RM_Account_Number__c.subStringAfter('-');
                                    orderWrapper.accountNumber = accountNumber;
                                }
                            orderWrapper.userType = currentAccount.Record_Type_Text__c == 'Credit' ? 'credit' : '';

                            }  else {
                            orderWrapper.accountNumber = '0';
                            }
                        }
                    }

			        orderWrapper.sfAccountNumber = order.Account.SF_Account_Number__c;
                    if(String.isNotBlank(order.Account.Driver_s_License_State__c) && String.isNotBlank(order.Account.Drivers_License__c))
                    {
                         orderWrapper.driverLicenseState=order.Account.Driver_s_License_State__c;
                         orderWrapper.driverLicenseNumber=order.Account.Drivers_License__c;
                    }
  
    			    //orderWrapper.driverLicenseState = order.Account.Driver_s_License_State__c != null?order.Account.Driver_s_License_State__c:'';
     			   // orderWrapper.driverLicenseNumber = order.Account.Drivers_License__c != null?order.Account.Drivers_License__c:'';
            
        }  

        orderWrapper.fulfillmentType = order.Deliverymethod__c;
        orderWrapper.deliveryInstructions = '';
        orderWrapper.startDateTime = order.Start_Date__c.formatGMT(SBR_3_0_Constants.INT_DATE_FORMAT);
        orderWrapper.endDateTime = order.Return_Date__c.formatGMT(SBR_3_0_Constants.INT_DATE_FORMAT);
        //for DeliveryMethod Pickup, Earliest Date Time will be null but since RM requires it, passing it the current time + 5 minutes.
        orderWrapper.earliestDateTime = order.Earliest_Delivery_Date__c != null ? order.Earliest_Delivery_Date__c.formatGMT(SBR_3_0_Constants.INT_DATE_FORMAT) : DateTime.now().addMinutes(5).formatGMT(SBR_3_0_Constants.INT_DATE_FORMAT); // optional
        if( order.PoNumber != null && order.PoNumber != ''){ // FRONT-14560 
            orderWrapper.poNumber = order.PoNumber;
        }
        orderWrapper.optOutRPP = order.RPP__c == 'N' ? 'Y' : 'N';	// SF-7224
        orderWrapper.optOutFuelCharge = order.Opt_Out_Fuel_Charge__c ? 'Y' : 'N';
        orderWrapper.deliveryCharge = order.Delivery_Charge__c;
        orderWrapper.email = order.Account.E_mail_Address__c;
        orderWrapper.phoneNumber = order.Account.Phone.replaceAll('[^0-9]', '');
        orderWrapper.sellingChannel = SBR_3_0_Constants.SELLING_CHANNEL;
        orderWrapper.initiatingChannel = SBR_3_0_Constants.INITIATING_CHANNEL;
        orderWrapper.primarySalesRepId = order.Sales_Rep__r.RepID__c != null? order.Sales_Rep__r.RepID__c:'';
        orderWrapper.createdBy = order.CreatedBy.Name;
        orderWrapper.pickUpCharge = order.Pickup_Charge__c != null?order.Pickup_Charge__c:0;
		
        setPaymentDetails();   //Added by chethan for  FRONT- 14560 
        setPC();
        setJobsite();
        setOrderedBy();
        groupOrderLines(order.OrderItems);
               
    }

    /***********************************************************************************************************
     Author : Chethan S N 
     Method Name : setMakeADepositDetails
     Implementation Purpose : Added by chethan for  FRONT- 14560
     Date :     
     ************************************************************************************************************/
    @TestVisible
    private void setPaymentDetails(){
        SBR_3_0_WrapOrder.Payment paymentDetails = new SBR_3_0_WrapOrder.Payment();
        Map<String,String> mapOfPaymentMenthodAnnotation 
        = new map<String,String>{'Visa' =>'V','Amex' => 'A','Cash Currency' => 'C', 'Discover' => 'D', 'Interac Debit' => 'G' , 'Check' => 'K' , 'Mastercard' => 'M','No Refund Given' => 'N', 'Pay on Return'=> 'P','Refund Request (Corporate)' => 'R','Uncollected' => 'U','Visa' => 'V','Diners Club'=> 'X' };        
        Map<String, Object> paymentDetailsObject = (Map<String, Object>)JSON.deserializeUntyped(makeADepositDetails);
        String PMselected = (String)paymentDetailsObject.get('paymentMethod');
        SBR_3_0_Generic_Callout.PaymentMethod = (String)paymentDetailsObject.get('paymentMethod');
        SBR_3_0_Generic_Callout.sourceTransactionId = (String)TransactionIdN;
        
        paymentDetails.method = mapOfPaymentMenthodAnnotation.get(PMselected);
        paymentDetails.amount =  (Integer)paymentDetailsObject.get('amountCollected'); 
        if(PMselected == 'Amex' || PMselected == 'Visa' || PMselected == 'Mastercard' || PMselected == 'Discover'
           || PMselected == 'Diners Club' || PMselected == 'Interac Debit'){ //Make sure CreditCardlane is passed only if card is selected.
                paymentDetails.creditCardLane =  (String.valueOf(paymentDetailsObject.get('terminal'))==null || String.valueOf(paymentDetailsObject.get('terminal'))=='') ? '0': String.valueOf(paymentDetailsObject.get('terminal')).split('ID: ')[1];
        } 
        if(PMselected == 'Check'){
           paymentDetails.checkNumber =  String.valueOf(paymentDetailsObject.get('checkNumber')); 
        }        
        orderWrapper.Payment = paymentDetails;
    }

    private void setOrderedBy(){
        orderWrapper.orderedBy = new SBR_3_0_WrapOrder.OrderedBy();
        String concatName = order.Order_By__r.LastName+', '+order.Order_By__r.FirstName;
        Integer maxSize = 20;
        if(concatName.length() > maxSize ){
            concatName = concatName.substring(0, maxSize);
        }
        orderWrapper.orderedBy.name = concatName;
        orderWrapper.orderedBy.phoneNumber = (String.isNotBlank(order.Order_By__r.Phone) ? order.Order_By__r.Phone : order.Order_By__r.MobilePhone);
        orderWrapper.orderedBy.email = order.Order_By__r.Email;
    }
    private void setPC() {
        orderWrapper.pc = new SBR_3_0_WrapOrder.Pc();
        User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId()); // FRONT-14560 
        orderWrapper.rentalmanUser = (loggedInUser!=null && loggedInUser.Wynne_User_Name__c != null) ? loggedInUser.Wynne_User_Name__c :'WROHR'; // Added for FRONT-14560.        
        
        //23575
        if(order.Sourcing_Branch__c != null && order.Sourcing_Branch__r.Latitude_Longitude__Longitude__s !=null && order.Sourcing_Branch__r.Latitude_Longitude__Latitude__s !=null ) {
            orderWrapper.pc.id = order.Sourcing_Branch__r.Branch_Location_Number__c;
            if(order.Sourcing_Branch__r?.Time_Zone_Id__c !=null){
                orderWrapper.pc.timezoneName = order.Sourcing_Branch__r?.Time_Zone_Id__c;
            }else{
                orderWrapper.pc.timezoneName = loggedInUser?.TimeZoneSidKey;
            }
        } else {
            if (order.Branch__r.Branch_Location_Number__c == null) {
                throw new CreateOrderException('Branch Location Number is required');
            }
            orderWrapper.pc.id = order.Branch__r.Branch_Location_Number__c;
            if(order.Branch__r.Time_Zone_Id__c !=null){
                orderWrapper.pc.timezoneName = order.Branch__r.Time_Zone_Id__c;
            }else{
                orderWrapper.pc.timezoneName = loggedInUser?.TimeZoneSidKey;
            }
        }
    }

    private void setJobsite() {
        orderWrapper.jobsite = new SBR_3_0_WrapOrder.Jobsite();
        orderWrapper.jobsite.address = new SBR_3_0_WrapOrder.Address();
        orderWrapper.jobsite.id = order.Jobsite__r.Job_Site_Id__c; //'1234351';
        orderWrapper.jobsite.jobsiteNumber = order.Jobsite__r.Job_Number__c;        
        orderWrapper.jobsite.address.name = order.Jobsite__r.Location.Name;
        orderWrapper.jobsite.address.line1 = order.Jobsite__r.Location.Street_Address__c;
        orderWrapper.jobsite.address.line2 = order.Jobsite__r.Location.Street_Address_2__c != null?order.Jobsite__r.Location.Street_Address_2__c:'';
        orderWrapper.jobsite.address.city = order.Jobsite__r.Location.City__c;
        orderWrapper.jobsite.address.state = order.Jobsite__r.Location.State__c;
        orderWrapper.jobsite.address.country = order.Jobsite__r.Location.Country__c;
        orderWrapper.jobsite.address.zip = order.Jobsite__r.Location.Zip_Code__c;
        orderWrapper.jobsite.address.phoneNumber = order.Jobsite__r.Job_Site_Contact__c != null ? order.Jobsite__r.Job_Site_Contact__c.replaceAll('[^0-9]', '') : '0';
        //orderWrapper.jobsite.address.location = ''; // Unsure - Leave blank according to document
        orderWrapper.jobsite.address.location = order.Jobsite__r.Location.City__c; // FRONT-14560   //  ''; // Unsure - Leave blank according to document
        orderWrapper.jobsite.address.distance = order.Jobsite__r.Location?.Distance_Multiplier__c != null ?order.Jobsite__r.Location?.Distance_Multiplier__c?.intValue() : 0; // Converting decimal to Int
    }

    private void setProduct(OrderItem orderItem) {
        SBR_3_0_WrapOrder.Products product = new SBR_3_0_WrapOrder.Products();
        product.equipmentId = orderItem.Product2.Bulk_Item__c ? orderItem.Product2?.itemNumberUsedByReservationsRentalOut__c : orderItem.Product2.Category__c + orderItem.Product2.Class__c;//SAL-24130
        product.suggestedRates = new SBR_3_0_WrapOrder.SuggestedRates();
        product.actualRates = new SBR_3_0_WrapOrder.SuggestedRates();
        product.toolFlex = (orderItem.Product2?.ToolFlex__c == 'C' || String.isBlank(orderItem.Product2?.ToolFlex__c)) ? 'N' : orderItem.Product2?.ToolFlex__c; //22580, SF-5294
        product.hourRate = orderItem.Hourly_Rate__c;
        product.minimumRate = orderItem.Min_Rate__c;
        product.catId = orderItem.Product2.Category__c; //068;
        product.classId = orderItem.Product2.Class__c;//'0210';
        product.quantity = orderItem.Quantity.intValue(); // converting decimal to Int
        product.freeFlag = orderItem.Free_Flag__c ? 'Y' : 'N';
        product.suggestedRates.day = orderItem.Suggested_Daily_Rate__c;
        product.suggestedRates.weekly = orderItem.Suggested_Weekly_Rate__c;
        product.suggestedRates.monthly = orderItem.Suggested_Monthly_Rate__c;
        product.actualRates.day = orderItem.Daily_Rate__c;
        product.actualRates.weekly = orderItem.Weekly_Rate__c;
        product.actualRates.monthly = orderItem.Monthly_Rate__c;
        product.dayRateOverride = orderItem.Rates_Overriden__c ? 'Y' : 'N';
        product.weeklyRateOverride = orderItem.Rates_Overriden__c ? 'Y' : 'N';
        product.monthlyRateOverride = orderItem.Rates_Overriden__c ? 'Y' : 'N';
        product.lineComment = orderItem.Line_Comments__c;
       
        product.sfLineNumber = String.valueOf(orderItem.OrderItemNumber);
        orderWrapper.products.add(product);
    }

    private void setSalesItem(OrderItem orderItem) {
        SBR_3_0_WrapOrder.SalesItems salesItems = new SBR_3_0_WrapOrder.SalesItems();
        salesItems.itemNumber = orderItem.Product2.Item_Number__c;
        salesItems.stockClass = orderItem.Product2.Stock_Class__c;
        salesItems.quantity = orderItem.Quantity.intValue(); // Converting demical to Int
        salesItems.unitPrice = orderItem.Selling_Price__c;
        salesItems.sfLineNumber = String.valueOf(orderItem.OrderItemNumber);
        salesItems.unitOfMeasure = 'ft'; // FRONT-14560 , added to remove request error. 
        orderWrapper.salesItems.add(salesItems);
    }

    private void setMiscItem(OrderItem orderItem) {
        SBR_3_0_WrapOrder.MiscItems miscItems = new SBR_3_0_WrapOrder.MiscItems();
        miscItems.type = orderItem.Misc_Charges_Type__c;
        miscItems.charge = orderItem.Selling_Price__c;
        miscItems.tax = orderItem.Misc_Charges_Tax__c;
        miscItems.taxExempt = orderItem.Taxable__c;
        miscItems.nonTaxable = orderItem.Misc_Charges_Non_Taxable__c;
        miscItems.itemTaxRate = orderItem.Misc_Charges_Item_Tax_Rate__c;
        miscItems.itemNumber = orderItem.Product2.Item_Number__c;
        miscItems.stockClass = orderItem.Product2.Stock_Class__c;
        miscItems.sfLineNumber = String.valueOf(orderItem.OrderItemNumber);
        miscItems.productSku = orderItem.Product2.Product_SKU__c;
        orderWrapper.miscItems.add(miscItems);
    }

    private void groupOrderLines(List<OrderItem> orderItems) {
        orderWrapper.products = new List<SBR_3_0_WrapOrder.Products>();
        orderWrapper.salesItems = new List<SBR_3_0_WrapOrder.SalesItems>();
        orderWrapper.miscItems = new List<SBR_3_0_WrapOrder.MiscItems>();
        for(OrderItem orderItemRec: orderItems) {
            if(orderItemRec.Product2.Product_Type__c == SBR_3_0_Constants.CAT_CLASS) {
                setProduct(orderItemRec);
            } else if(orderItemRec.Product2.Product_Type__c == SBR_3_0_Constants.PARTS || orderItemRec.Product2.Product_Type__c == SBR_3_0_Constants.MERCHANDISE
                        || (orderItemRec.is_User_Added__c && (orderItemRec.Product2.Product_Type__c == 'MISC Charge Items' || orderItemRec.Product2.Product_Type__c == 'Misc-Charge'))
                    ) { //SAL-25828
                setSalesItem(orderItemRec);
            } else {
                setMiscItem(orderItemRec);
            }
        }
    }

    @TestVisible
    private void handleOrderResponse() {
        System.debug('@@@Response'+response);
        String errorMsg  = '';
        try {
            if(response != null && response instanceof Map<String, Object>) {
                Map<String, Object> resultMap = (Map<String, Object>)response;
                system.debug('resultMap'+resultMap);
                if(resultMap.containsKey(DATA) && resultMap.get(DATA) instanceof Map<String, Object>){
                    Map<String, Object> data = (Map<String, Object>)resultMap.get(DATA);
                    if(data.containsKey(RM_RESERVATION_ID)){
                        String rmReservationId = (String)data.get(RM_RESERVATION_ID);
                        order.Reservation_Order_Number__c = rmReservationId;
                        order.Submitted_to_Wynne__c = true; // SF-6182
                        system.debug('order'+order);
                        update order;
                    }
                    if(data.containsKey(LINES)){
                       List<Object> linesData =(List<Object>)data.get(LINES);

                       for(Object line : linesData) {
                           Map<String, Object> linesMap= (Map<String, Object>) line;
                           String lineNumber;
                           if(isConvertQuoteToOrder()){
                            lineNumber = (String)linesMap.get(GLOBAL_LINE_NUMBER);
                           } else {
                            lineNumber = (String)linesMap.get(SF_LINE_NUMBER);
                           }
                           Integer lineNo = (lineNumber!= null && lineNumber != '')?Integer.valueOf(lineNumber):null;
                           if(mapOrderItem.containsKey(lineNo)) {
                                OrderItem ordItem = mapOrderItem.get(lineNo);
                                ordItem.Reservation_Line_Number__c = Integer.valueOf(linesMap.get(RM_LINE_NUMBER));
                                ordItem.Line_Item_Type__c = (String) linesMap.get(RM_LINE_TYPE);
                                ordItem.Global_Line_Number__c = Decimal.valueOf((String) linesMap.get(GLOBAL_LINE_NUMBER));
                                ordItem.Line_Composite_Key__c = order.Reservation_Order_Number__c + '-' + ordItem.Global_Line_Number__c;
                            }
                            //    else{
                            //     maxSFLineNumber = maxSFLineNumber + 1;
                            //     OrderItem orderLineNoSF = new OrderItem();
                            //     orderLineNoSF = (OrderItem) line;
                            //     String rmLineNo = (String)linesMap.get(RM_LINE_NUMBER);
                            //     orderLineNoSF.Reservation_Line_Number__c = Decimal.valueOf(rmLineNo);
                            //     orderLineNoSF.Line_Item_Type__c = (String)linesMap.get(RM_LINE_TYPE);
                            //     orderLineNoSF.Global_Line_Number__c = Decimal.valueOf((String)linesMap.get(GLOBAL_LINE_NUMBER));
                            //     mapOrderItem.put(maxSFLineNumber, orderLineNoSF);
                            //     //need to do AC2 here
                            //     //set the info for the json response
                            //    }
                        }
                        if (!Test.isRunningTest()) {
                            update mapOrderItem.values();
                        }
                        
                    }
                } else if (resultMap.containsKey(ERROR) && resultMap.get(ERROR) instanceof Map<String, Object>) {
                    Map<String, Object> error = (Map<String, Object>) resultMap.get(ERROR);
                    errorMsg = Label.Reservation_API_Error + '\n \n' + ' message: ' + error.get('message') + ' errorKey: ' + error.get('errorKey') + ' errorCode: ' + error.get('errorCode');
                    //SF-6805
                    String errorStr = String.valueOf(error.get('message'));
                    String jobLocNotFound = 'Job location not found';
                    if(String.isNotBlank(errorStr) && errorStr.contains(jobLocNotFound)){
                        //errorStr = 'The Job Site has not been successfully created in RentalMan. Please reach out to your System Administrator';
                        errorMsg = Label.Reservation_API_Error + '\n \n' + ' message: ' + Label.Job_Site_Error + ' errorKey: ' + error.get('errorKey') + ' errorCode: ' + error.get('errorCode');
                    }
                    throw new CreateOrderException(errorMsg);
                }
            }
        }
        catch(Exception e) {
            if(errorMsg  == null) {
                errorMsg = SBR_3_0_Constants.ERROR_MSG;
            }
            throw new CreateOrderException(errorMsg);
        }
    }
    
    public class CreateOrderException extends Exception {}
}