/*********************************************************************************************************************
 * Apex Class: SBR_3_0_DynamicRecordFormSectionDetail
 ---------------------------------------------------------------------------------------------------------------------------------------
 * Purpose/Methods:
 * - Class to store the details of the dynamic record field driven by Record_Field__mdt
 ---------------------------------------------------------------------------------------------------------------------------------------
 * History:
 * - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
 1.0         Komal Dwivedi          12-Oct-2023          Initial version
 *********************************************************************************************************************/

public with sharing class SBR_3_0_DynamicRecordFormFieldDetail{
  @TestVisible
  private static final String INPUT_FIELD_TYPE = 'Input Field';
  @TestVisible
  private static final String CUSTOM_COMP_TYPE = 'Custom Comp';
  @TestVisible
  private static final String OUTPUT_FIELD_TYPE = 'Output Field';

  @AuraEnabled
  public String externalId;
  @AuraEnabled
  public String label;
  @AuraEnabled
  public String apiName;
  @AuraEnabled
  public Decimal order;
  @AuraEnabled
  public Boolean required;
  @AuraEnabled
  public String formFactor;
  @AuraEnabled
  public Boolean isReadOnly;
  @AuraEnabled
  public Map<String, Object> attributes;
  @AuraEnabled
  public String type;
  @AuraEnabled
  public String customCompName;
  @AuraEnabled
  public List<String> listenTo;
  @AuraEnabled
  public Boolean allowedToDispatch;
  @AuraEnabled
  public Boolean showCustomLabel;
  //Start for Front-13084
  @AuraEnabled
  public String placeholder;
  @AuraEnabled
  public String helpText;
  //End for Front-13084

  public SBR_3_0_DynamicRecordFormFieldDetail(Record_Field__mdt field){
    this.externalId = field.DeveloperName;
    this.label = field.Label__c;
    this.apiName = field.Api_Name__c;
    this.order = field.Order__c;
    this.required = field.Required__c;
    this.isReadOnly = field.Is_Read_Only__c;
    this.attributes = String.isBlank(field.Attributes__c)
      ? null
      : (Map<String, Object>) JSON.deserializeUntyped(field.Attributes__c);
    this.type = String.isBlank(field.Type__c)
      ? INPUT_FIELD_TYPE
      : field.Type__c;
    this.customCompName = field.Custom_Component_Name__c;
    this.listenTo = String.isNotBlank(field.Listen_To__c)
      ? field.Listen_To__c.split(',')
      : null;
    this.allowedToDispatch = field.Allow_To_Dispatch_Event__c;
    this.showCustomLabel = field.Show_Custom_Label__c;
    //Added for Front-13084
    this.helpText = field.HelpText__c;
    this.placeholder = field.Placeholder__c;
  }
}