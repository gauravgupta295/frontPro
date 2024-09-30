import { LightningElement, api, track } from "lwc";
import getUserLocationDtls from "@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getBranchChronosDetails"; //SADAPUR

export default class SBR_3_0_searchJobSiteAndLocationCmp extends LightningElement {
  @api recordId;
  @api jobLocationId;
  @api jobSiteId;
  @api contactId;
  @api jobLocationRecordTypeId;
  @api createNewJobLocation;
  @api createNewJobSite;
  @api companyCode = "01";
  @api noJobSiteChecked = false;
  @api showJobSiteCheckbox;
  @track mobileMainDiv = "";
  status = "A";
  isJobLocationSelected = false;
  jobLocationWhereClause;
  jobSiteWhereClause;
  contactWhereClause;
  //Start for FRONT-4843
  isFrontline = "";
  @api LastLoginApp;
  @api RecordTypeName;
  //End for FRONT-4843
  connectedCallback() {
  	if (window.matchMedia("(max-width: 480px)").matches) {
      this.mobileMainDiv = "mobileMainDiv";
   	}
    //Start for FRONT-4843

    if (
      this.LastLoginApp == "RAE_Frontline" &&
      this.RecordTypeName == "Non-Credit"
    ) {
      this.isFrontline = true;
    }
    //end for FRONT-4843

    this.checkInitialValues();
  }

  renderedCallback() {
    if (this.noJobSiteChecked) {
      let checkbox = this.template.querySelector("lightning-input");
      checkbox.checked = true;
    }
  }

  checkInitialValues() {
    if (
      typeof this.createNewJobLocation === "undefined" ||
      this.createNewJobLocation === null
    ) {
      this.createNewJobLocation = false;
    }
    if (
      typeof this.createNewJobSite === "undefined" ||
      this.createNewJobSite === null
    ) {
      this.createNewJobSite = false;
    }
    if (
      typeof this.jobLocationId !== "undefined" &&
      this.jobLocationId !== null
    ) {
      this.isJobLocationSelected = true;
    }
    //SADAPUR
    getUserLocationDtls()
      .then((result) => {
        console.log("Result->" + JSON.stringify(result));
        if (result != null) {
          console.log("Company_Code__c->" + result.Company_Code__c);
          this.companyCode = result.Company_Code__c;

          console.log("this.companyCode->" + this.companyCode);
        }
      })
      .catch((error) => {
        console.log("fetch USER-LOCATION error", error);
      });
  }

  get options() {
    return [
      { label: "Create New", value: true },
      { label: "Choose Existing", value: false },
      { label: "Job Site Same as Billing", value: null}
    ];
  }

  get JobSiteOptions() {
    return [
      { label: "Create New", value: true },
      { label: "Choose Existing", value: false }
    ];
  }

  //start for 4843
  get optionsfrontline() {
    return [{ label: "Choose Existing", value: false }];
  }
  //end for 4843

  handleCheckboxChange(event) {
    this.noJobSiteChecked = event.target.checked;
  }

  handleChange(event) {
    const { name, value } = event.target;
    console.log("Changing");
    if (name === "jobLocationRadio") {
      this.createNewJobLocation = value === "true" ? true : false;
      this.createNewJobSite = value === "true" ? true : false;
      this.jobLocationId = "";
      this.isJobLocationSelected = false;
    } else if (name === "jobSiteRadio") {
      this.createNewJobSite = value === "true" ? true : false;
      this.jobSiteId = "";
    }
  }

  handleJobLocationChange(event) {
    if (event.detail.selectedRecord !== undefined) {
      this.jobLocationId = event.detail.selectedRecord.Id;
      this.jobSiteId = "";
      this.isJobLocationSelected = true;
    } else {
      this.jobLocationId = "";
      this.jobSiteId = "";
      this.isJobLocationSelected = false;
    }
  }

  handleJobSiteChange(event) {
    if (event.detail.selectedRecord !== undefined) {
      this.jobSiteId = event.detail.selectedRecord.Id;
    } else {
      this.jobSiteId = "";
    }
  }

  // handleContactChange(event) {
  //     if(event.detail.selectedRecord !== undefined) {
  //         this.contactId = event.detail.selectedRecord.Id;
  //     }
  //     else {
  //         this.contactId = '';
  //     }
  // }

  get jobLocationWhere() {
    this.jobLocationWhereClause =
      "RecordTypeId = '" +
      this.jobLocationRecordTypeId +
      "' AND Company_Code__c = '" +
      this.companyCode +
      "'";
    return this.jobLocationWhereClause;
  }

  get jobSiteWhere() {
    this.jobSiteWhereClause =
      "ParentRecordId = '" +
      this.recordId +
      "' AND LocationId = '" +
      this.jobLocationId +
      "' AND Status__c = '" +
      this.status +
      "'";
    return this.jobSiteWhereClause;
  }
  // get contactWhere() {
  //     this.contactWhereClause = 'AccountId = \'' + this.recordId + '\'';
  //     return this.contactWhereClause;
  // }
}