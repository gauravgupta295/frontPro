public with sharing class SBR_3_0_DynamicRecordFormPageDetail {
  @AuraEnabled
  public String label;
  @AuraEnabled
  public String externalId;
  @AuraEnabled
  public String objName;
  @AuraEnabled
  public String styleSheet;
  @AuraEnabled
  public List<SBR_3_0_DynamicRecordFormSectionDetail> sections;
  public String parentPageName;
  @AuraEnabled
  public List<SBR_3_0_DynamicRecordFormPageDetail> childrenPages;
  @AuraEnabled
  public Boolean hasChildrenPages {
    get {
      return this.childrenPages <> null && !this.childrenPages.isEmpty();
    }
  }
  /* Added helptext as part of FRONT-15703*/
  @AuraEnabled
  public String helpText;
  public SBR_3_0_DynamicRecordFormPageDetail(Record_Page__mdt recordPage) {
    this.externalId = recordPage.DeveloperName;
    this.objName = recordPage.SObject_Name__c;
    this.sections = new List<SBR_3_0_DynamicRecordFormSectionDetail>();
    this.label = recordPage.Label__c;
    this.childrenPages = new List<SBR_3_0_DynamicRecordFormPageDetail>();
    this.helpText = recordPage.HelpText__c;
  }
}