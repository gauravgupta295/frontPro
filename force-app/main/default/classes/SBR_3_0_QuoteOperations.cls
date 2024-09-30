/**
 * @description       : Processes 'SBQQ__Quote__C' records list before update/create operation.
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 03-19-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class SBR_3_0_QuoteOperations {
    public static Set<String> validRecTypes;

    /**
     * @description - method to publish quote to Outbox
     * @param newQuoteMap - Map<Id, SBQQ__Quote__c>
     */
    public static void publishQuoteToOutbox(Map<Id, SBQQ__Quote__c> newQuoteMap) {
        SBR_3_0_PublishRecordsToOutbox publishQuote = new SBR_3_0_PublishRecordsToOutbox(newQuoteMap, SBR_3_0_Constants.QUOTE_API_NAME);
        publishQuote.publish();
    }

    //Create/Delete related quote lines based on Erection Allocation, Dismantle Allocation %
    /**
     * @description       - method to create/delete quote lines for ED Scaffolding
     * @param quoteList   - List<SBQQ__Quote__c>
     * @param oldQuoteMap - Map<Id, SBQQ__Quote__c> - 
     */
    public static void manageELaborQuoteLines(List<SBQQ__Quote__c> quoteList, Map<Id, SBQQ__Quote__c> oldQuoteMap ) {
        Set<Id> deleteErectQuotes = new Set<Id>();
        Set<Id> erectQuotes = new Set<Id>();
        Set<Id> quotesToUpdate = new Set<Id>();
        Set<Id> deleteDismantleQuotes = new Set<Id>();
        List<Product2> edProductList =   SBR_3_0_ProductDA.getEDLaborProduct();

        String eLaborSKU = System.Label.E_Labor_Product_SKU;
        String dLaborSKU = System.Label.D_Labor_Product_SKU;
        Map<String, Product2> laborProductMap = new Map<String, Product2>();
        for(Product2 prod: edProductList){
            if(prod.Product_SKU__c == eLaborSKU){
                laborProductMap.put(eLaborSKU, prod);
            }else if(prod.Product_SKU__c == dLaborSKU){
                laborProductMap.put(dLaborSKU, prod);
            }
        }

        Set<Id> dismantleQuotes = new Set<Id>();
        for(SBQQ__Quote__c quote : quoteList){
            //SAL-16963
           if (oldQuoteMap != null && !oldQuoteMap.isEmpty() && (quote.Analysis_Region_Key__c == '921' || quote.Analysis_Region_Key__c == '933')) {
               // SAL-26878 _ remove check for Erection_Allocation__c update
                if(quote.Erection_Allocation__c!=null ){
                    //SF-7138, delete quote lines if Erection_Allocation__c is 0 or Show_Crew_Expense_Calculator__c is false
                    if(quote.Erection_Allocation__c == 0 || !quote.Show_Crew_Expense_Calculator__c){
                        deleteErectQuotes.add(quote.Id);
                   }
                   if(quote.Show_Crew_Expense_Calculator__c==true &&  quote.Erection_Allocation__c > 0){
                        erectQuotes.add(quote.Id);
                    }
                }
               // SAL-26878 _ remove check for Dismantle_Allocation__c update
                if(quote.Dismantle_Allocation__c!=null ){
                    //SF-7138. delete quote lines if Dismantle_Allocation__c is 0 or Show_Crew_Expense_Calculator__c is false
                    if(quote.Dismantle_Allocation__c == 0 || !quote.Show_Crew_Expense_Calculator__c){
                        deleteDismantleQuotes.add(quote.Id);
                   }
                   if(quote.Show_Crew_Expense_Calculator__c==true && quote.Dismantle_Allocation__c > 0 ){
                        dismantleQuotes.add(quote.Id);
                    }
                }
            }
        }

        // To delete quote lines
        List<SBQQ__QuoteLine__c> quoteLinesToDelete = new List<SBQQ__QuoteLine__c>();
        if(!deleteErectQuotes.isEmpty() || !deleteDismantleQuotes.isEmpty()){
            Set<Id> quotesToQuery = new Set<Id>();
            quotesToQuery.addAll(deleteErectQuotes);
            quotesToQuery.addAll(deleteDismantleQuotes);

            List<SBQQ__QuoteLine__c> edLaborQuoteList = SBR_3_0_QuoteLineDA.getQuoteLinesForEDScaffoldingLaborQuotes(quotesToQuery);
            for(SBQQ__QuoteLine__c qline : edLaborQuoteList){
                if((!deleteErectQuotes.isEmpty() && qline.Misc_Charges_Type__c=='Erect')  || (!deleteDismantleQuotes.isEmpty() && qline.Misc_Charges_Type__c=='Dismantle')){
                    quoteLinesToDelete.add(qline);
                }
            }
        }
        if(!quoteLinesToDelete.isEmpty()){
            Delete quoteLinesToDelete;
        }

        // To create quote lines if not already present and allocation >0
        if(!erectQuotes.isEmpty()){
            quotesToUpdate.addAll(erectQuotes);
            List<SBQQ__QuoteLine__c> eLaborQuotesList = SBR_3_0_QuoteLineDA.getQuoteLinesForEDLaborQuotes(erectQuotes, 'Erect');
            for(SBQQ__QuoteLine__c qtline : eLaborQuotesList){
                if(erectQuotes.contains(qtline.SBQQ__Quote__c)){
                    erectQuotes.remove(qtline.SBQQ__Quote__c);
                }
            }
        }

        List<SBQQ__QuoteLine__c> quoteLinesToAdd = new List<SBQQ__QuoteLine__c>();
        for(Id qtId : erectQuotes){
            SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
            quoteLine.Line_Name__c = 'ELABOR';
            quoteLine.Misc_Charges_Type__c = 'Erect';
            quoteLine.SBQQ__Product__c = laborProductMap.get(eLaborSKU)?.Id;
            quoteLine.Start_Date__c = date.today().addDays(7);
            quoteLine.Selling_Price__c = 0;
            quoteLine.SBQQ__Quantity__c = 1;
            quoteLine.SBQQ__Quote__c = qtId;
            quoteLine.Added_by_Crew_Expense__c = true; // SAL-26878, SAL-27341
            quoteLinesToAdd.add(quoteLine);
        }

        if(!dismantleQuotes.isEmpty()){
            quotesToUpdate.addAll(dismantleQuotes);
            List<SBQQ__QuoteLine__c> dLaborQuotesList = SBR_3_0_QuoteLineDA.getQuoteLinesForEDLaborQuotes(dismantleQuotes, 'Dismantle');
            for(SBQQ__QuoteLine__c qtdline : dLaborQuotesList){
                if(dismantleQuotes.contains(qtdline.SBQQ__Quote__c)){
                    dismantleQuotes.remove(qtdline.SBQQ__Quote__c);
                }
            }

        }

        for(Id dqtId : dismantleQuotes){
            SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
            quoteLine.Line_Name__c = 'ELABOR';
            quoteLine.Misc_Charges_Type__c = 'Dismantle';
            quoteLine.SBQQ__Product__c = laborProductMap.get(dLaborSKU)?.Id;
            quoteLine.Start_Date__c = date.today().addDays(7);
            quoteLine.Selling_Price__c = 0;
            quoteLine.SBQQ__Quantity__c = 1;
            quoteLine.SBQQ__Quote__c = dqtId;
            quoteLine.Added_by_Crew_Expense__c = true; // SAL-26878, SAL-27341
            quoteLinesToAdd.add(quoteLine);
        }

        if(!quoteLinesToAdd.isEmpty()){
            Database.insert( quoteLinesToAdd,false);
        }

        if(!quotesToUpdate.isEmpty()){
            updateQuoteLines(quotesToUpdate);
        }
    }

     // This method will also be invoked from Update Totals - Related to Scaffolding quotes
     public static void updateQuoteLines( Set<Id> quotes) {
        SBR_3_0_QuoteTriggerHandler.afterUpdateRecursiveCheck = true;
        Map<Id,SBQQ__Quote__c> scaffoldingQuotes = new Map<Id,SBQQ__Quote__c> (SBR_3_0_QuoteDA.getScaffoldingQuotes(quotes));
        if(scaffoldingQuotes.isEmpty() ||  scaffoldingQuotes.values().isEmpty()){
                    // This is not scaffolding quote

            return;
        }
       
        Map<String,String> quoteIDProductSKUMap = new Map<String,String>();
        // get product mapping
        List<Expense_Crew_Mapping__c> mappingList = SBR_3_0_ExpenseCrewMappingDA.getExpenseCrewMappingForScaffoldingQuote(scaffoldingQuotes.values()[0]);
        String eLaborSKU = System.Label.E_Labor_Product_SKU;

        // Get Crew summary records
        Map<Id,Crew_Summary__c> crewSummaryMap = new Map<Id,Crew_Summary__c>(SBR_3_0_CrewSummaryDA.getCrewSummaryForScaffoldingQuotes(scaffoldingQuotes.keyset()));
        for(Expense_Crew_Mapping__c mapping : mappingList){
            if(mapping.SF_Product_SKU__r.Product_SKU__c == eLaborSKU) {  //SAL-26878,27341
            for(Crew_Summary__c crewSum : crewSummaryMap.values()){
                if(crewSum.Quote__r.Analysis_Region_Key__c == mapping.Analysis_Region_Key__c && crewSum.Quote__r.Company_Code__c == mapping.Company_Code__c)
                   quoteIDProductSKUMap.put(crewSum.Quote__c,mapping.SF_Product_SKU__c);
            }
        }
        }
        SBR_3_0_CrewSummaryOperations.updateQuoteDetails(SBR_3_0_CrewSummaryDA.getCrewSummaryForScaffoldingQuotes(scaffoldingQuotes.keyset()));

        // Get expense records
        Map<Id,SBR_Expense__c> expenseMap = new Map<Id,SBR_Expense__c>(SBR_3_0_ExpenseDA.getQuotesExpensesForScaffoldingQuotes(scaffoldingQuotes.keyset()));
        Map<Id,Decimal> miscCostMap = new Map<Id,Decimal>();
        Map<Id,Decimal> freightCostMap = new Map<Id,Decimal>();

        for(SBR_Expense__c exp : expenseMap.values()){
            if(exp.ExpenseType__c!=null && exp.ExpenseType__c.toLowerCase().contains('freight')){
                if(freightCostMap.containsKey(exp.Quote_Expenses__c)){
                    Decimal frCst = freightCostMap.get(exp.Quote_Expenses__c);
                    freightCostMap.put(exp.Quote_Expenses__c,frCst+exp.Total__c);
                }
                else{
                    freightCostMap.put(exp.Quote_Expenses__c,exp.Total__c);
                }
            }
            // SF-8216 , misc cost includes all of these expense types
            if(exp.ExpenseType__c!=null && 
                (exp.ExpenseType__c.toLowerCase().contains('misc') 
                    || exp.ExpenseType__c.toLowerCase().contains('safety') 
                    || exp.ExpenseType__c.toLowerCase().contains('forklift ') 
                    || exp.ExpenseType__c.toLowerCase().contains('engineering')
                    || exp.ExpenseType__c.toLowerCase().contains('sublet'))){
                if(miscCostMap.containsKey(exp.Quote_Expenses__c)){
                    Decimal miscCst = miscCostMap.get(exp.Quote_Expenses__c);
                    miscCostMap.put(exp.Quote_Expenses__c,miscCst+exp.Total__c);
                }else{
                    miscCostMap.put(exp.Quote_Expenses__c,exp.Total__c);
                }
            }
        }

        List<AggregateResult> moveOnlyAggrList = SBR_3_0_CrewSummaryDA.getCrewSummaryScaffoldingAggregateList(scaffoldingQuotes.keyset());
        List<AggregateResult> aggregateMoveResultList = SBR_3_0_CrewSummaryDA.getCSTotalsSumMoveAggrList(scaffoldingQuotes.keyset());
        List<AggregateResult> aggregateResultList = SBR_3_0_CrewSummaryDA.getCSTotalsSumExceptMoveAggrList(scaffoldingQuotes.keyset());
        Map<String,Decimal> costMap = new Map<String,Decimal>();
        Map<String,Decimal> csMoveMap = new Map<String,Decimal>();

        if(AggregateResultList != null && aggregateResultList.size() > 0 && moveOnlyAggrList != null && moveOnlyAggrList.size() > 0){

            for(AggregateResult aggr1 : aggregateResultList){
                for(AggregateResult aggr2 : moveOnlyAggrList){
                    Id scQuoteID =  (String)aggr1.get('Quote__c');
                    Decimal cost = (Decimal)aggr2.get('total');
                    Decimal quantity = (Decimal)aggr1.get('quantity');
                    costMap.put(scQuoteID,cost);


                }
            }
        }
        // SF-8216 , calculating CS related move cost, this will then be added with expense related cost for total move cost on quote
        if(aggregateMoveResultList != null && aggregateMoveResultList.size() > 0 ){
            for(AggregateResult aggr1 : aggregateMoveResultList){
                    Id scQuoteID =  (String)aggr1.get('Quote__c');
                    Decimal cost = (Decimal)aggr1.get('total');
                    csMoveMap.put(scQuoteID,cost);
            }
        }



        List<AggregateResult> aggregateResultExpensesList = SBR_3_0_ExpenseDA.getEDExpenseAggregateList(scaffoldingQuotes.keyset());
        if(aggregateResultExpensesList != null && aggregateResultExpensesList.size() > 0){
            for(AggregateResult aggrExp : aggregateResultExpensesList){
                Id quoteID =  (String)aggrExp.get('Quote_Expenses__c');
                Decimal cost = (Decimal)aggrExp.get('total');
                Decimal quantityExp = (Decimal)aggrExp.get('quantity');
                if(costMap.get(quoteID)==null){
                    costMap.put(quoteID,cost);
                }else{
                    Decimal crewSumCost = costMap.get(quoteID);
                    costMap.put(quoteID,crewSumCost+cost);
                }
            }
        }
        for(SBQQ__Quote__c  quote  : scaffoldingQuotes.values()){
            quote.E_D_Total__c = (Decimal) costMap.get(quote.Id);
            quote.Freight__c = (Decimal) freightCostMap.get(quote.Id);
            quote.Misc_Sales__c = (Decimal) miscCostMap.get(quote.Id);
            // SF-8216
            Decimal csMoveCost = 0;
            if(csMoveMap.get(quote.Id)!=null){
                csMoveCost = (Decimal) csMoveMap.get(quote.Id) ;
            }
            quote.Move_Calculation__c = csMoveCost +  quote.Move_Cost_Expense__c ;
        }
        update scaffoldingQuotes.values();

        //Get D-Labor Product SKU
        String dLabor_ProductSKU = System.Label.D_Labor_Product_SKU;
        List<Product2> products = SBR_3_0_ProductDA.getProductsByProductSKU(new Set<String>{dLabor_ProductSKU});
        List<SBQQ__QuoteLine__c> quotelines = new  List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> eLaborQuoteLineList = SBR_3_0_QuoteLineDA.getQuoteLinesForScaffoldingQuotes(scaffoldingQuotes.keyset());
        DateTime today = System.now();
        if(!eLaborQuoteLineList.isEmpty()){ //existing records  found, update them
            for(SBQQ__QuoteLine__c qline : eLaborQuoteLineList){
                if(qline.Misc_Charges_Type__c=='Erect'){
                    qline.Selling_Price__c = qline.SBQQ__Quote__r.Erect__c;
                    qline.SBQQ__Quantity__c =1;
                    if(qline.SBQQ__Product__c==null){
                        qline.SBQQ__Product__c = quoteIDProductSKUMap.get(qline.SBQQ__Quote__c);
                    }
                }else if(qline.Misc_Charges_Type__c=='Dismantle'){
                    qline.Selling_Price__c = qline.SBQQ__Quote__r.Dismantle__c;
                    qline.SBQQ__Quantity__c = 1;
                    if(qline.SBQQ__Product__c==null && products!=null && !products.isEmpty()){
                        qline.SBQQ__Product__c=products[0].Id;
                    }
                }

                if(qline.Start_Date__c < today) {
                    return;
                }
            }
            update eLaborQuoteLineList;
        }
    }

    public static void updateName(List<SBQQ__Quote__c> quoteList) {
        for(SBQQ__Quote__c quote : quoteList) {
            if(quote.Rentalman_Quote_Id__c != null && quote.Quote_Name__c == null) {
                quote.Quote_Name__c = quote.Job_Name__c;
            }
        }
    }

    // Upating End Date on Quote Based on Start Date and Duration
    public static void updateEndDate(List<SBQQ__Quote__c> quoteList, Map<Id, SBQQ__Quote__c> oldQuoteMap){
        SBR_3_0_QuoteTriggerHandler.beforeUpdateRecursiveCheck = true;

        Id profileId = UserInfo.getProfileId();
        String userProfileName =[Select Id, Name from Profile where Id=:profileId].Name;
        String customPermissionName = 'Allow_user_to_edit_Quote_with_Status_In_Review';

       // Check if the user has the custom permission
        Boolean hasCustomPermission = FeatureManagement.checkPermission(customPermissionName);

        // Calculate End Date of Quote based on Duration and Start Date
        for(SBQQ__Quote__c quote : quoteList){
           if(quote.Start_Date__c != null && quote.Duration__c != 'Custom'){

               if((quote.SBQQ__Status__c =='Draft' || (quote.SBQQ__Status__c=='In Review' && hasCustomPermission) || userProfileName== System.Label.SBR_3_0_SystemAdminProfil)
                  && quote.Duration__c!=null && quote.Submitted_to_Wynne__c ==false &&
                   ( oldQuoteMap==null || (oldQuoteMap != null && !oldQuoteMap.isEmpty() && (oldQuoteMap.get(quote.Id).Duration__c!=quote.Duration__c ||  oldQuoteMap.get(quote.Id).Start_Date__c!=quote.Start_Date__c ||
                   oldQuoteMap.get(quote.Id).Total_Est_Duration_weeks__c!=quote.Total_Est_Duration_weeks__c)))){

                    DateTime startDate = quote.Start_Date__c;
                    String varDuration = quote.Duration__c;

                    Integer daysToAdd = 0;

                    if (varDuration == 'Day') {
                        daysToAdd = 1;
                    } else if (varDuration == 'Week') {
                        daysToAdd = 7;
                    } else if (varDuration == '4 Week') {
                        daysToAdd = 28;
                    }
                   
                    quote.End_Date__c = startDate.addDays(daysToAdd);
               }
           }
        }
    }

    // SF_6005   When Delivery override = true, Updating Suggested delivery Charges per truck same as delivery charge 
    // SF_6005   When Delivery override = true, Updating Suggested pickup Charges per truck same as pickup charge 
    // SF_6833   Update/Override the Suggested delivery and Suggested pickup fields only when they do not hold any value
    public static void handleDeliveryOverrideChanges(Map<Id, SBQQ__Quote__c> oldMap, Map<Id, SBQQ__Quote__c> newMap){
        List<SBQQ__Quote__c> ordersToUpdate = new List<SBQQ__Quote__c>();
        for(SBQQ__Quote__c quote: newMap.values()){
            SBQQ__Quote__c oldQuote = oldMap.get(quote.Id);             
            if( quote.SBQQ__DeliveryMethod__c == SBR_3_0_Constants.FULFILLMENT_TYPE_DELIVERY && quote.Delivery_Charges_Override__c == true ){
                if(quote.Delivery_Charges__c <> null && quote.Delivery_Charges__c <> oldQuote.Delivery_Charges__c &&
                    (quote.Delivery_Charge__c == null || quote.Delivery_Charge__c == 0)   //SF-6833
                ){
                    quote.Delivery_Charge__c = quote.Delivery_Charges__c;
                }
                if(quote.Pickup_Charges__c <> null && quote.Pickup_Charges__c <> oldQuote.Pickup_Charges__c &&
                    (quote.Pickup_Charge__c == null || quote.Pickup_Charge__c == 0)   //SF-6833
                ){
                    quote.Pickup_Charge__c = quote.Pickup_Charges__c;
                }
            }
        }
    }    
    
    
    // Prevent Edit quote : SAL-27468
    public static void PreventEditQuote(Map<Id, SBQQ__Quote__c> mapQuotes,Map<Id, SBQQ__Quote__c> oldMapQuotes){
        List<Id> quoteIds = new List<Id>();
        List<Order> orders = new List<Order>();
        Map<Id, List<Order>> mapQuoteIdOrders = new  Map<Id, List<Order>>();

        // get profile of logged user
        Id profileId =userinfo.getProfileId();
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name;

        for(Id quoteId : mapQuotes.keySet()){
            quoteIds.add(quoteId);
        }
        if(!quoteIds.isEmpty()){
            orders = [SELECT  Id,SBQQ__Quote__c FROM Order WHERE SBQQ__Quote__c IN :quoteIds ];
        }
        
        for(Id quoteId : mapQuotes.keySet()){
            SBQQ__Quote__c quote = mapQuotes.get(quoteId);
            List<Order> associatedOrders = new List<Order>();
            for(Order order : orders){
                if(order.SBQQ__Quote__c == quote.Id){
                    associatedOrders.add(order);
                }
            }
            mapQuoteIdOrders.put(quote.Id,associatedOrders);
        }
        for (Id quoteId : mapQuoteIdOrders.keySet()) {
            SBQQ__Quote__c quote = mapQuotes.get(quoteId);
            SBQQ__Quote__c oldQuote = oldMapQuotes.get(quoteId);
            System.debug('quote : ' + quote) ;
            
            if( 
                // this condition to not block changing the status 
                oldQuote.SBQQ__Status__c == 'Won' && oldQuote.SBQQ_Status_Reason__c == 'Converted' && !mapQuoteIdOrders.get(quoteId).isEmpty() &&
               profileName != SBR_3_0_Constants.PROFILE_NAME_ADMIN && profileName != SBR_3_0_Constants.PROFILE_NAME_BUSINESS_ADMIN){
                String message =  Label.Quote_Prevent_Editing;
                quote.addError(message);
            }      
        }
    }

    public static void setRPPFieldToTrue(List<SBQQ__Quote__c> newList){
        try{

            List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();
            Id prospectRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
    
            if(prospectRecordTypeId != null){
                for(SBQQ__Quote__c quote : newList){
                    if(quote.SBQQ__Account__c != null && quote?.SBQQ__Account__r.RecordTypeId == prospectRecordTypeId &&
                      quote?.SBQQ__Account__r.RPP__c == 'Y' && quote.RPP__c != 'Y'){    //SF-7224
                        SBQQ__Quote__c updatedQuote = new SBQQ__Quote__c(Id = quote.Id , RPP__c = 'Y');
                        quotesToUpdate.add(updatedQuote);
                    }
                }
                if(!quotesToUpdate.isEmpty()){
                    update quotesToUpdate;
                }
            }
        }catch(Exception e){
            throw e ;
        }
       
    }
    
    //SF-5331
    public static void enableScaffoldQuotesOptions(List<SBQQ__Quote__c> newList){
        for(SBQQ__Quote__c quote : newList){
            system.debug('Quote analysis region key: ' + quote.Analysis_Region_Key__c);
            if(quote.Analysis_Region_Key__c == '921' || quote.Analysis_Region_Key__c == '933'){
                quote.Include_Advanced_Scope__c = true;
                quote.Show_Crew_Expense_Calculator__c = true;
            }
        }
    }

     //SF-5397: Updating SBQQ__Quote__c.Account_Record_Type_Txt__c field which is used in sharing rules
     public static void populateAccountRecordType(List<SBQQ__Quote__c> newQuotes, Boolean isInsert) {
        SBR_3_0_QuoteTriggerHandler.beforeUpdateRecursiveCheck = true;
        Set<Id> accIds = new Set<Id>();
        for(SBQQ__Quote__c quote : newQuotes) {
            if(String.isBlank(quote.Account_Record_Type_Txt__c) && quote.SBQQ__Account__c != null) {
                accIds.add(quote.SBQQ__Account__c); 
            }
        }
        if(!accIds.isEmpty()) {
            Map<Id,Account> mapAccount = new Map<Id,Account>([Select RecordType.Name, RecordType.DeveloperName, RPP__c, Charge_for_RPP__c 
                from Account Where Id in: accIds]);
            Account relAcc;
            for(SBQQ__Quote__c quote : newQuotes) {
                relAcc = mapAccount.get(quote.SBQQ__Account__c);
                if(String.isBlank(quote.Account_Record_Type_Txt__c))
                    quote.Account_Record_Type_Txt__c = relAcc.RecordType.Name;
                if(isInsert)    {    // SF-7224
                    // FRONT-30293, 30294: Assigning Charge_for_RPP__c for Non-Credit
                    quote.RPP__c = relAcc.RecordType.DeveloperName == 'Non_Credit' ? relAcc.Charge_for_RPP__c : relAcc.RPP__c;    
                }
            }
        }
    }

    /**
    * @description Set IsDeliveryOptionsChanged__c to true when fields on delivery tab is changed - SF-6415
    * @author Pavan Konduru | 01-19-2024 
    * @param oldMap 
    * @param newMap 
    **/
    public static void handleDeliveryOptionChange(Map<Id, SBQQ__Quote__c> oldMap, Map<Id, SBQQ__Quote__c> newMap){
        for(SBQQ__Quote__c quote: newMap.values()){
            SBQQ__Quote__c oldQuote = oldMap.get(quote.Id);
            if(oldQuote.SBQQ__DeliveryMethod__c <> quote.SBQQ__DeliveryMethod__c ||
                (oldQuote.Pickup_Charges__c <> null && oldQuote.Pickup_Charges__c <> quote.Pickup_Charges__c) ||          
                (oldQuote.Delivery_Charges__c <> null && oldQuote.Delivery_Charges__c <> quote.Delivery_Charges__c) ||   
                oldQuote.Delivery_Charges_Override__c <> quote.Delivery_Charges_Override__c ||
                oldQuote.Using_3rd_Party__c <> quote.Using_3rd_Party__c
            ){
                quote.IsDeliveryOptionsChanged__c = true;
            }
        }
    }
    public static void updateCreatedByUserBranch(List<SBQQ__Quote__c> quotes)
    {
        List<Schema.Location> userLocation = SBR_3_0_BranchDA.getLoggedInUserLocation();
        if(userLocation !=null && userLocation.size() > 0)
        {
            for(SBQQ__Quote__c currentQuote : quotes)
            {
                if(currentQuote.Created_By_Users_Branch__c == null){
                    currentQuote.Created_By_Users_Branch__c = userLocation[0].Id;
                }
            }
        }
    }


}