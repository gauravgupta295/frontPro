import { LightningElement, api } from 'lwc';
import getChronosStatus from "@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getProfileBranchChronosDetails";
import Sbr_3_0_lineitemEditorCmp from "@salesforce/resourceUrl/Pros_NonCredit_Css";
import { loadStyle } from "lightning/platformResourceLoader";

export default class Sbr_3_0_lineItemEditAvailabilityComponent extends LightningElement {

  @api locationInfo;
  @api productCat;

  title;
  _branchNumber;
  originalBranchNumber;
  activetabContent = "";
  isModalOpen = true;
  showAvailability = false;
  //isBranchOpen = true;
  isMobile;
  isBranchOpen = false;
  branchName;
  branchHeaderText;
  cancelButtonLabel = "Cancel";
  isAssetPageOpen = false; //FRONT-1668 and 1937

  connectedCallback() {
    this.isMobile = window.matchMedia("(max-width: 480px)").matches;
    if (this.isMobile) {
      loadStyle(this, Sbr_3_0_lineitemEditorCmp);
    }
    if (this.locationInfo) {
      this.initializeData();
    } else {
      getChronosStatus().then((result) => {
        this.locationInfo = result;
        this.initializeData();
      });
    }
  }

  //FRONT-1668 and 1937
  @api initializePropFromLineEditorWrapperCmp() {
    this.isBranchOpen = true;
  }

  initializeData() {
    this.showAvailability = true;
    this._branchNumber = this.locationInfo.branch.Branch_Location_Number__c;
    this.originalBranchNumber = this._branchNumber;
    this.branchHeaderText = "Assets: Branch " + this._branchNumber;
    this.branchName = "Branch " + this._branchNumber;
    this.activetabContent = "Branch";
    this.isBranchOpen = true;
  }

  handleUpdateHeader(event) {
    //FRONT-1668 and 1937
    this.branchHeaderText = event.detail;
  }

  openBranch(evt) {
    if (evt.detail == null && this.locationInfo) {
      this._branchNumber = this.locationInfo.Branch_Location_Number__c;
    } else {
      this._branchNumber = evt.detail;
    }
    this.activetabContent = "Branch";
    //this.branchName = "Branch " + this.originalBranchNumber;
    this.branchName = "Branch " + this._branchNumber;
    /*this.branchHeaderText = "Assets: Branch " + this.branchNumber;*/
    this.isBranchOpen = true;
  }
  
  tabChangeHandler(event) {
    this.activetabContent = event.target.value;
    if (this.activetabContent == "Branch") {//FRONT-8722 and FRONT-8721
      this.isBranchOpen = true;
    } else {
      this.closeBranch();
      if (this.activetabContent == "District") {
        this.title = this.locationInfo.District__c;
      } else if (this.activetabContent == "Region") {
        this.title = this.locationInfo.Region__c;
      } else if (this.activetabContent == "Territory") {
        this.title = this.locationInfo.Territory__c;
      } else if (this.activetabContent == "Company") {
        this.title = this.locationInfo.Company__c;
      }
    }
  }

  closeBranch() {//FRONT-8722 and FRONT-8721
    this.isBranchOpen = false;
  }

  handlePageBack() {
    if (this.isBranchOpen == true) {
      this.template
        .querySelector("c-sbr_3_0_availability-modal-info-cmp")
        .pageBack();
    }
  }

  handleReturnPage() {
    this.isBranchOpen = false;
    this.activetabContent = "District";
  }

  //FRONT-1668 and 1937
  handleChangePage(event){
    this.isAssetPageOpen = event.detail.isAssetPageOpen;
  }
  //*FRONT-8722 and FRONT-8721 start
  @api setDefaultBranch() {
    this.initializeData();
  }

  @api hideAvailability() {
    this.showAvailability= false;
  }

  get branchNumber() {
    return this._branchNumber;
  }

  //*FRONT-8722 and FRONT-8721 end
}