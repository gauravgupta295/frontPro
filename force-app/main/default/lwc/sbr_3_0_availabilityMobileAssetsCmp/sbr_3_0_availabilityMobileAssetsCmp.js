import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";

export default class sbr_3_0_AvailabilityMobileAssetsCmp extends NavigationMixin(
  LightningElement
) {
  @api selectedProduct;
  @api locationInfo;

  isMobileAssets = true;
  nonBranchHeader = "Availability";
  header;
  productCat;
  activeTabContent;
  previousTab;
  tabs = true;
  title;
  isBranchOpen = false;
  branchNumber;
  _branchName; //FRONT-8722

  tabClass =
    "tab-button slds-m-horizontal_xx-small";
  selectedTabClass =
    "tab-button slds-m-horizontal_xx-small slds-button slds-button_neutral active-state";
  notSelectedBranchTabClass =
    "tab-button slds-m-horizontal_xx-small slds-button slds-button_neutral branch-button-inactive"; //FRONT-8722
  selectedBranchTabClass =
    "slds-m-horizontal_xx-small slds-button slds-button_neutral active-state branch-button"; //FRONT-8722
  branchTabClass; //FRONT-8722
  districtTabClass;
  regionTabClass;
  territoryTabClass;
  companyTabClass;
  districtShowTable = false;
  regionShowTable = false;
  territoryShowTable = false;
  companyShowTable = false;

  @api
  toggleAvailAssetPanel(productCat, activeTabContent, locationInfo) {
    this.productCat = productCat;
    this.activeTabContent = activeTabContent;
    this.locationInfo = locationInfo;
    this._branchName = "Branch: " + this.locationInfo.Branch_Location_Number__c;

    this.branchNumber = this.locationInfo?.Branch_Location_Number__c;

    if (this.activeTabContent === "Branch") {
      /*
      Commented as a part of retrofit activity
      this.tabs = false;
      // this.header = "Assets: Branch " + this.branchNumber;
      this.updateHeader({ detail: "Assets: Branch " + this.branchNumber });
      */
      this.isBranchOpen = true;
    } else {
      this.isBranchOpen = false;
      this.tabs = true;
      // this.header = this.nonBranchHeader;
      this.updateHeader();
      if (this.activeTabContent === "District") {
        this.title = this.locationInfo.District__c;
      } else if (this.activeTabContent === "Region") {
        this.title = this.locationInfo.Region__c;
      } else if (this.activeTabContent === "Territory") {
        this.title = this.locationInfo.Territory__c;
      } else if (this.activeTabContent === "Company") {
        this.title = this.locationInfo.Company__c;
      }
    }

    this.setTabClasses(this.activeTabContent);
  }

  updateHeader(evt) {
    if (evt) {
      this.header = evt.detail;
    } else {
      this.header = this.nonBranchHeader;
    }
  }

  handleBackButton() {
    if (this.isBranchOpen) {
      // this.updateHeader({ detail: "Assets: Branch " + this.branchNumber }); Commented as a part of retrofit activity
      this.template
        .querySelector("c-sbr_3_0_availability-modal-info-cmp")
        ?.pageBack();
    } else {
      this.backToSpotlight();
    }
  }

  backToSpotlight() {
    this.isBranchOpen = false;
    const toggleprodinqmobilestate = new CustomEvent(
      "toggleprodinqmobilestate",
      {
        bubbles: true,
        composed: true,
        detail: {
          viewState: "item-spotlight",
          product: this.selectedProduct,
          showTabsPanel: false
        }
      }
    );
    this.dispatchEvent(toggleprodinqmobilestate);
  }

  navigateHome() {
    this[NavigationMixin.Navigate]({
      type: "standard__namedPage",
      attributes: {
        pageName: "home"
      }
    });
  }

  handleBranchTab() {
    this.openBranch({ detail: this.locationInfo.Branch_Location_Number__c });
  }

  //FRONT-8722 & 8721 Branch moved from modal to tabs
  openBranch(evt) {
    this.branchNumber = evt.detail;
    //this.tabs = false;
    this.previousTab = this.activeTabContent;
    //this.header = "Assets: Branch " + this.branchNumber;
    this._branchName = "Branch: " + this.branchNumber;
    this.setTabClasses("Branch");
    this.isBranchOpen = true;
  }

  closeBranch() {
    if (this.previousTab) {
      this.header = this.nonBranchHeader;
      this.activeTabContent = this.previousTab;
      this.tabs = true;
      this.isBranchOpen = false;
    } else {
      this.backToSpotlight();
    }
  }

  tabChangeHandler(event) {
    this.activeTabContent = event.target.value;
    if (this.activeTabContent == "Branch") {
      //FRONT-8722 & 8721 Branch moved from modal to tabs
      this.handleBranchTab();
    } else {
      this.isBranchOpen = false;
      this._branchName = "Branch: " + this.branchNumber;
      if (this.activeTabContent == "District") {
        this.title = this.locationInfo.District__c;
      } else if (this.activeTabContent == "Region") {
        this.title = this.locationInfo.Region__c;
      } else if (this.activeTabContent == "Territory") {
        this.title = this.locationInfo.Territory__c;
      } else if (this.activeTabContent == "Company") {
        this.title = this.locationInfo.Company__c;
      }
    }

    this.setTabClasses(this.activeTabContent);
  }

  setTabClasses(activeTab) {
    this.branchTabClass =
      activeTab === "Branch" ? this.selectedBranchTabClass : this.tabClass; //FRONT-8722 & 8721 Branch moved from modal to tabs
    this.districtTabClass =
      activeTab === "District" ? this.selectedTabClass : this.tabClass;
    this.regionTabClass =
      activeTab === "Region" ? this.selectedTabClass : this.tabClass;
    this.territoryTabClass =
      activeTab === "Territory" ? this.selectedTabClass : this.tabClass;
    this.companyTabClass =
      activeTab === "Company" ? this.selectedTabClass : this.tabClass;

    this.districtShowTable = activeTab === "District";
    this.regionShowTable = activeTab === "Region";
    this.territoryShowTable = activeTab === "Territory";
    this.companyShowTable = activeTab === "Company";
  }

  get branchName() {
    return this._branchName;
  }
}