/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 06-20-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class SBR_3_0_AvailabilityBadgeCmpController {
    @AuraEnabled
    public static SBR_3_0_WrapInventoryAtBranch.ATPResponse getATP(Id objectId, String catClass, 
    String companyCode, String transactionType) {
        SBR_3_0_WrapInventoryAtBranch.ATPRequest atpReqObj = new SBR_3_0_WrapInventoryAtBranch.ATPRequest();
        String objectName = '';
        // get user profile branch
        List<Schema.Location> userProfileLocation = SBR_3_0_BranchDA.getLoggedInUserLocation();
        if(userProfileLocation.size() == 0) {
            return null;
        }

        if(String.isNotBlank(objectId)) {
            objectName = objectId.getSObjectType().getDescribe().getName();
        }
        if (String.isBlank(companyCode)) {
            User u = [SELECT CompanyName FROM User WHERE Id = :UserInfo.getUserId()];
            companyCode = u.CompanyName;
        }
        API_ATP_Config__mdt atpFieldConfig = SBR_3_0_CustomMetadata_DA.getATPApiConfig('Prod_Inquiry');
        atpReqObj.orgId = companyCode;
        atpReqObj.cartId = SBR_3_0_Constants.SELLING_CHANNEL;
        atpReqObj.fulfillmentType = SBR_3_0_Constants.ATP_FULFILLMENTTYPE_DELIVERY;
        //obj.transactionType = transactionType; //SAL-24282
        atpReqObj.sellingChannel = SBR_3_0_Constants.SELLING_CHANNEL;
        if(atpFieldConfig <> NULL){
            atpReqObj.includeZeroATP = atpFieldConfig.Include_Zero_ATP__c;
            atpReqObj.limitBranchByDistanceCount = Integer.valueOf(atpFieldConfig.Limit_Branch_By_Distance__c);
        }
        if (objectName == 'SBQQ__Quote__c'){
            SBQQ__Quote__c selectedQuote = SBR_3_0_QuoteDA.getQuotes(new Set<Id>{objectId}).values()[0];
            //SAL-24240
            if(!selectedQuote.OMS_Sourcing_Enabled__c){
                return null;
            }

            String formatted = selectedQuote.Start_Date__c.formatGmt(SBR_3_0_Constants.INT_DATE_FORMAT); 
            atpReqObj.requestedDeliveryDate = formatted;

            if(selectedQuote.SBQQ__DeliveryMethod__c == 'Delivery' &&  selectedQuote.OMS_Sourcing_Enabled__c){
                if(selectedQuote.Jobsite__r <> NULL &&
                    selectedQuote.Jobsite__r.Latitude_Longitude__Latitude__s <> NULL && 
                    selectedQuote.Jobsite__r.Latitude_Longitude__Longitude__s <> NULL
                ){
                    atpReqObj.latitude = selectedQuote.Jobsite__r.Latitude_Longitude__Latitude__s;
                    atpReqObj.longitude = selectedQuote.Jobsite__r.Latitude_Longitude__Longitude__s;
                    atpReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_JOBSITE;
                    // SAL-25138
                    System.debug('********** selectedQuote.Jobsite__r.Time_Zone_Id__c : '+ selectedQuote.Jobsite__r.Time_Zone_Id__c);
                    atpReqObj.timezoneId = selectedQuote.Jobsite__r.Time_Zone_Id__c;
                } else if(
                    selectedQuote.Sourcing_Branch__r <> NULL && 
                    selectedQuote.Sourcing_Branch__r.Latitude_Longitude__Latitude__s <> NULL && 
                    selectedQuote.Sourcing_Branch__r.Latitude_Longitude__Longitude__s <> NULL
                ) {
                    atpReqObj.fulfillmentType = SBR_3_0_Constants.FULFILLMENT_TYPE_CPU;
                    atpReqObj.latitude = selectedQuote.Sourcing_Branch__r.Latitude_Longitude__Latitude__s;
                    atpReqObj.longitude = selectedQuote.Sourcing_Branch__r.Latitude_Longitude__Longitude__s;
                    atpReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_BRANCH;
                    // SAL-25138
                    System.debug('********** selectedQuote.Sourcing_Branch__r.Time_Zone_Id__c : '+ selectedQuote.Sourcing_Branch__r.Time_Zone_Id__c);
                    atpReqObj.timezoneId = selectedQuote.Sourcing_Branch__r.Time_Zone_Id__c;
                } else if(selectedQuote.Branch__r <> NULL && 
                        selectedQuote.Branch__r.Latitude_Longitude__Latitude__s <> NULL && 
                        selectedQuote.Branch__r.Latitude_Longitude__Longitude__s <> NULL)
                {
                    atpReqObj.latitude = selectedQuote.Branch__r.Latitude_Longitude__Latitude__s;
                    atpReqObj.longitude = selectedQuote.Branch__r.Latitude_Longitude__Longitude__s;
                    atpReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_BRANCH;
                    // SAL-25138
                    System.debug('********** selectedQuote.Branch__r.Time_Zone_Id__c : '+ selectedQuote.Branch__r.Time_Zone_Id__c);
                    atpReqObj.timezoneId = selectedQuote.Branch__r.Time_Zone_Id__c;
                }
            } else if(selectedQuote.SBQQ__DeliveryMethod__c == 'Pickup' ){
                atpReqObj.fulfillmentType = SBR_3_0_Constants.FULFILLMENT_TYPE_CPU; 
                if(selectedQuote.Sourcing_Branch__r <> NULL && selectedQuote.Sourcing_Branch__r.Latitude_Longitude__Latitude__s <> NULL && 
                    selectedQuote.Sourcing_Branch__r.Latitude_Longitude__Longitude__s <> NULL){
                    atpReqObj.latitude = selectedQuote.Sourcing_Branch__r.Latitude_Longitude__Latitude__s;
                    atpReqObj.longitude = selectedQuote.Sourcing_Branch__r.Latitude_Longitude__Longitude__s;
                    atpReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_BRANCH;
                    // SAL-25138
                    System.debug('********** selectedQuote.Sourcing_Branch__r.Time_Zone_Id__c : '+ selectedQuote.Sourcing_Branch__r.Time_Zone_Id__c);
                    atpReqObj.timezoneId = selectedQuote.Sourcing_Branch__r.Time_Zone_Id__c;
                }
            } else {
                List<Schema.Location> userLocation = SBR_3_0_BranchDA.getLoggedInUserLocation();
                Datetime myDateTime = Datetime.now();
                formatted = myDateTime.formatGmt(SBR_3_0_Constants.INT_DATE_FORMAT); 
                atpReqObj.requestedDeliveryDate = formatted;
                if(userLocation[0].Latitude_Longitude__Latitude__s <> NULL && userLocation[0].Latitude_Longitude__longitude__s <> NULL){
                    atpReqObj.latitude = userLocation[0].Latitude_Longitude__Latitude__s;
                    atpReqObj.longitude = userLocation[0].Latitude_Longitude__longitude__s;
                    atpReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_BRANCH;
                    // SAL-25138
                    System.debug('********** userLocation[0].Time_Zone_Id__c : '+ userLocation[0].Time_Zone_Id__c);
                    atpReqObj.timezoneId = userLocation[0].Time_Zone_Id__c;
                }
            }
            // SAL-24258 - End
        } else if (objectName == 'Order'){
            Order selectedOrder = SBR_3_0_OrderDA.getOrders(new Set<Id>{objectId}).values()[0];
            //SAL-24240
            if(!selectedOrder.OMS_Sourcing_Enabled__c){
                return null;
            }
            String formatted = selectedOrder.Start_Date__c.formatGmt(SBR_3_0_Constants.INT_DATE_FORMAT); 
            atpReqObj.requestedDeliveryDate = formatted;
            // SAL-24258 - Start
            if(selectedOrder.Deliverymethod__c == 'Delivery' && selectedOrder.OMS_Sourcing_Enabled__c){
                if(selectedOrder.Jobsite__r.Latitude_Longitude__Latitude__s <> NULL && 
                    selectedOrder.Jobsite__r.Latitude_Longitude__Longitude__s <> NULL){
                        atpReqObj.latitude = selectedOrder.Jobsite__r.Latitude_Longitude__Latitude__s;
                        atpReqObj.longitude = selectedOrder.Jobsite__r.Latitude_Longitude__Longitude__s;
                        atpReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_JOBSITE;
                        // SAL-25138
                        System.debug('********** selectedOrder.Jobsite__r.Time_Zone_Id__c : '+ selectedOrder.Jobsite__r.Time_Zone_Id__c);
                        atpReqObj.timezoneId = selectedOrder.Jobsite__r.Time_Zone_Id__c;
                }else if(selectedOrder.Sourcing_Branch__r <> NULL && 
                        selectedOrder.Sourcing_Branch__r.Latitude_Longitude__Latitude__s <> NULL && 
                        selectedOrder.Sourcing_Branch__r.Latitude_Longitude__Longitude__s <> NULL)
                {
                    atpReqObj.latitude = selectedOrder.Sourcing_Branch__r.Latitude_Longitude__Latitude__s;
                    atpReqObj.longitude = selectedOrder.Sourcing_Branch__r.Latitude_Longitude__Longitude__s;
                    atpReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_BRANCH;
                    // SAL-25138
                    System.debug('********** selectedOrder.Sourcing_Branch__r.Time_Zone_Id__c : '+ selectedOrder.Sourcing_Branch__r.Time_Zone_Id__c);
                    atpReqObj.timezoneId = selectedOrder.Sourcing_Branch__r.Time_Zone_Id__c;
                } else if(selectedOrder.Branch__r <> NULL && 
                        selectedOrder.Branch__r.Latitude_Longitude__Latitude__s <> NULL && 
                        selectedOrder.Branch__r.Latitude_Longitude__Longitude__s <> NULL)
                {
                    atpReqObj.latitude = selectedOrder.Branch__r.Latitude_Longitude__Latitude__s;
                    atpReqObj.longitude = selectedOrder.Branch__r.Latitude_Longitude__Longitude__s;
                    atpReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_BRANCH;
                    // SAL-25138
                    System.debug('********** selectedOrder.Branch__r.Time_Zone_Id__c : '+ selectedOrder.Branch__r.Time_Zone_Id__c);
                    atpReqObj.timezoneId = selectedOrder.Branch__r.Time_Zone_Id__c;
                }
            } else if(selectedOrder.Deliverymethod__c == 'Pickup'){
                atpReqObj.fulfillmentType = SBR_3_0_Constants.FULFILLMENT_TYPE_CPU;
                if(selectedOrder.Sourcing_Branch__r <> NULL && selectedOrder.Sourcing_Branch__r.Latitude_Longitude__Latitude__s <> NULL && 
                    selectedOrder.Sourcing_Branch__r.Latitude_Longitude__Longitude__s <> NULL){

                    atpReqObj.latitude = selectedOrder.Sourcing_Branch__r.Latitude_Longitude__Latitude__s;
                    atpReqObj.longitude = selectedOrder.Sourcing_Branch__r.Latitude_Longitude__Longitude__s;
                    atpReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_BRANCH;
                    // SAL-25138
                    System.debug('********** selectedOrder.Sourcing_Branch__r.Time_Zone_Id__c : '+ selectedOrder.Sourcing_Branch__r.Time_Zone_Id__c);
                    atpReqObj.timezoneId = selectedOrder.Sourcing_Branch__r.Time_Zone_Id__c;
                }
            } else {
                List<Schema.Location> userLocation = SBR_3_0_BranchDA.getLoggedInUserLocation();
                Datetime myDateTime = Datetime.now();
                formatted = myDateTime.formatGmt(SBR_3_0_Constants.INT_DATE_FORMAT); 
                atpReqObj.requestedDeliveryDate = formatted;
                if(userLocation[0].Latitude_Longitude__Latitude__s <> NULL && userLocation[0].Latitude_Longitude__longitude__s <> NULL){
                    atpReqObj.latitude = userLocation[0].Latitude_Longitude__Latitude__s;
                    atpReqObj.longitude = userLocation[0].Latitude_Longitude__longitude__s;
                    atpReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_BRANCH;
                    // SAL-25138
                    System.debug('********** userLocation[0].Time_Zone_Id__c : '+ userLocation[0].Time_Zone_Id__c);
                    atpReqObj.timezoneId = userLocation[0].Time_Zone_Id__c;
                }
            }
            // SAL-24258 - End
        } else {   // For Product Inquiry
            List<Schema.Location> userLocation = SBR_3_0_BranchDA.getLoggedInUserProfileBranchLocation();
            if(userLocation.size() == 0) {
               userLocation = userProfileLocation;  
            }
            //SAL-24240
            //SAL-26846   - Need to look at User location. If it is OMS enabled, user needs to see OMS behaviour on spotlight panel
            if(!userProfileLocation[0].OMS_Sourcing_Enabled__c ){  
                return null;
            }

            // SF-6355 - default fulfillment type = CPU for PI requests
            atpReqObj.fulfillmentType = SBR_3_0_Constants.FULFILLMENT_TYPE_CPU;
            
            // SAL-24311
            Datetime myDateTime;
            String formatted;
            if(objectName == 'Cart__c')
            {
                Cart__c currentCart = SBR_3_0_CartDA.getCart(objectId);
                myDateTime = (currentCart.Rental_Start_Date__c!=null ?currentCart.Rental_Start_Date__c:Datetime.now())  ;
                formatted = myDateTime.formatGmt(SBR_3_0_Constants.INT_DATE_FORMAT); 

            }
            else {
                myDateTime = Datetime.now();
                formatted = myDateTime.formatGmt(SBR_3_0_Constants.INT_DATE_FORMAT); 
            }
            
            atpReqObj.requestedDeliveryDate = formatted;
            if(userLocation[0].Latitude_Longitude__Latitude__s <> NULL && userLocation[0].Latitude_Longitude__longitude__s <> NULL){
                atpReqObj.latitude = userLocation[0].Latitude_Longitude__Latitude__s;
                atpReqObj.longitude = userLocation[0].Latitude_Longitude__longitude__s;
                atpReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_BRANCH;
                // SAL-25138
                System.debug('********** userLocation[0].Time_Zone_Id__c : '+ userLocation[0].Time_Zone_Id__c);
                atpReqObj.timezoneId = userLocation[0].Time_Zone_Id__c;
            }
        } 

        SBR_3_0_WrapInventoryAtBranch.Products p = new SBR_3_0_WrapInventoryAtBranch.Products();
        p.uom = 'EA';
        p.productId = catClass;
        List<SBR_3_0_WrapInventoryAtBranch.Products> products = new list<SBR_3_0_WrapInventoryAtBranch.Products>();
        products.add(p);
        atpReqObj.products = products;
        
        System.debug('getATP obj: ' + JSON.serializePretty(atpReqObj));
        SBR_3_0_WrapInventoryAtBranch.ATPResponse response = SBR_3_0_API_FetchInventoryAtBranch.getInventoryAtBranch(atpReqObj,companyCode);
        System.debug('getATP response: ' + response);
        return response;
    }

    @AuraEnabled
    public static String getATI(Id objectId, String catClassesJSON){
        SBR_3_0_WrapAlternateItems.ATIRequest atiReqObj = new SBR_3_0_WrapAlternateItems.ATIRequest();
        API_ATP_Config__mdt atpFieldConfig = SBR_3_0_CustomMetadata_DA.getATPApiConfig('Prod_Inquiry');

        System.debug('catClassesJSON -> ' + catClassesJSON);
        String objectName = '';
        if(String.isNotBlank(objectId)) {
            objectName = objectId.getSObjectType().getDescribe().getName();
        }
        
        User u = [SELECT CompanyName FROM User WHERE Id = :UserInfo.getUserId()];
        
        atiReqObj.cartId = SBR_3_0_Constants.SELLING_CHANNEL;
        atiReqObj.fulfillmentType = SBR_3_0_Constants.ATP_FULFILLMENTTYPE_DELIVERY;
        atiReqObj.transactionType = SBR_3_0_Constants.ATP_TRANSACTIONTYPE_ALL;
        atiReqObj.sellingChannel = SBR_3_0_Constants.SELLING_CHANNEL;
        atiReqObj.includeZeroATP = atpFieldConfig.Include_Zero_ATP__c;
        //obj.limitBranchByDistanceCount = limitBranchByDistanceCount;
        if (objectName == 'SBQQ__Quote__c'){
            SBQQ__Quote__c selectedQuote = SBR_3_0_QuoteDA.getQuotes(new Set<Id>{objectId}).values()[0];
            //SAL-24240
            if(!selectedQuote.OMS_Sourcing_Enabled__c){
                return null;
            }
            String formatted = selectedQuote.Start_Date__c.formatGmt(SBR_3_0_Constants.INT_DATE_FORMAT); 
            atiReqObj.requestedDeliveryDate = formatted;

            // SAL-24258 - Start
            if(selectedQuote.SBQQ__DeliveryMethod__c == 'Delivery' && selectedQuote.OMS_Sourcing_Enabled__c){
                if(selectedQuote.Jobsite__r.Latitude_Longitude__Latitude__s <> NULL && 
                    selectedQuote.Jobsite__r.Latitude_Longitude__Longitude__s <> NULL)
                    {
                        atiReqObj.latitude = selectedQuote.Jobsite__r.Latitude_Longitude__Latitude__s;
                        atiReqObj.longitude = selectedQuote.Jobsite__r.Latitude_Longitude__Longitude__s;
                        atiReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_JOBSITE;
                        // SAL-25138
                        System.debug('********** selectedQuote.Jobsite__r.Time_Zone_Id__c : '+ selectedQuote.Jobsite__r.Time_Zone_Id__c);
                        atiReqObj.timezoneId = selectedQuote.Jobsite__r.Time_Zone_Id__c;
                    } else if(selectedQuote.Sourcing_Branch__r <> NULL && 
                            selectedQuote.Sourcing_Branch__r.Latitude_Longitude__Latitude__s <> NULL && 
                            selectedQuote.Sourcing_Branch__r.Latitude_Longitude__Longitude__s <> NULL)
                    {
                        atiReqObj.latitude = selectedQuote.Sourcing_Branch__r.Latitude_Longitude__Latitude__s;
                        atiReqObj.longitude = selectedQuote.Sourcing_Branch__r.Latitude_Longitude__Longitude__s;
                        atiReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_BRANCH;
                        // SAL-25138
                        System.debug('********** selectedQuote.Sourcing_Branch__r.Time_Zone_Id__c : '+ selectedQuote.Sourcing_Branch__r.Time_Zone_Id__c);
                        atiReqObj.timezoneId = selectedQuote.Sourcing_Branch__r.Time_Zone_Id__c;
                    } else if(selectedQuote.Branch__r <> NULL && 
                            selectedQuote.Branch__r.Latitude_Longitude__Latitude__s <> NULL && 
                            selectedQuote.Branch__r.Latitude_Longitude__Longitude__s <> NULL)
                    {
                        atiReqObj.latitude = selectedQuote.Branch__r.Latitude_Longitude__Latitude__s;
                        atiReqObj.longitude = selectedQuote.Branch__r.Latitude_Longitude__Longitude__s;
                        atiReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_BRANCH;
                        // SAL-25138
                        System.debug('********** selectedQuote.Branch__r.Time_Zone_Id__c : '+ selectedQuote.Branch__r.Time_Zone_Id__c);
                        atiReqObj.timezoneId = selectedQuote.Branch__r.Time_Zone_Id__c;
                    }
            } else if(selectedQuote.SBQQ__DeliveryMethod__c == 'Pickup'){
                atiReqObj.fulfillmentType = SBR_3_0_Constants.FULFILLMENT_TYPE_CPU;
                if(selectedQuote.Sourcing_Branch__r <> NULL && selectedQuote.Sourcing_Branch__r.Latitude_Longitude__Latitude__s <> NULL && 
                    selectedQuote.Sourcing_Branch__r.Latitude_Longitude__Longitude__s <> NULL){

                    atiReqObj.latitude = selectedQuote.Sourcing_Branch__r.Latitude_Longitude__Latitude__s;
                    atiReqObj.longitude = selectedQuote.Sourcing_Branch__r.Latitude_Longitude__Longitude__s;
                    atiReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_BRANCH;
                    // SAL-25138
                    System.debug('********** selectedQuote.Sourcing_Branch__r.Time_Zone_Id__c : '+ selectedQuote.Sourcing_Branch__r.Time_Zone_Id__c);
                    atiReqObj.timezoneId = selectedQuote.Sourcing_Branch__r.Time_Zone_Id__c;
                }
            } else {
                List<Schema.Location> userLocation = SBR_3_0_BranchDA.getLoggedInUserLocation();
                Datetime myDateTime = Datetime.now();
                formatted = myDateTime.formatGmt(SBR_3_0_Constants.INT_DATE_FORMAT); 
                atiReqObj.requestedDeliveryDate = formatted;
                if(userLocation[0].Latitude_Longitude__Latitude__s <> NULL && userLocation[0].Latitude_Longitude__longitude__s <> NULL){
                    atiReqObj.latitude = userLocation[0].Latitude_Longitude__Latitude__s;
                    atiReqObj.longitude = userLocation[0].Latitude_Longitude__longitude__s;
                    atiReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_BRANCH;
                    // SAL-25138
                    System.debug('********** userLocation[0].Time_Zone_Id__c : '+ userLocation[0].Time_Zone_Id__c);
                    atiReqObj.timezoneId = userLocation[0].Time_Zone_Id__c;
                }
            }
            // SAL-24258 - End
        } else if (objectName == 'Order'){
            Order selectedOrder = SBR_3_0_OrderDA.getOrders(new Set<Id>{objectId}).values()[0];
            if(!selectedOrder.OMS_Sourcing_Enabled__c){
                return null;
            }
            String formatted = selectedOrder.Start_Date__c.formatGmt(SBR_3_0_Constants.INT_DATE_FORMAT); 
            atiReqObj.requestedDeliveryDate = formatted;
            // SAL-24258 - Start
            if(selectedOrder.Deliverymethod__c == 'Delivery' && selectedOrder.OMS_Sourcing_Enabled__c){
                if(selectedOrder.Jobsite__r.Latitude_Longitude__Latitude__s <> NULL && 
                    selectedOrder.Jobsite__r.Latitude_Longitude__Longitude__s <> NULL){
                        atiReqObj.latitude = selectedOrder.Jobsite__r.Latitude_Longitude__Latitude__s;
                        atiReqObj.longitude = selectedOrder.Jobsite__r.Latitude_Longitude__Longitude__s;
                        atiReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_JOBSITE;
                        // SAL-25138
                        System.debug('********** selectedOrder.Jobsite__r.Time_Zone_Id__c : '+ selectedOrder.Jobsite__r.Time_Zone_Id__c);
                        atiReqObj.timezoneId = selectedOrder.Jobsite__r.Time_Zone_Id__c;
                }else if(selectedOrder.Sourcing_Branch__r <> NULL && 
                        selectedOrder.Sourcing_Branch__r.Latitude_Longitude__Latitude__s <> NULL && 
                        selectedOrder.Sourcing_Branch__r.Latitude_Longitude__Longitude__s <> NULL)
                {
                    atiReqObj.latitude = selectedOrder.Sourcing_Branch__r.Latitude_Longitude__Latitude__s;
                    atiReqObj.longitude = selectedOrder.Sourcing_Branch__r.Latitude_Longitude__Longitude__s;
                    atiReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_BRANCH;
                    // SAL-25138
                    System.debug('********** selectedOrder.Sourcing_Branch__r.Time_Zone_Id__c : '+ selectedOrder.Sourcing_Branch__r.Time_Zone_Id__c);
                    atiReqObj.timezoneId = selectedOrder.Sourcing_Branch__r.Time_Zone_Id__c;
                } else if(selectedOrder.Branch__r <> NULL && 
                        selectedOrder.Branch__r.Latitude_Longitude__Latitude__s <> NULL && 
                        selectedOrder.Branch__r.Latitude_Longitude__Longitude__s <> NULL)
                {
                    atiReqObj.latitude = selectedOrder.Branch__r.Latitude_Longitude__Latitude__s;
                    atiReqObj.longitude = selectedOrder.Branch__r.Latitude_Longitude__Longitude__s;
                    atiReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_BRANCH;
                    // SAL-25138
                    System.debug('********** selectedOrder.Branch__r.Time_Zone_Id__c : '+ selectedOrder.Branch__r.Time_Zone_Id__c);
                    atiReqObj.timezoneId = selectedOrder.Branch__r.Time_Zone_Id__c;
                }
            } else if(selectedOrder.Deliverymethod__c == 'Pickup'){
                atiReqObj.fulfillmentType = SBR_3_0_Constants.FULFILLMENT_TYPE_CPU;
                if(selectedOrder.Sourcing_Branch__r <> NULL && selectedOrder.Sourcing_Branch__r.Latitude_Longitude__Latitude__s <> NULL && 
                    selectedOrder.Sourcing_Branch__r.Latitude_Longitude__Longitude__s <> NULL){

                    atiReqObj.latitude = selectedOrder.Sourcing_Branch__r.Latitude_Longitude__Latitude__s;
                    atiReqObj.longitude = selectedOrder.Sourcing_Branch__r.Latitude_Longitude__Longitude__s;
                    atiReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_BRANCH;
                    // SAL-25138
                    System.debug('********** selectedOrder.Sourcing_Branch__r.Time_Zone_Id__c : '+ selectedOrder.Sourcing_Branch__r.Time_Zone_Id__c);
                    atiReqObj.timezoneId = selectedOrder.Sourcing_Branch__r.Time_Zone_Id__c;
                }
            } else {
                List<Schema.Location> userLocation = SBR_3_0_BranchDA.getLoggedInUserLocation();
                Datetime myDateTime = Datetime.now();
                formatted = myDateTime.formatGmt(SBR_3_0_Constants.INT_DATE_FORMAT); 
                atiReqObj.requestedDeliveryDate = formatted;
                if(userLocation[0].Latitude_Longitude__Latitude__s <> NULL && userLocation[0].Latitude_Longitude__longitude__s <> NULL){
                    atiReqObj.latitude = userLocation[0].Latitude_Longitude__Latitude__s;
                    atiReqObj.longitude = userLocation[0].Latitude_Longitude__longitude__s;
                    atiReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_BRANCH;
                    // SAL-25138
                    System.debug('********** userLocation[0].Time_Zone_Id__c : '+ userLocation[0].Time_Zone_Id__c);
                    atiReqObj.timezoneId = userLocation[0].Time_Zone_Id__c;
                }
            }
            // SAL-24258 - End
        } else { // Product Inquiry
            List<Schema.Location> userLocation = SBR_3_0_BranchDA.getLoggedInUserLocation();
            if(!userLocation[0].OMS_Sourcing_Enabled__c){
                return null;
            }
            // SAL-24311
            Datetime myDateTime;
            String formatted;
            if(objectName == 'Cart__c')
            {
                Cart__c currentCart = SBR_3_0_CartDA.getCart(objectId);
                 myDateTime = (currentCart.Rental_Start_Date__c!=null ?currentCart.Rental_Start_Date__c:Datetime.now())  ;
                 formatted = myDateTime.formatGmt(SBR_3_0_Constants.INT_DATE_FORMAT); 

            }
            else {
                          myDateTime = Datetime.now();
                          formatted = myDateTime.formatGmt(SBR_3_0_Constants.INT_DATE_FORMAT); 
            }
            
            atiReqObj.requestedDeliveryDate = formatted;
            if(userLocation[0].Latitude_Longitude__Latitude__s <> NULL && userLocation[0].Latitude_Longitude__longitude__s <> NULL){
                atiReqObj.latitude = userLocation[0].Latitude_Longitude__Latitude__s;
                atiReqObj.longitude = userLocation[0].Latitude_Longitude__longitude__s;
                atiReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_BRANCH;
                // SAL-25138
                System.debug('********** userLocation[0].Time_Zone_Id__c : '+ userLocation[0].Time_Zone_Id__c);
                atiReqObj.timezoneId = userLocation[0].Time_Zone_Id__c;
            }
        }

        List<SBR_3_0_WrapAlternateItems.Products> productsList = new List<SBR_3_0_WrapAlternateItems.Products>();

        List<String> catClassList = (List<String>) JSON.deserialize(catClassesJSON, List<String>.class);

        for(String cc : catClassList) {
            SBR_3_0_WrapAlternateItems.Products p = new SBR_3_0_WrapAlternateItems.Products();
            p.uom = 'EA';
            p.productId = cc;
            productsList.add(p);
        }
        atiReqObj.products = productsList;

        String response = getAltInventory(JSON.serialize(atiReqObj), u.CompanyName);

        return response;
    }

    @AuraEnabled(cacheable = true)
    public static String getAltInventory(String ATIRequest, String companyCode){
        system.debug('ATIRequest: ' + ATIRequest);
        SBR_3_0_WrapAlternateItems.ATIRequest obj = (SBR_3_0_WrapAlternateItems.ATIRequest) System.JSON.deserialize(ATIRequest, SBR_3_0_WrapAlternateItems.ATIRequest.class);
        system.debug('obj: ' + obj);
        try{
            SBR_3_0_WrapAlternateItems.ATIResponse resp = SBR_3_0_API_FetchAlternateItems.getAlternateItems(obj, companyCode);
            system.debug('Response:' + System.JSON.serialize(resp));
            return System.JSON.serialize(resp);
        } catch (Exception e){
            system.debug('Exception:' + e);
            return null;
        }
    }

    @AuraEnabled(Cacheable = true)
    public static String getBranchId(String branchNumber) {
        String branchId;

        if (String.isNotBlank(branchNumber)) {
            List<Schema.Location> branch = [SELECT Id FROM Location WHERE Branch_Location_Number__c = :branchNumber];
            if (!branch.isEmpty()) {
                branchId = branch[0].Id;
            }
        }

        return branchId;
    }
}