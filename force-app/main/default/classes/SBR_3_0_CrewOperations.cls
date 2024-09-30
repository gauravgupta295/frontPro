public with sharing class SBR_3_0_CrewOperations {

    public static void createOrUpdateCrewSummary(List<Crew__c> newCrewList) {
        Set<Id> quoteIds = new Set<Id>();
        List<Crew__c> crewNeedSummary = new List<Crew__c>();
        List<Crew__c> crewToUpdate = new List<Crew__c>();
        List<Crew_Summary__c> newCrewSummaries = new List<Crew_Summary__c>();
        Map<String, Crew_Summary__c> crewSummaryMap = new Map<String, Crew_Summary__c>();
        for (Crew__c crew : newCrewList) {
            quoteIds.add(crew.Quote__c);
        }

        //SAL-26878
        Map<Id,SBQQ__Quote__c> quotesMap = SBR_3_0_QuoteDA.getQuotes(quoteIds);
        // get product mapping
        List<Expense_Crew_Mapping__c> mappingList = SBR_3_0_ExpenseCrewMappingDA.getExpenseCrewMappingForScaffoldingQuote(quotesMap.values()[0]);


        List<Crew_Summary__c> crewSummaries = SBR_3_0_CrewSummaryDA.getCrewSummaryForScaffoldingQuotes(quoteIds);
        for (Crew_Summary__c crewSummary : crewSummaries) {
            crewSummaryMap.put(concatQuoteAndTask(crewSummary.Quote__c, crewSummary.Task_Type__c), crewSummary);
        }

        //SAL-26878
        Map<String,String> quoteIDProductSKUMap = new Map<String,String>();
        for(Expense_Crew_Mapping__c mapping : mappingList){
            if(!crewSummaries.isEmpty()){
                for(Crew_Summary__c crewSum : crewSummaries){
                    if(crewSum.Quote__r.Analysis_Region_Key__c == mapping.Analysis_Region_Key__c && crewSum.Quote__r.Company_Code__c == mapping.Company_Code__c 
                        && crewSum.Task_Type__c == mapping.Expense_Crew_Type__c){
                        quoteIDProductSKUMap.put(crewSum.Quote__c, mapping.SF_Product_SKU__c);
                    }
                }
            }else{
                quoteIDProductSKUMap.put(newCrewList[0].Quote__c, mapping.SF_Product_SKU__c);
            }
            
        }

        for (Crew__c crew : newCrewList) {
            if (crewSummaryMap.containsKey(concatQuoteAndTask(crew.Quote__c, crew.Task__c))) {
                crewNeedSummary.Add(crew);
            }
            else {
                //for new crew summaries to be created ensure that you don't create more than 1 of the same Quote/Task type
                if (!crewSummaryMap.containsKey(concatQuoteAndTask(crew.Quote__c, crew.Task__c))) {
                    Crew_Summary__c newCrewSummary = new Crew_Summary__c();
                    newCrewSummary.Quote__c = crew.Quote__c;
                    newCrewSummary.Task_Type__c = crew.Task__c;
                    //SAL-26878
                    newCrewSummary.Product_SKU__c = quoteIDProductSKUMap.get(crew.Quote__c);
                    newCrewSummaries.add(newCrewSummary);
                    crewNeedSummary.add(crew);
                    crewSummaryMap.put(concatQuoteAndTask(crew.Quote__c, crew.Task__c), newCrewSummary);
                }
            }
        }
        
        insert newCrewSummaries;

        for (Crew__c crew: crewNeedSummary) {
            if (crewSummaryMap.containsKey(concatQuoteAndTask(crew.Quote__c, crew.Task__c))) {
                crew.Crew_Summary__c = crewSummaryMap.get(concatQuoteAndTask(crew.Quote__c, crew.Task__c)).Id;
                //SAL-26878
                crew.Product__c = quoteIDProductSKUMap.get(crew.Quote__c);
                crewToUpdate.Add(crew);
            }
        }
    }

    public static void deleteCrewSummary(List<Crew__c> oldCrew) {
        Set<Id> summaryIdsToEval = new Set<Id>();
        for (Crew__c crew : oldCrew) {
            summaryIdsToEval.add(crew.Crew_Summary__c);
        }
        if (summaryIdsToEval.size() > 0) {
            System.enqueueJob(new DeleteSummaries(summaryIdsToEval));
        }
    }
    
    
    @InvocableMethod(label='Calculate Quoteline Details' description='Returns the list of Crew Quote Reponses ' category='Quote')
	public static List<CrewQuoteResponse> calculateQuoteLineDetails(List<CrewQuoteRequest> crewRequest) {

        List<Id> crewId = new List<Id>();
        Set<Id> quoteId = new Set<id>();
        Set<String> crewType = new Set<String>();
        Set<String> crewSKU = new Set<String>();

        for(CrewQuoteRequest crewReq : crewRequest){
                crewId.add(crewReq.crewId);
                quoteId.add(crewReq.quoteId);
        }
        

        List<Crew__c> crewRecordList = SBR_3_0_CrewDA.getCrews(crewId);
        
        for(Crew__c crew : crewRecordList){
                crewType.add(crew.Task__c);
        }


        Map<Id, SBQQ__Quote__c> quoteMap = SBR_3_0_QuoteDA.getQuotes(quoteId);

        List<Expense_Crew_Mapping__c> crewMapping = SBR_3_0_ExpenseCrewMappingDA.getExpenseCrewMapping(quoteMap.values(),crewType);

        if(crewMapping.isEmpty()  ){
            return null;
        }
        for (Expense_Crew_Mapping__c expMapping : crewMapping) {
            crewSKU.add(expMapping.SF_Product_SKU__c);
        }
        

        // find expense mapping for crew task type
        List<Expense_Crew_Mapping__c> mappingList = SBR_3_0_ExpenseCrewMappingDA.getExpenseCrewMappingForProductSKU(quoteMap.values(),crewSKU);
        Set<String> taskSet = new Set<String>();

        if(mappingList == null || mappingList.isEmpty()){
            return null;
        }

        // find task type for product sku, filter crew records which match the task type for same product sku 
        for(Expense_Crew_Mapping__c mapping : mappingList){
            taskSet.add(mapping.Expense_Crew_Type__c);
        }
        
        // Get all eligible crews records for quote
        List<Crew__c> allCrewList = SBR_3_0_CrewDA.getCrews(crewId);
        List<CrewQuoteResponse> retList = new List<CrewQuoteResponse>();

        for(Crew__c crew : allCrewList){
            CrewQuoteResponse crewResp = new CrewQuoteResponse();
            crewResp.stHours = crewResp.stHours + crew.Standard_Hours__c;
            crewResp.otHours = crewResp.otHours + crew.Overtime_Hours__c;
            crewResp.stCost = crewResp.stCost + crew.Standard_Cost__c;
            crewResp.otCost = crewResp.otCost + crew.Overtime_Cost__c;
            crewResp.crewCount =allCrewList.size();
            retList.add(crewResp);
        }
        
        SBR_3_0_Log.logInfo('retList--->'+ retList);
        return retList;
    }

    private static String concatQuoteAndTask(String quoteId, String taskType) {
        system.debug('Quote and task type: ' + quoteId + taskType);
        return quoteId + taskType;
    }

    public class DeleteSummaries implements Queueable {
        public Set<Id> summaryIdsToEval = new Set<Id>();

        public DeleteSummaries(Set<Id> summaryIdsToEval) {
            this.summaryIdsToEval = summaryIdsToEval;
        }
        public void execute(QueueableContext context) {
            List<Crew_Summary__c> summariesToDelete = new List<Crew_Summary__c>();
            List<Crew_Summary__c> summariesToEval = SBR_3_0_CrewSummaryDA.getCrewSummaryByIds(summaryIdsToEval);

            if(summariesToEval.size() > 0) {
            for (Crew_Summary__c summary : summariesToEval) {
                    if(summary.Record_Count__c == 0){
                        summariesToDelete.add(summary);
                    }
                }
            }
            system.debug(summariesToDelete);
            delete summariesToDelete;
        }
    }

    public class CrewQuoteRequest {
        @InvocableVariable(label='Crew Id' required=TRUE)
        public String crewId;
        @InvocableVariable(label='Quote Id' required=TRUE)
        public String quoteId;
    }
    public class CrewQuoteResponse {
        @InvocableVariable(label='Crew Count' required=FALSE)
        public Integer crewCount = 0;
        @InvocableVariable(label='ST Hours' required=FALSE)
        public Decimal stHours = 0;
        @InvocableVariable(label='OT Hours' required=FALSE)
        public Decimal otHours = 0;
        @InvocableVariable(label='ST Cost' required=FALSE)
        public Decimal stCost = 0;
        @InvocableVariable(label='OT Cost' required=FALSE)
        public Decimal otCost = 0;
    }
}