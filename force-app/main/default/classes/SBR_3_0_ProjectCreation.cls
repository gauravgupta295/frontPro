/*********************************************************************************************************************
* Apex Class: SBR_3_0_ProjectCreation
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to allow Lead conversion flow to bypass duplicate alerts when creating a new project
* - SAL-178
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Konrad Haight           2022-05-24         Initial version    
*********************************************************************************************************************/
public without sharing class SBR_3_0_ProjectCreation {
  @InvocableMethod(
    label='Create Project'
    description='Create Project using details entered in Convert Lead flow'
  )
  public static List<ProjectCreationWrapper> createProject(
    List<ProjectCreationWrapper> wrappers
  ) {
    List<ProjectCreationWrapper> result = new List<ProjectCreationWrapper>();
    ProjectCreationWrapper w = new ProjectCreationWrapper();

    if (wrappers.size() > 0) {
      ProjectCreationWrapper wrap = wrappers.get(0);
      Project__c p = new Project__c();
      p.City__c = wrap.city;
      p.State__c = wrap.state;
      p.ZIP_Code__c = wrap.zip;
      p.Country__c = wrap.country;
      p.Street__c = wrap.street;
      p.Project_Name__c = wrap.name;

      Database.DMLOptions dml = new Database.DMLOptions();
      dml.DuplicateRuleHeader.AllowSave = true;

      Database.insert(p, dml);

      w.city = wrap.city;
      w.state = wrap.state;
      w.name = wrap.name;
      w.projectId = p.id;

      System.debug(w);
      result.add(w);
    }
    return result;
  }

  public class ProjectCreationWrapper {
    @InvocableVariable(label='Project City' required=true)
    public String city;

    @InvocableVariable(label='Project Name' required=true)
    public String name;

    @InvocableVariable(label='Project State' required=true)
    public String state;

    @InvocableVariable(label='Project Id' required=false)
    public String projectId;

    @InvocableVariable(label='Project Zip Code' required=false)
    public String zip;

    @InvocableVariable(label='Project Street' required=false)
    public String street;

    @InvocableVariable(label='Project Country' required=false)
    public String country;
  }

  public class ProjectCreationException extends Exception {
  }
}