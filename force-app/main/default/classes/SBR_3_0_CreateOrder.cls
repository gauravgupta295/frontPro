/**
 * 
 * @author 
 * @description SBR_3_0_CreateOrder
 */
public with sharing class SBR_3_0_CreateOrder {
    
    public Savepoint databaseSavePoint {get; set;}
    
    private static WrapOrder wor = new WrapOrder();
    private static final String CONTRACT_TYPE ='ContractOrder';
    private static final String RESERVATION_TYPE ='ReservationOrder';
    private static final String SALES_TYPE = 'SalesOrder';
    private static final String DELIVERY_METHOD_DELIVERY = 'Delivery';
    private static final String DELIVERY_METHOD_PICKUP = 'Pickup';
    private static final String STATUS_DRAFT = 'Draft';
    private static final String STATUS_OPEN = 'Open'; //BD SAL-26179
    private static final String SOBJECT_ORDER = 'Order';
    private static final String DELIVERY = 'DELIVERY';
    private static final String PICKUP = 'PICKUP';
   
    private static String branchTimeZoneOffset;
    private static Set<String> assetNumbers;
    private static String genericProductSku='';

    private Order inOrder; //Inbound Order details to upsert 
    private List<Order_Item_Detail__c> inLineDetails;

    
    private static Boolean isNew = false;
    private static Boolean isContract = false;
    private static Boolean staleInboundOrder = false;
    private static Boolean hasAccountChanged = false;
    private static Boolean hasJobSiteChanged = false;
    private static Boolean hasBranchChanged = false;
    //sales rep, 
    private static Boolean hasPrimarySaleRepChanged = false;
    private static Boolean hasSecSaleRepChanged = false;
    private String lineCompositeKey ='';
   
    private Boolean lockTotals = false; //BD SAL-26179
    private Map<String, Boolean> isLineItemHiddenMap = new Map<String, Boolean>();
    private Map<String, Boolean> isAssetItemHiddenMap = new Map<String, Boolean>();
    private Map<String,OrderItem> lineItemExistsMap = new Map<String,OrderItem>();//SAL-23832
    private static String uniqueRMAccountNumber; // PS-5602:SG:05222024
    /**
     * 
     * @param req 
     * @description SBR_3_0_CreateOrder
     */
    public SBR_3_0_CreateOrder(String req) {
        wor = (WrapOrder) JSON.deserialize(req, WrapOrder.class);
        inOrder = (Order)JSON.deserializeStrict(JSON.serialize(wor.data), Order.class); //inbound Order
        //PS-5602:SG:05222024: To check if the incoming payloads rmAccount # has company code appended, if so use it other wise append the company code to the rmAccount #. 
        if(wor!=null && String.isNotBlank(wor.rmAccountNumber) && String.isNotBlank(wor.data.Company_Code__c))
            uniqueRMAccountNumber = (wor.rmAccountNumber.startsWith(wor.data.Company_Code__c + '-')) ? wor.rmAccountNumber : wor.data.Company_Code__c + '-' +  wor.rmAccountNumber;

        setAggregatedStatuses();
    }

    /**
     * 
     * @return  `String`
     * @description syncOrderToSF
     */
    public Id syncOrderToSF() {
        //This (apparently) is to call the getter, which will then set a "isNew" boolean, that prevents a null pointer exception from happening.
        Order existing = sfOrder; //NOPMD
        return loadOrder();
    }
    
    private Id loadOrder() {
        Savepoint sp = null;
        
        if(!Schema.sObjectType.OrderItem.isCreateable() ||
            !Schema.sObjectType.OrderItem.isUpdateable() ||
            !Schema.sObjectType.Order.isCreateable() ||
            !Schema.sObjectType.Order.isUpdateable() ||
            !Schema.sObjectType.OrderItem.isDeletable()){
            //For AuraHandled exceptions, you have to call the setMessage method on it explicity for odd reasons.
            String message = 'Insufficent permissions on Order or Order Item records. Need create, update access on both objects and delete access on order items to continue.';
            AuraHandledException insufficientEx = new AuraHandledException(message);
            insufficientEx.setMessage(message);
            throw insufficientEx;
        }
        
        SBQQ__Quote__c updateQuoteRecord;
        //PS-5942:SG:05202024: Included the hasAccountChanged check to accomodate the RM logic of Account changes on an existing Order. 
        inOrder.AccountId = (isNew || hasAccountChanged) ? relAcct.Id : sfOrder.AccountId;     //Relate Account
        inOrder.Branch__c = (isNew || sfOrder.Branch__c == null) ? branchId : sfOrder.Branch__c;   //Relate Branch
        inOrder.Sourcing_Branch__c = branchId;
        if(inOrder.Branch__c == null) { throw new SBR_3_0_CustomException('Branch not found!'); }
        inOrder.Status = isNew ? STATUS_DRAFT : sfOrder.Status;
        inOrder.Type = wor.type;
        inOrder.RM_Sales_Rep_Id__c = wor.primarySalesRep ; //23889
        inOrder.Sales_Rep__c = (salesRepUserIds !=null && salesRepUserIds.containsKey(wor.primarySalesRep)) ? salesRepUserIds.get(wor.primarySalesRep).Id : null ; //Relate Sales Reps
        inOrder.Secondary_Rep__c = (salesRepUserIds !=null && salesRepUserIds.containsKey(wor.secondarySalesRep)) ? salesRepUserIds.get(wor.secondarySalesRep).Id : null;
        
        //inOrder.Jobsite__c = (jobSite != null) ? jobSite.Id : createJobSite(inOrder).Id; //assign jobsiteId or create one        
        inOrder.Reservation_Order_Number__c = wor.reservationNumber; 
        //SF-7107,SF-7105
        if(String.isBlank(inOrder.Rentalman_Quote_Id__c)){
            inOrder.Rentalman_Quote_Id__c = String.isNotBlank(wor.reservationNumber) ? wor.reservationNumber : ''; //SF-7187 Order.Rentalman_Quote_Id__c same value as Reservation_Order_Number__c
        }
        inOrder.Contract_Order_Number__c = wor.contractNumber;
        inOrder.Time_zone_offset__c = isNew || (!isNew && hasBranchChanged) ?branchTimeZoneOffset : sfOrder.Time_zone_offset__c; ////updating timezone offset  - SAL 13797 : Davinder Singh
        inOrder.CurrencyISOCode = inOrder.CurrencyIsoCode__c;
        
        // SF-6820: If RM Id is not present, do not update the Quote lookup
        String relatedQuoteId = getRelatedQuote(); 
        if(String.isNotBlank(relatedQuoteId)) {
            inOrder.SBQQ__Quote__c =  relatedQuoteId;  
        }
             
        inOrder.Pricebook2Id = [SELECT id from Pricebook2 where Name ='Standard Price Book' Limit 1].Id;  
        if(!isNew && String.isNotBlank(wor.contractNumber) && (wor.type == CONTRACT_TYPE)  &&  sfOrder.Status ==  STATUS_OPEN){ //BD SAL-26179
            inOrder.Lock_Initial_Totals__c = true;
            lockTotals = true;
        }
        
        Map<String, OrderItem> linesToUpsert = new Map<String, OrderItem>();
        List<OrderItem> linesToDelete = new List<OrderItem>();
        
        //processLineItems no longer inserts the records.  Instead, it takes instanciated lists and adds the line items to them
        //For insert / deletions later in this method.
        //The reason for this is to handle order header / specific pricing calculation, so that we don't need to re-update
        //The order record after the order items are created.
        processLineItems(linesToUpsert, linesToDelete);    
        
        Integer queriesBeforeOrder = Limits.getQueries();
        if(isNew) {
            inOrder.RecordTypeId = getOrderRecordTypeId();  // Record type is only updated for new orders
            inOrder.Order_Initiating_Channel__c = 'RM'; //SF-6471 
            inOrder.Created_By_Users_Branch__c = inOrder.Sourcing_Branch__c;
        }
        inOrder.id = sfOrder.id;
        
        if(!lockTotals && 'true' != wor.preventTaxCalculation){
            SBR_3_0_API_Contract_OpenOrderTaxUpdate.updateOrderAndOrderItemTaxes(inOrder, linesToUpsert);
        }
        
        try{
            //Set savepoint, after callout but prior to DML operations.
            sp = Database.setSavepoint();
            
            //The create job site and job location does some record insert logic, which needs to run after the callout.
            inOrder.Jobsite__c = (jobSite != null) ? jobSite.Id : createJobSite(inOrder).Id; //assign jobsiteId or create one        
        
            //This ordered by call may result in the creation of a contact record, therefore, it was moved *after* the update order taxes.
            inOrder = setOrderedBy(inOrder); 
        
            upsert inOrder Id;
            
            //DO NOT CHANGE the order of these DML operations.
            Integer queriesBeforeDelete = Limits.getQueries();
            delete linesToDelete; //first delete the lines
                
            System.debug('Total queries used in order item delete: ' + (Limits.getQueries() - queriesBeforeDelete));
            for(OrderItem oi : linesToUpsert.values()){
                if(oi.OrderId == null){
                    oi.OrderId = inOrder.Id;
                }
            }
            
            Integer queriesBeforeLineItems = Limits.getQueries(); //NOPMD
            upsert linesToUpsert.values() Line_Composite_Key__c;
            System.debug('Total queries used in order item upsert: ' + (Limits.getQueries() - queriesBeforeLineItems));
        }catch(Exception error){
            Database.rollback(sp);
            throw error;
        }
        
        return inOrder.Id;
    }

    //Add, Update or Delete line items
    private void processLineItems(Map<String, OrderItem> linesToUpsert, List<OrderItem> linesToDelete){
        Map<String, Decimal> miscCharges= new Map<String, Decimal>();
        Map<String,PricebookEntry> pricebookEntries = getPricebookEntryMap();
        
        //Loop through line items supplied in the request and add/update/delete 
        for(WrapOrderItem lineData: wor.linedata){
            //Delete item if cancelled
            OrderItem line = lineData.data;
            
            inOrder.Is_Specific_Pricing_Flag__c |=  
                (SBR_3_0_Constants.CUSTOMER_LOADED_SPECIFIC_PRICING_TYPE == line.Specific_Pricing_Type__c);
            
            inOrder.Specific_Pricing_Flag__c |= line.Specific_Pricing_Flag__c;
                                                       
            setLineItemStatuses(line);
            line.Line_Composite_Key__c = getCompositeKey(lineData.data.Global_Line_Number__c); //Set Composite key
            line.OrderId = inOrder.Id; //Set Order Id
            if(String.isBlank(line.Branch_Location_Number__c)) { line.Branch_Location_Number__c = wor.branchNumber; } //set branch info to Order's branch if not sent via integration
            line.Quantity = getQuantity(line);
            line.is_Line_Item_Hidden__c = isLineItemHiddenMap.containsKey(line.Line_Composite_Key__c)? isLineItemHiddenMap.get(line.Line_Composite_Key__c): false;
            line.is_Asset_Item_Hidden__c = isAssetItemHiddenMap.containsKey(line.Line_Composite_Key__c)? isAssetItemHiddenMap.get(line.Line_Composite_Key__c): false;

            if (line.Status_Closed_Qty__c == line.Quantity) { // SF-6406
                line.SBQQ__Asset__c = null; //SF-5865 if closed qty is 1 then this will be true for serialized return, set the asset lookup to null
                line.is_Asset_Item_Hidden__c = true;
            } 
            // SF-6549: If asset number starts with 'RR', it is the case of Re-Rent items. In this case, store it in a custom field as the corresponding asset does not exist in SF.
            else if (!String.IsBlank(lineData.assetNumber) && lineData.assetNumber.startsWith('RR')){
                line.Re_rent_Asset_Number__c = lineData.assetNumber;    
            }
            else if (!String.IsBlank(lineData.assetNumber)) {
                line.SBQQ__Asset__c = getAssetId(lineData.assetNumber); //Get Asset;
            }
            
            //Assign default product to delivery line item, SAL-25998
            if(lineData.productSKU == '0000000') {
                if(line.Misc_Charges_Type__c == DELIVERY || line.Misc_Charges_Type__c == 'DEL') {
                    line.Misc_Charges_Type__c = DELIVERY;
                    lineData.productSKU = DELIVERY;
                } 
                if(line.Misc_Charges_Type__c == PICKUP) {
                    lineData.productSKU = PICKUP;
                }
            }
            
            PricebookEntry pbe = pricebookEntries.get(lineData.productSKU) ?? pricebookEntries.get('ITEMNOTFOUND');
            line.Product2Id = pbe?.Product2Id;
            line.PricebookEntryId = pbe?.Id;
            line.UnitPrice = pbe?.UnitPrice ?? 0;
            
            //Consolidate the Delivery/Pickup (and all misc charges) based on the Original Unique Global line#  SAL-26267
            if(!isNew && line.Misc_Charges_Type__c != null  && line.Original_Global_Line_Number__c != null) {
                line.Line_Composite_Key__c = getCompositeKey(lineData.data.Original_Global_Line_Number__c); 
                if(linesToUpsert.containsKey(line.Line_Composite_Key__c)) {
                    OrderItem mainDelCPUItemInThisPayload = linesToUpsert.get(line.Line_Composite_Key__c);
                    if(miscCharges.containsKey(line.Line_Composite_Key__c)){
                        mainDelCPUItemInThisPayload.Selling_Price__c += miscCharges.get(line.Line_Composite_Key__c);
                    }
                    else{
                        Decimal existingCharge = sfLines.containsKey(line.Line_Composite_Key__c) ? sfLines.get(line.Line_Composite_Key__c).Selling_Price__c : null;
                        if(existingCharge != null) {
                            mainDelCPUItemInThisPayload.Selling_Price__c += existingCharge;
                        }
                        miscCharges.put(line.Line_Composite_Key__c, mainDelCPUItemInThisPayload.Selling_Price__c);
                    }
                    continue; //skip the rest and to next iteration since don't need this line as it's being consolidated
                }
            }

            if(line.PricebookEntryId == null) {throw new SBR_3_0_CustomException ('PriceBookEntry not found for Product '+ lineData.productSKU + ' !');}
            if(hasProductOnTheLineChanged(line)) {
                linesToDelete.add(sfLines.get(line.Line_Composite_Key__c));
            }

            linesToUpsert.put(line.Line_Composite_Key__c, line); //Add line item to the list to upsert
        }    
    }

    private void setAggregatedStatuses() {
        inOrder.Aggregated_Status_Asset_Assigned_Qty__c = inOrder.Aggregated_Status_Asset_Assigned_Qty__c ?? 0;
        inOrder.Aggregated_Status_Asset_Pending_Qty__c = inOrder.Aggregated_Status_Asset_Pending_Qty__c ?? 0;
        inOrder.Aggregated_Status_Cancelled_Qty__c = inOrder.Aggregated_Status_Cancelled_Qty__c ?? 0;
        inOrder.Aggregated_Status_Closed_Qty__c = inOrder.Aggregated_Status_Closed_Qty__c ?? 0;
        inOrder.Aggregated_Status_Created_Qty__c = inOrder.Aggregated_Status_Created_Qty__c ?? 0;
        inOrder.Aggregated_Status_Filled_Qty__c = inOrder.Aggregated_Status_Filled_Qty__c ?? 0;
        inOrder.Aggregated_Status_Invoice_Pending_Qty__c = inOrder.Aggregated_Status_Invoice_Pending_Qty__c ?? 0;
        inOrder.Aggregated_Status_Invoiced_Qty__c = inOrder.Aggregated_Status_Invoiced_Qty__c ?? 0;
        inOrder.Aggregated_Status_Pick_Created_Qty__c = inOrder.Aggregated_Status_Pick_Created_Qty__c ?? 0;
        inOrder.Aggregated_Status_Customer_Pickup_Qty__c = inOrder.Aggregated_Status_Customer_Pickup_Qty__c ??0;
    }
    
    private void setLineItemStatuses(OrderItem oi) {
        oi.Status_Asset_Assigned_Qty__c = oi.Status_Asset_Assigned_Qty__c ?? 0;
        oi.Status_Asset_Pending_Qty__c = oi.Status_Asset_Pending_Qty__c ?? 0;
        oi.Status_Created_Qty__c = oi.Status_Created_Qty__c ?? 0;
        oi.Status_Filled_Qty__c = oi.Status_Filled_Qty__c ?? 0;
        oi.Status_Invoice_Pending_Qty__c = oi.Status_Invoice_Pending_Qty__c ?? 0;
        oi.Status_Invoiced_Qty__c = oi.Status_Invoiced_Qty__c ?? 0;
        oi.Status_Cancelled_Qty__c = oi.Status_Cancelled_Qty__c ?? 0;
        oi.Status_Closed_Qty__c = oi.Status_Closed_Qty__c ?? 0;
    }

    private static Account relAcct {
        get{
            if (relAcct == null && wor!=null && String.isNotBlank(wor.rmAccountNumber)) {   
                //if it's a new Order or Account has changed for the existing Order, query for the AccountId
                if(isNew || (isNew == false && hasAccountChanged)) {
                    // PS:5602:SG:Commented the below line as this might lead to an invalid uniqueRMAccountNumber if the payload already has company code appended to the rmAccountNumber. 
                    //String uniqueRMAccountNumber = wor.data.Company_Code__c + '-' +  wor.rmAccountNumber;
                    List<Account> accts =  new List<Account> ();
                    accts = SBR_3_0_OrderDA.getRelatedAccount(uniqueRMAccountNumber);
                    if(accts != null && accts.size()>0) {
                        relAcct = accts[0];
                        return accts[0];
                    }
                }
                else {
                    relAcct = sfOrder.Account;
                    return sfOrder.Account;
                }
                throw new SBR_3_0_CustomException('Related Account not found!');
            }
            return relAcct;
        }
        set;
    }
    
    private static Order sfOrder {
        get{
            if(sfOrder == null) {
                List<Order> recs = new List<Order>();
                
                //This simply validates that the wor.type field is set correctly.
                getOrderRecordTypeId();
                
                if(String.isNotBlank(wor.contractNumber) && (wor.type == CONTRACT_TYPE || wor.type == SALES_TYPE )) {
                    //Contract # will be present for Contract and Sales Order
                    isContract = true;
                    recs = SBR_3_0_OrderDA.getContractOrderByContractNum(wor.contractNumber, companyCode);
                }
                else if(String.isNotBlank(wor.reservationNumber) && (wor.type == RESERVATION_TYPE ))  {
                    //Reservation # will be present for Reservation Order
                    recs = SBR_3_0_OrderDA.getReservationOrderByResNum(wor.reservationNumber, companyCode);  // SAL-23458  - Removed recordType argument
                }
                else {
                    throw new SBR_3_0_CustomException (Label.ContractOrResNumberRequired);
                }
                if(recs.size() > 0) {                   
                    sfOrder = recs[0];
                    hasAccountChanged = (sfOrder.Account.RM_Account_Number__c != wor.rmAccountNumber);
                    hasBranchChanged = (sfOrder.Branch__r.Branch_Location_Number__c != wor.branchNumber);
                    hasJobSiteChanged = (String.isNotBlank(sfOrder.Jobsite__r.Job_Site_Id__c) && sfOrder.Jobsite__r.Job_Site_Id__c != wor.jobSiteId);
                    hasPrimarySaleRepChanged = (sfOrder.Sales_Rep__c != null && sfOrder.Sales_Rep__r.RepID__c != wor.primarySalesRep);
                    hasSecSaleRepChanged = (sfOrder.Secondary_Rep__c != null && wor.secondarySalesRep != null  &&  sfOrder.Secondary_Rep__r.RepID__c != wor.secondarySalesRep);
                    return sfOrder;
                }
                else {
                    sfOrder = new Order();
                    isNew = true; //no existing SF record found
                }
            }
            return sfOrder;
        }
        set;
    }
    
    private static Map<String, OrderItem> sfLines {
        get {
            if(sfLines == null) {                
                if(isContract && String.isNotBlank(wor.contractNumber)) {
                    /// update to fetch by contract#
                    sfLines = SBR_3_0_OrderItemDA.getOrderItemByContractNumber(wor.contractNumber, companyCode);
                }
                else {
                    sfLines = SBR_3_0_OrderItemDA.getOrderItemByReservationNumber(wor.reservationNumber, companyCode);
                }
            }
            return sfLines;
        }
        set;
    }

    private static String companyCode {
        get {
            if(wor.data.Company_Code__c != null) {
                return wor.data.Company_Code__c;
            }
            throw new SBR_3_0_CustomException(Label.CompanyCodeRequired);
        }
        set;
    }

    private static Id getOrderRecordTypeId(){
        if(String.isBlank(wor.type)) {
            throw new SBR_3_0_CustomException (Label.OrderTypeRequired);
        }
        
        Map<String,Schema.RecordTypeInfo> recordTypeMap = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName();
            
        if(wor.type == RESERVATION_TYPE){
            return recordTypeMap.get('Reservation_Order').getRecordTypeId();
        }
        
        if(wor.type == CONTRACT_TYPE){
            return recordTypeMap.get('Contract_Order').getRecordTypeId();
        }
        
        if(wor.type == SALES_TYPE){
            return recordTypeMap.get('Sales_Order').getRecordTypeId();
        }
        
        throw new SBR_3_0_CustomException(String.format(Label.InvalidOrderType, new List<String>{ wor.type }));
    }
    
    private static String branchId {
        get {
            if(branchId == null) {
                Map<String,Schema.Location> branches = SBR_3_0_BranchDA.getBranchByNumbers(new Set<String> {wor.branchNumber});
                if(branches.containsKey(wor.branchNumber)) {
                    if(branches.get(wor.branchNumber).Time_Zone__c !=null){
                        branchTimeZoneOffset = String.ValueOf(branches.get(wor.branchNumber).Time_Zone__c);
                    }
                    branchId = branches.get(wor.branchNumber).Id;                    
                    return branchId;
                }
            }
            return branchId;
        }
        set;
    }
    
    private static AssociatedLocation jobSite {
        get{        
            if(
                jobSite == null && wor != null && String.isNotBlank(wor.jobSiteId) &&
                (isNew || (!isNew && hasJobSiteChanged))
            ) {
                List<AssociatedLocation> jobsites = SBR_3_0_JobsiteDA.getJobSitesByJobSiteId(wor.jobSiteId);
                
                if(!jobsites.isEmpty()){
                    jobSite = jobsites[0];
                    return jobSite; 
                }
                else {
                    throw new SBR_3_0_CustomException('Jobsite Id ' + wor.jobSiteId + ' does not exist in SF!');
                }
            }
            else if(jobSite == null && sfOrder != null && sfOrder.Jobsite__r != null ) {
                return sfOrder.Jobsite__r;
            }
            return jobSite;
        }
        set;
    }
    
    private static Map<String,User> salesRepUserIds {
        get{
            if(salesRepUserIds == null) {
                Set<String> reps = new Set<String>();
                if(String.isNotBlank(wor.primarySalesRep)){ //&& (isNew || (!isNew && hasPrimarySaleRepChanged))) {
                    reps.add(wor.primarySalesRep);
                }
                if(String.isNotBlank(wor.secondarySalesRep)){ // && (isNew || (!isNew && hasSecSaleRepChanged))) {
                    reps.add(wor.secondarySalesRep);
                }
                salesRepUserIds = SBR_3_0_UserDA.getUserMapBySalesRepIds(reps);
                if(!salesRepUserIds.isEmpty()) {
                    return salesRepUserIds;
                }
                //throw new OrderException('Related Sales Rep not found!'); // 23889, removing this exception
            }
            return salesRepUserIds;
        }
        set;
    }
    
    private static Schema.Location jobLocation {
        get{
            if(jobLocation != null){
                return jobLocation;
            }
            
            if (wor.address != null && SBR_3_0_SalesHelper.isAddressComplete(wor.address)) {
                jobLocation = SBR_3_0_JobsiteDA.getRelatedJobLocation(wor.address);
            }
            
            SBR_3_0_WrapAddress acctAddr = null;
            if (wor.data.Deliverymethod__c == DELIVERY_METHOD_PICKUP && SBR_3_0_SalesHelper.isAddressComplete(relAcct)) {
                acctAddr = SBR_3_0_SalesHelper.WrapAccountShippingAddress(relAcct);
            }
            
            if (jobLocation == null && wor.data.Deliverymethod__c == DELIVERY_METHOD_PICKUP && SBR_3_0_SalesHelper.isBillingAddressComplete(relAcct)) {
                 acctAddr = SBR_3_0_SalesHelper.WrapAccountBillingAddress(relAcct);
            }
            
            if(acctAddr != null){
                jobLocation = SBR_3_0_JobsiteDA.getRelatedJobLocation(acctAddr);
            }
                
            if(jobLocation == null){
                jobLocation = setNewJobLocation();
            }
            
            return jobLocation;
        }
        set;
    }

    private static Map<String,Asset> assetsMap {
        get {
            if(assetsMap == null && !assetNumbers.isEmpty()) {
                Map<String,Asset> assets = new Map<String,Asset>();
                assetsMap = SBR_3_0_AssetDA.getAssetsByNumbers(assetNumbers);
            
                if(assetsMap!=null && !assetsMap.isEmpty()) {
                    return assets;
                }
                throw new SBR_3_0_CustomException('Assets not found!');
            }
            return assetsMap;
        }
        set;
    }
    
    private static Schema.Location setNewJobLocation() {
        Schema.Location l = new Schema.Location();
        if (wor.data.Deliverymethod__c == DELIVERY_METHOD_PICKUP && SBR_3_0_SalesHelper.isAddressComplete(relAcct)){
            l = SBR_3_0_SalesHelper.createJobLocFromShippingAddr(relAcct);
        }
        else if (wor.data.Deliverymethod__c == DELIVERY_METHOD_PICKUP && SBR_3_0_SalesHelper.isBillingAddressComplete(relAcct)){
            l = SBR_3_0_SalesHelper.createJobLocFromBillingAddr(relAcct);
        }
        else {
            if(wor.address != null) {
                l = SBR_3_0_SalesHelper.createJobLocFromAddress(wor.address);
            }
            else {
                throw new SBR_3_0_CustomException('Address is required.');
            }
        }
        if (wor.orderedBy != null) {
            if (String.isNotBlank(wor.orderedBy.firstName) && String.isNotBlank(wor.orderedBy.lastName)) {
                l.Name = wor.orderedBy.firstName + ' ' + wor.orderedBy.lastName;
            }
        }
        l.Company_Code__c = companyCode;
        if (Schema.sObjectType.Location.isCreateable()) {
           insert l;
        }
        return l;
    }
    
    /**
     * 
     * @param req 
     * @return  `AssociatedLocation`
     * @description createJobSite
     */
    public AssociatedLocation createJobSite(Order req){
        AssociatedLocation js = new AssociatedLocation();
        
        //address field
        if (req.Deliverymethod__c == DELIVERY_METHOD_PICKUP && SBR_3_0_SalesHelper.isAddressComplete(relAcct)) {
            //from related account for cash pickup
            js = SBR_3_0_SalesHelper.createJoSiteFromShippingAddr(relAcct, jobLocation.Id, branchId);         
        }
        else if (req.Deliverymethod__c == DELIVERY_METHOD_PICKUP && SBR_3_0_SalesHelper.isBillingAddressComplete(relAcct)) {
            //from related account for cash pickup
            js = SBR_3_0_SalesHelper.createJoSiteFromBillingAddr(relAcct, jobLocation.Id, branchId);
        }
        else {
            js = SBR_3_0_SalesHelper.createJoSiteFromAddress(wor.address, relAcct.Id, jobLocation.Id, branchId);
        }
        
        js.SalesRepUserId__c = !salesRepUserIds.isEmpty() && salesRepUserIds.containsKey(wor.primarySalesRep)? salesRepUserIds.get(wor.primarySalesRep).Id : null;
        
        if (Schema.sObjectType.AssociatedLocation.isCreateable()) {
            insert js;
        }
        return js;
    }

    private String getCompositeKey(Decimal globalLineNum) {
        return isContract ? (wor.contractNumber + '-' + Integer.valueOf(globalLineNum)) : (wor.reservationNumber + '-' + Integer.valueOf(globalLineNum));
    }

    private Id getAssetId(String assetNum) {
        if(
            assetsmap != null 
            && !assetsMap.isEmpty() 
            && String.isNotBlank(assetNum) 
            && assetsMap.containsKey(assetNum) 
        ) {
            return assetsMap.get(assetNum).Id;
        }
        return null;
    }
    
    private Order setOrderedBy(Order o) {
        if (wor.orderedBy != null) {
            o.First_Name__c = wor.orderedBy.firstName ?? '';
            o.Last_Name__c   = wor.orderedBy.lastName ?? '';
            o.Ordered_By_Text__c = o.First_Name__c +' '+ o.Last_Name__c;    // SF-6829
            o.Phone__c = wor.orderedBy.phone ?? '';
            o.Email__c = SBR_3_0_SalesHelper.validateEmail(wor.orderedBy.email);
            Contact returnedContact = SBR_3_0_SalesHelper.findOrCreateContact(wor.orderedBy, wor.address, relAcct);
            if(returnedContact.Id != null){
                o.Order_By__c = returnedContact.Id;
            }
        }
        return o;
    }
    
    private Boolean hasProductOnTheLineChanged(OrderItem inbound) {
        return
            inbound.PricebookEntryId != null
            && sfLines != null
            && sfLines.containsKey(inbound.Line_Composite_Key__c)
            && sfLines.get(inbound.Line_Composite_Key__c).PricebookEntryId != inbound.PricebookEntryId;
    }
    
    private Decimal getQuantity(OrderItem oi) {
        Decimal qty =
            (oi.Status_Asset_Assigned_Qty__c ?? 0) +
        	(oi.Status_Asset_Pending_Qty__c ?? 0) +
        	(oi.Status_Created_Qty__c ?? 0) +
        	(oi.Status_Filled_Qty__c ?? 0) +
        	(oi.Status_Invoice_Pending_Qty__c ?? 0) +
        	(oi.Status_Invoiced_Qty__c ?? 0) +
        	(oi.Status_Closed_Qty__c ?? 0);
        
        if(qty == 0) {
            if(oi.Status_Cancelled_Qty__c != null && oi.Status_Cancelled_Qty__c>0 ) {
                isAssetItemHiddenMap.put(oi.Line_Composite_Key__c, true);
                qty += oi.Status_Cancelled_Qty__c;
                if(oi.Quantity == oi.Status_Cancelled_Qty__c)
                {
                    isLineItemHiddenMap.put(oi.Line_Composite_Key__c, true);
                }
            }
            //status = this is cancelled or closed or invoiced - set that quantity
            //ToDo->filter these lineitems as not to be displayed using a new boolean field.
            //isLineItemHiddenMap.put(oi.Line_Composite_Key__c, true);
            if(qty == 0 && oi.Quantity == 0) {
                throw new SBR_3_0_CustomException ('Quantity Status values should add up to more than zero!');
            }
            else if(qty == 0 && oi.Quantity > 0) {
               // isLineItemHiddenMap.put(oi.Line_Composite_Key__c, false);
                return oi.Quantity;
            }
        }
        return qty;
    }
    
    private String getRelatedQuote() {
        String uniqueRMQuoteId = null; // Initialize to null

        if (String.isNotBlank(inOrder.Rentalman_Quote_Id__c)) {
            uniqueRMQuoteId = companyCode + '-' + inOrder.Rentalman_Quote_Id__c;
            inOrder.Rentalman_Quote_Id__c = uniqueRMQuoteId;
        } else if (String.isNotBlank(wor.reservationNumber)) {  //SF-6776-check if reservationNumber is not blank (for Quotes Converted to Reservation from RM)
            uniqueRMQuoteId = companyCode + '-' + wor.reservationNumber;
        }
        
        if (uniqueRMQuoteId != null) {
            List<SBQQ__Quote__c> sfQuote = SBR_3_0_QuoteDA.getQuoteByRentalmanQuoteId(uniqueRMQuoteId);
            if(sfQuote.size()>0) {
                return sfQuote[0].Id;
            }
        }
        return null;
    }
    
    private Map<String,PricebookEntry> getPricebookEntryMap(){
        String cic = SBR_3_0_UtilityDA.getCompanyCurrencies().get(companyCode);
        Map<String,PricebookEntry> result = new Map<String,PricebookEntry>();
        
        Set<String> skus =  new Set<String>();
        
        //This is a private member variable that's used in other methods / functions.
        assetNumbers = new Set<String>();
        
        for(WrapOrderItem lineWrapper: wor.linedata){
            if(String.isNotBlank(lineWrapper.productSKU)){
                skus.add(lineWrapper.productSKU);
            }
            
            if(String.isNotBlank(lineWrapper.assetNumber)) {
                assetNumbers.add(lineWrapper.assetNumber);
            }
        }
                
        for(PricebookEntry pbe : 
            [Select 
                Id,
                UnitPrice,
                Product2Id,
                Product2.Item_Number__c,
                Product2.Product_SKU__c,
                Product2.Product_Type__c,
                Product2.Stock_class__c
             From 
                PricebookEntry
             Where
            	((Product2.Product_SKU__c in :skus Or Product2.Item_Number__c = 'ITEMNOTFOUND')
                Or (Product2.Stock_class__c = 'DEL' and Product2.Product_Type__c ='MISC Charge Items' and (Product2.Item_Number__c='PICKUP' or Product2.Item_Number__c ='DELIVERY')))
                And CurrencyIsoCode = :cic
                And Pricebook2.IsStandard = true]){
            
            Product2 prod = pbe.Product2;
            //Put the generic / item not found product in the same map
            if('ITEMNOTFOUND' == prod.Item_Number__c){
                result.put('ITEMNOTFOUND', pbe);    
            }
                    
            if('DEL' == prod.Stock_class__c && 'MISC Charge Items' == prod.Product_Type__c && (prod.Item_Number__c == 'PICKUP' || prod.Item_Number__c == 'DELIVERY')){
                result.put(prod.Item_Number__c, pbe);            
            }
            
            result.put(pbe.Product2.Product_SKU__c, pbe);         
        }
        
        if(result.values().isEmpty()){
            throw new SBR_3_0_CustomException('No Price Book Entries found!');
        }
        
        return result;
    }

    /**
     * @description WrapOrder
     */
    public class WrapOrder{
        public String preventTaxCalculation = '';
        public String rmAccountNumber = '';
        public String branchNumber = '';
        public String jobSiteId ='';
        public String jobNumber ='';
        public String reservationNumber ='';
        public String contractNumber ='';
        public String primarySalesRep ='';
        public String secondarySalesRep ='';
        public String type ='';
        public SBR_3_0_ContactWrap orderedBy = new SBR_3_0_ContactWrap();
        public SBR_3_0_WrapAddress address = new SBR_3_0_WrapAddress(); 
        public Order data = new Order();
        public List<WrapOrderItem> linedata = new List <WrapOrderItem>();
    }

    /**
     * @description WrapOrderItem
     */
    public class WrapOrderItem {
        public String productSKU = '';
        public String assetNumber = '';
        public String orderNumber ='';
        public String branchNumber ='';
        public OrderItem data = new OrderItem();
        public List<LineItemDetailWrapper> lineItemDetails = new List<LineItemDetailWrapper>();
    }
    
    /**
     * @description LineItemDetailWrapper
     */
    public class LineItemDetailWrapper {
        public Order_Item_Detail__c data = new Order_Item_Detail__c();
    }
}