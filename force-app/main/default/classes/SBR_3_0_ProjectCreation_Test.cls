/*********************************************************************************************************************
* Apex Class: SBR_3_0_ProjectCreation_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to test SBR_3_0_ProjectCreation
* - SAL-178
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Konrad Haight           2022-05-24         Initial version    
*********************************************************************************************************************/
@isTest
public without sharing class SBR_3_0_ProjectCreation_Test {
  @isTest
  static void testCreateProject() {
    List<SBR_3_0_ProjectCreation.ProjectCreationWrapper> wrappers = new List<SBR_3_0_ProjectCreation.ProjectCreationWrapper>();

    SBR_3_0_ProjectCreation.ProjectCreationWrapper w = new SBR_3_0_ProjectCreation.ProjectCreationWrapper();

    w.city = 'Test City';
    w.state = 'Test State';
    w.name = 'Test Name';

    wrappers.add(w);

    //create inner class instance with leadId set to new lead.Id
    Test.startTest();
    List<SBR_3_0_ProjectCreation.ProjectCreationWrapper> result = SBR_3_0_ProjectCreation.createProject(
      wrappers
    );
    Test.stopTest();

    SBR_3_0_ProjectCreation.ProjectCreationWrapper wrap = result[0];

    System.assertEquals(
      wrap.name,
      'Test Name',
      'Project name should match'
    );
  }
}