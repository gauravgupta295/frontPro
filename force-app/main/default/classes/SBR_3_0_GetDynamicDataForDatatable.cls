/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-19-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class SBR_3_0_GetDynamicDataForDatatable {
    @AuraEnabled
    public static DataTableResponse GetWrapperOfSObjectFieldColumnActionValues(String columLableList,String fieldApiNamesWithType,String fieldApiNamesWithoutType , String relatedObjectApiName ,String parentFieldApiName, String recordId, String recordSize)
    {
        List<DataTableColumns> lstDataColumns            = new List<DataTableColumns>();
        List<SObject> lstDataTableData                   = new List<SObject>();
        List<string> columnList                          = new List<string>();
        List<string> fieldAPINameList                    = new List<string>();

        String dataQuery = 'Select Id , '+fieldApiNamesWithoutType+' From ' + relatedObjectApiName +' Where '+parentFieldApiName +' = :recordId LIMIT '+recordSize;
        String dataQueryForSize = 'Select count() From ' + relatedObjectApiName +' Where '+parentFieldApiName +' = :recordId';
        System.debug('dataQuery'+dataQuery);
        system.debug('dataQueryForSize'+dataQueryForSize);
        if(columLableList != null)
        {
            columnList = columLableList.split(',');
        }

        if(fieldApiNamesWithType != null)
        {
            fieldAPINameList = fieldApiNamesWithType.split(',');
        }

        for(integer i = 0; i < columnList.size(); i++)
        {
            
            if(fieldAPINameList[i].substringAfterLast(':').trim() == 'url' ){
                DataTableColumns datacolumns = new DataTableColumns( columnList[i].trim() , 
                                                                fieldAPINameList[i].substringBefore(':').trim(), 
                                                                fieldAPINameList[i].substringAfterLast(':').trim(),
                                                                fieldAPINameList[i].split(':')[1].trim()
                                                                );
                lstDataColumns.add(datacolumns);
            }else {
                DataTableColumns datacolumns = new DataTableColumns( columnList[i].trim() , 
                                                                fieldAPINameList[i].substringBefore(':').trim(), 
                                                                fieldAPINameList[i].substringAfter(':').trim()
                                                                );
                lstDataColumns.add(datacolumns);
            }
        }

        for(SObject SObjectItem : Database.query(dataQuery))
        {
            lstDataTableData.add(SObjectItem);
        }
        lstDataColumns.add(new DataTableColumns());
        DataTableResponse finalWrapper   = new DataTableResponse();
        finalWrapper.lstDataTableColumns = lstDataColumns;
        finalWrapper.lstDataTableData    = lstDataTableData;
        system.debug('count dataQueryForSize'+database.countQuery(dataQueryForSize));
        
        finalWrapper.sizeOfRecords = database.countQuery(dataQueryForSize);
        return finalWrapper;
    }

   public class DataTableColumns {
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled       
        public String fieldName {get;set;}
        @AuraEnabled
        public String type {get;set;}
        @AuraEnabled
        public boolean sortable {get;set;}
        @AuraEnabled
        public boolean hideDefaultActions {get;set;}
        @AuraEnabled
        public typeAttributesData typeAttributes {get;set;}
        @AuraEnabled
        public String target {get;set;}
        @AuraEnabled
        public DataTableColumns tooltip {get;set;}
        @AuraEnabled
        public List<DataTableColumns> rowActions {get;set;}
        @AuraEnabled
        public String menuAlignment {get;set;}
        @AuraEnabled
        public string name {get;set;}
        public DataTableColumns()
        {
            this.type = 'action';
            this.typeAttributes = new typeAttributesData('slds-popover__body','true','true');
        }
        public DataTableColumns(String menuAlign , String actionsDisplay)
        {
            if(actionsDisplay == 'true'){
                List<DataTableColumns> rowactionList = new List<DataTableColumns>();
                rowactionList.add(new DataTableColumns('Edit','edit'));
                rowactionList.add(new DataTableColumns('Delete','delete'));
                this.rowActions     = rowactionList;
                this.menuAlignment = menuAlign;
            }else {
                this.label     = menuAlign;
                this.name = actionsDisplay;
            }
            
        }
        public DataTableColumns(String label, String fieldName, String type )
        {
            this.label     = label;
            this.fieldName = fieldName;
            this.type      = type; 
            this.sortable = true;
        }
        public DataTableColumns(String label, String fieldName, String type , String fieldUrlLable)
        {
            this.label     = label;
            this.fieldName = fieldName;
            this.type      = type; 
            this.sortable = true;
            if(type == 'url' ){
                
                this.hideDefaultActions = true;
                this.typeAttributes =new typeAttributesData(fieldUrlLable , label,'false');
                this.target = '_self';
                this.tooltip =new DataTableColumns(fieldUrlLable);
            }      
        }
        
        public DataTableColumns( String fieldUrlLable)
        {
            this.fieldName = fieldUrlLable;
        }
    }

    

    public class typeAttributesData {
        @AuraEnabled
        public DataTableColumns label {get;set;}
        @AuraEnabled
        public String menuAlignment {get;set;}
        @AuraEnabled
        public List<DataTableColumns> rowActions {get;set;}
        
        public typeAttributesData( String fieldUrlLable , String label , string actionAttribute)
        {
            if(actionAttribute == 'true'){
                List<DataTableColumns> rowactionList = new List<DataTableColumns>();
                rowactionList.add(new DataTableColumns('Edit','edit'));
                rowactionList.add(new DataTableColumns('Delete','delete'));
                this.rowActions     = rowactionList;
                this.menuAlignment = fieldUrlLable;
            }else {
                this.label = new DataTableColumns(fieldUrlLable);
            }
        }
    }
    
    public class DataTableResponse {
        @AuraEnabled
        public Integer sizeOfRecords {get;set;}
        @AuraEnabled
        public List<DataTableColumns> lstDataTableColumns {get;set;}
        @AuraEnabled
        public List<sObject> lstDataTableData {get;set;}
    }
}