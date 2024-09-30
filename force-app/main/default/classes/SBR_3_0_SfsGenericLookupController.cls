/*********************************************************************************************************************
* Apex Class: SBR_3_0_SfsGenericLookupController
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* -  To support Salesforce field service mobile lookup 
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION       DATE               DETAIL FEATURES
    1.0          2023-02-23          Initial version  
    2.0          2023-10-23          added seach fxnality on all fields  

**********************************************************************************************************************************************/
public with sharing class SBR_3_0_SfsGenericLookupController {
    // Method to fetch lookup search result   
    @AuraEnabled (cacheable=true)
    public static list<sObject> fetchLookupData(string searchKey , string sObjectApiName, string filterQuery,string otherField) {    
        List < sObject > returnList = new List < sObject > ();
        string sWildCardText = '%' + searchKey + '%';
        string sQuery;
        List < sObject > tempList = new List < sObject > ();
        String fieldsToQuery = 'SELECT Id,';
        Boolean showOtherField=false;
        String searchQuery=' Where (Name Like : sWildCardText';
        if(string.isNotBlank(otherField)){

            fieldsToQuery = fieldsToQuery + otherField+',';
            showOtherField=true;
            searchQuery+=' OR '+otherField+' like : sWildCardText)';


        }
        else {
            searchQuery+=')';
        }
          // Retro


        if(sObjectApiName=='Asset'){
          
            if(filterQuery=='None'){
                sQuery= fieldsToQuery+'Name From ' + sObjectApiName + searchQuery+' order by Name ASC LIMIT 20';
            }else{
                sQuery= fieldsToQuery+'Name From ' + sObjectApiName + searchQuery+filterQuery+' order by Name ASC LIMIT 20';
            }     
        } else if(filterQuery=='None'){
            sQuery= fieldsToQuery+'Name From ' + sObjectApiName + ' Where Name Like : sWildCardText order by createdDate DESC LIMIT 5';
        }else if(sObjectApiName=='ProductItem'){
            if(showOtherField)
            {
            return getProductItems( searchKey,  sObjectApiName,  filterQuery);
            }
            sQuery= fieldsToQuery+'ProductName,QuantityOnHand From ' + sObjectApiName + ' Where ProductName Like : sWildCardText'+filterQuery+'order by createdDate DESC LIMIT 10';
        }
        else if(sObjectApiName=='Product2' && showOtherField)
        {
            return getProductItems( searchKey,  sObjectApiName,  filterQuery);
        }
        else if(sObjectApiName=='WorkOrder'){
            sQuery= fieldsToQuery+'WorkOrderNumber From ' + sObjectApiName + ' Where WorkOrderNumber Like : sWildCardText'+filterQuery+'order by createdDate DESC LIMIT 10';
        }else{
            sQuery= fieldsToQuery+'Name From ' + sObjectApiName + ' Where Name Like : sWildCardText'+filterQuery+' order by createdDate DESC LIMIT 5';
        }
        system.debug(sQuery);
        
        for (sObject obj: database.query(sQuery)) {
            returnList.add(obj);
        }
        return returnList;
    }
    
    // Method to fetch lookup default value 
    @AuraEnabled
    public static sObject fetchDefaultRecord(string recordId , string sObjectApiName) {
        string sRecId = recordId;  
        string sQuery='';  
        if(sObjectApiName=='ProductItem'){
            sQuery = 'Select Id,ProductName From ' + sObjectApiName + ' Where Id = : sRecId LIMIT 1';
        }
        else if(sObjectApiName=='WorkOrder'){
            sQuery = 'Select Id,WorkOrderNumber From ' + sObjectApiName + ' Where Id = : sRecId LIMIT 1';
        }
        else{
            sQuery = 'Select Id,Name From ' + sObjectApiName + ' Where Id = : sRecId LIMIT 1';
        }
        for (sObject obj: database.query(sQuery)) {
            return obj;
        }
        return null;
    }
  // search on multiple fields on ProductItem an Product2
  Public static list<Sobject> getProductItems(String filterText, string sObjectApiName, string filterQuery)
  {
      system.debug('herer');
      string sWildCardText = '%' + filterText + '%';
      string fields;
      list<Sobject> returnList= new list<Sobject>();
      map<id,Sobject> results= new map<id,Sobject>();
      string sQuery='';
      if(sObjectApiName=='ProductItem')
      {
          fields='ProductName,QuantityOnHand,SM_PS_Description__c, SM_PS_Item_Number__c , SM_PS_Stock_Class__c';
       sQuery= 'Select Id,ProductName,QuantityOnHand,SM_PS_Description__c, SM_PS_Item_Number__c , SM_PS_Stock_Class__c From ' + sObjectApiName + ' Where (ProductName Like : sWildCardText OR SM_PS_Item_Number__c Like : sWildCardText OR SM_PS_Stock_Class__c Like : sWildCardText) and '+filterQuery+'order by createdDate DESC LIMIT 10';
      
      }
      if(sObjectApiName=='Product2')
      {
          fields='Name,Description__c, Stock_class__c , SM_PS_Item_number__c';
          if(filterQuery!='' || filterQuery !=null || filterQuery !='None')
          {
       sQuery= 'Select Id,Name,Description__c, Stock_class__c , SM_PS_Item_number__c From ' + sObjectApiName + ' Where (Name Like : sWildCardText OR SM_PS_Item_number__c Like : sWildCardText OR Stock_class__c Like : sWildCardText) and'+ filterQuery +'order by createdDate DESC LIMIT 10';
          }
          else {
            sQuery= 'Select Id,Name,Description__c, Stock_class__c , SM_PS_Item_number__c From ' + sObjectApiName + ' Where (Name Like : sWildCardText OR SM_PS_Item_number__c Like : sWildCardText OR Stock_class__c Like : sWildCardText) order by createdDate DESC LIMIT 10';
       
          }
      }
      system.debug(squery);
      for (Sobject obj: database.query(sQuery)) {
          results.put(obj.Id,obj);
          returnList.add(obj);
      }
      if(returnList.size()<10 && String.isNotBlank(filterText) && (filterText.length()>2))
      {
          map<id,ProductItem> Products= new map<id,productItem>();
          String fieldValue = '*'+filterText+'*';
          Integer limitRecs=10-returnlist.size();
          String fieldName = 'SM_PS_Description__c, SM_PS_Item_Number__c , SM_PS_Stock_Class__c';
         //String searchquery = 'FIND \'' + fieldValue + '\'  IN ALL FIELDS RETURNING '+' ProductItem (Id,ProductName, SM_PS_Description__c, SM_PS_Item_Number__c , SM_PS_Stock_Class__c where '+filterQuery+') LIMIT '+ limitRecs;
          String searchquery='';
          if(String.ISNOTBlank(filterQuery))
          {
          searchquery = 'FIND \'' + fieldValue + '\'  IN ALL FIELDS RETURNING '+ sObjectApiName+' (Id,'+fields+' where '+filterQuery+') LIMIT '+ limitRecs;
          
          }
          else{
            searchquery  ='FIND \'' + fieldValue + '\'  IN ALL FIELDS RETURNING '+ sObjectApiName+' (Id,'+fields+' ) LIMIT '+ limitRecs;
           
          }
          system.debug(searchquery);
          List<List<SObject>> searchList = System.Search.query(searchquery );//Return List of SObject list
          system.debug('Search result: ' + searchList[0]);//Get search result
          if(searchList[0].size() > 0) {
          //You can cast your result and return other fields if needed
          List<Sobject > objSearchResultsList = (List<Sobject >) searchList[0];
          for (Sobject obj: objSearchResultsList) {
              results.put(obj.Id,obj);
              returnList.add(obj);
          }
      }
      }
      system.debug(results);
  return results.values();
}
  
    
    
}