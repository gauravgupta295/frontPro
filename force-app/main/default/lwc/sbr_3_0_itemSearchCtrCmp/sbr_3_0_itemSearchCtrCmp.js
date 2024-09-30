import { LightningElement, track, api, wire } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import getProfileBranchChronosDetails from "@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getBranchChronosDetailsNew";
import { Logger } from "c/sbr_3_0_frontlineUtils";
import FORM_FACTOR from "@salesforce/client/formFactor";

const logger = Logger.create(true);

export default class Sbr_3_0_itemSearchCtrCmp extends LightningElement {
  isMobile = false;
  isRendered = false;
  @api recordId;
  @api objectApiName;
  showAssetSpotlight = false;
  //to be used to explicitly sync customer information on sbr_3_0_itemSearchCtrCmp and sbr_3_0_lineItemsContainerCmp when inside sbr_3_0_quickQuoteContainerCmp
  @api
  get syncCustomer() {
    return this._selectedCustomer;
  }
  set syncCustomer(value) {
    if (value) {
      this._selectedCustomer = value.Id ? value : {};
    }
  }
  get syncCustomerName() {
    return this._selectedCustomer?.Name;
  }

  @api syncCartInfo;
  spotlightPanelHeight;
  _selectedCustomer = "";
  onRecordPage = false;
  @api tabsPanelHeight;
  fields = [];

  //mobile specific attributes start
  viewState = "base"; //possible values: base, filter, listview, custinfo, spotlight

  activeTab = "item-search";
  activeTabForheader = "Rental";
  selectedProducts = [];
  oldSelectedProduct;
  viewStateOld = "";
  locationInfo;
  activeAvailTab;
  isCustomerAdded = false;
  isCustomerAddedSpotlight = false;
  previousCustomer = false;
  customerName = "none";
  customerNumberToPass = "";

  callFilterCmp = false;
  isItemSearchPage; //11395

  // START FRONT-10483
  selectedClass = "slds-button slds-button_neutral active-state";
  unselectedClass = "slds-button slds-button_neutral selected-btn";
  rentalButtonClass = this.selectedClass;
  salesButtonClass = "slds-button slds-button_neutral selected-btn";
  assetButtonClass = "slds-button slds-button_neutral selected-btn";
  moreButtonClass =
    "slds-button slds-button_neutral slds-icon_xx-small selected-btn ";
  ccdVariant;
  ccVariant;
  moreVariant;
  // @track tabSequence=[{id:'1',label:'Cat Class Description' ,value:'Cat Class Description', variant:"success"},
  //                     {id:'2',label:'Cat Class' ,value:'Cat Class', variant:""}
  //                     ];
  // @track tabMenuSequence=[{id:'1',label:'Asset #' ,value:'Asset',variant:""},
  //                         {id:'2',label:'Serial #' ,value:'Serial',variant:""}]

  //END FRONT-10483
  //mobile specific attributes end

  //FRONT-1933
  activeSubTabName;
  //FRONT-11309
  locationInfoSales;
  @track selectedValueList;
  isContractSalesTab = false; //added for FRONT-15258,FRONT-15254
  showSpinner = true; //added for FRONT-15258

  //wire method to set customer information based on record page context
  @wire(getRecord, { recordId: "$recordId", fields: "$fields" })
  wiredRecord({ error, data }) {
    if (data) {
      let fieldsData;
      let recordTypeValue; //FRONT-15254,15258
      switch (this.objectApiName) {
        case "Cart__c":
          this.showSpinner = false; //added for FRONT-15258;
          fieldsData = data.fields.Account__r.value;

          break;
        case "SBQQ__Quote__c":
          this.showSpinner = false; //added for FRONT-15258;
          fieldsData = data.fields.SBQQ__Account__r.value;
          break;
        case "Order":
          fieldsData = data.fields.Account.value;
          recordTypeValue =
            data.fields.RecordType.value.fields.DeveloperName.value;
          //below condition added for FRONT-15258,15254
          if (recordTypeValue === "Create_Contract") {
            this.assetButtonClass = this.selectedClass;
            this.isContractSalesTab = true;
            this.activeTabForheader = "Asset"; //FRONT-15259
            this.activeSubTabName = "sales";
            this.showSpinner = false;
          } else {
            this.isContractSalesTab = false;
            this.activeTabForheader = "Rental"; //FRONT-15259
            this.showSpinner = false;
          }
          break;
        default:
          break;
      }
      if (fieldsData) {
        let acctInfo = {
          Id: fieldsData.fields.Id.value,
          Name: fieldsData.fields.Name.value,
          RM_Account_Number__c: fieldsData.fields.RM_Account_Number__c.value,
          RecordTypeId: fieldsData.recordTypeId,
          DisplayName: fieldsData.fields.Name.value
        };
        this._selectedCustomer = acctInfo;
        //getting issues when adding a contract item from Sales Tab
        let spotlightPanelCmp = this.template.querySelector(
          "c-sbr_3_0_spotlight-panel-cmp"
        );
        if (spotlightPanelCmp) {
          spotlightPanelCmp.updateCustomerInfo(this._selectedCustomer);
        }
        this.customerNumberToPass = acctInfo.RM_Account_Number__c;
      }
    } else if (error) {
      logger.log(error);
    }
  }

  //set fields to fetch for account information based on record page context
  setRecordFields() {
    switch (this.objectApiName) {
      case "Cart__c":
        this.fields = [
          "Cart__c.Account__r.Name",
          "Cart__c.Account__r.Id",
          "Cart__c.Account__r.RM_Account_Number__c"
        ];
        break;
      case "SBQQ__Quote__c":
        this.fields = [
          "SBQQ__Quote__c.SBQQ__Account__r.Name",
          "SBQQ__Quote__c.SBQQ__Account__r.Id",
          "SBQQ__Quote__c.SBQQ__Account__r.RM_Account_Number__c"
        ];
        break;
      case "Order":
        this.fields = [
          "Order.Account.Name",
          "Order.Account.Id",
          "Order.Account.RM_Account_Number__c",
          "Order.RecordType.DeveloperName"
        ];
        break;
      default:
        break;
    }
  }

  connectedCallback() {
    //this.isMobile = window.matchMedia("(max-width: 480px)").matches;
    this.isMobile = FORM_FACTOR === "Small";
    this.onRecordPage = this.recordId ? true : false;
    if (!this.recordId) {
      this.showSpinner = false; //added for FRONT-15258,FRONT-15254
    }
    if (this.onRecordPage) this.setRecordFields();
    this.isItemSearchPage = true; //FRONT-11395

    //FRONT-11309
    getProfileBranchChronosDetails({
      recordId: this.recordId,
      objectAPIName: this.objectApiName
    })
      .then((result) => {
        logger.log("User Location Info" + JSON.stringify(result));
        if (result.branch) this.locationInfoSales = result.branch;
        else this.locationInfoSales = result;
      })
      .catch((error) => {
        logger.log("Error in getProfileBranchChronosDetails", error.stack);
      });
  }

  /* buttonTabHandler(event){
    let state=event.target.value;

    if(state=="Cat Class Description"){
      this.ccdVariant="success";
      this.ccVariant="";

    }

    if(state=="Cat Class"){
      this.ccVariant="success";
      this.ccdVariant="";

    }
    if(state=="More"){
      this.moreVariant="success";

    }
    
  }
  */

  /*handleMenuClick(event){
    let state=event.target.value;

    if(state=='Cat Class'){
      this.tabSequence=[{id:'1',label:'Cat Class Description' ,value:'Cat Class Description',variant:""},
                      {id:'2',label:'Cat Class' ,value:'Cat Class',variant:"success"}
                      ];
      this.tabMenuSequence=[{id:'1',label:'Asset #' ,value:'Asset',variant:""},
                            {id:'2',label:'Serial #' ,value:'Serial',variant:""}]

    }

    if(state=="Asset"){

      this.tabSequence=[{id:'1',label:'Cat Class Description' ,value:'Cat Class Description',variant:""},
                      {id:'2',label:'Asset #' ,value:'Asset',variant:"success"}
                      ];
      this.tabMenuSequence=[{id:'1',label:'Cat Class' ,value:'Cat Class',variant:""},
                          {id:'2',label:'Serial #' ,value:'Serial',variant:""}]

    }
    if(state=="Serial"){
      this.tabSequence=[{id:'1',label:'Cat Class Description' ,value:'Cat Class Description',variant:""},
                      {id:'2',label:'Serial #' ,value:'Serial',variant:"success"}
                      ];
      this.tabMenuSequence=[{id:'1',label:'Cat Class' ,value:'Cat Class',variant:""},
                          {id:'2',label:'Asset #' ,value:'Asset',variant:""}]

    }

  }
*/
  renderedCallback() {
    if (!this.isMobile) {
      if (this.onRecordPage) {
        this.spotlightPanelHeight = this.tabsPanelHeight - 15;
      } else {
        this.spotlightPanelHeight =
          this.tabsPanelHeight -
          this.template.querySelector("c-sbr_3_0_customer-info-cmp")
            .offsetHeight -
          15;
      }
    }
  }

  closeproductsfilter() {
    //FRONT-15691
    this.template
      .querySelector("c-sbr_3_0_sales-product-filter-cmp")
      .closeProductFilter();
  }

  @api handleSelectedRows(event) {
    try {
      this.selectedProducts = []; //to remove the items selected from other tabs
      //FRONT-1933
      let spotLightPanelId = this.getSpotLinePanelId(event);
      if (!spotLightPanelId) {
        return;
      }

      /* FRONT - 1933 */
      if (this.activeSubTabName === "rental") {
        this.selectedProducts = event.detail;
        this.ratesSelectedProducts = this.selectedProducts;
        this.template
          .querySelector(
            `c-sbr_3_0_spotlight-panel-cmp[data-comp-id='${spotLightPanelId}']`
          )
          .toggleSpotlightPanel(this.selectedProducts);
      } else if (this.activeSubTabName === "sales") {
        this.selectedProducts = event.detail.selected;
        this.ratesSelectedProducts = this.selectedProducts;
        this.template
          .querySelector("c-sbr_3_0_consumabale-spotlight-panel-cmp")
          .toggleSpotlightPanel(this.selectedProducts);

        this.template
          .querySelector("c-sbr_3_0_consumabale-spotlight-panel-cmp")
          .checkSelectedvalue(event.detail.isSelectedValueNotMisc);
      } else if (this.activeSubTabName === "assets") {
        this.selectedProducts = event.detail;
        this.ratesSelectedProducts = this.selectedProducts;
        this.template
          .querySelector("c-sbr_3_0_asset-spotlight-cmp")
          .toggleSpotlightPanel(this.selectedProducts);
      }
      /* END : FRONT - 1933 */
    } catch (error) {
      logger.log("error in handleselected " + JSON.stringify(error));
    }
  }

  updateSelectedCustomer(event) {
    try {
      this._selectedCustomer = event.detail.selectedRecord
        ? event.detail.selectedRecord
        : null;
      this.template
        .querySelector("c-sbr_3_0_spotlight-panel-cmp")
        .updateCustomerInfo(this._selectedCustomer);
      if (!this.recordId) {
        //let selectedCustomer = event.detail;
        const selectedCustomerEvent = new CustomEvent("customerselection", {
          detail: { selectedRecord: { ...this._selectedCustomer } },
          bubbles: true,
          composed: true
        });
        this.dispatchEvent(selectedCustomerEvent);
      }
    } catch (error) {
      logger.log(
        "\n updating selected customer error - " + JSON.stringify(error)
      );
    }
  }

  handleViewCart() {
    const viewCartEvent = new CustomEvent("viewcart");
    this.dispatchEvent(viewCartEvent);
  }

  toggleProdInqMobileState(event) {
    this.viewStateOld = this.viewState;
    this.viewState = event.detail.viewState.valueOf();
    switch (this.viewState) {
      case "base":
        this.activeTab = "item-search";
        this.previousCustomer = false;
        break;
      case "filter":
        this.activeTab = "item-search";
        break;
      case "list-view":
        this.activeTab = "item-search";
        break;
      case "cust-info":
        this.activeTab = "cust-info";
        break;
      case "prod-filter":
        this.activeTab = "prod-filter";
        break;
      case "cart-info":
        this.activeTab = "cart-info";
        break;
      case "item-spotlight":
        this.activeTab = "item-spotlight";
        this.oldSelectedProduct = event.detail.product.valueOf();
        this.selectedProducts = [
          {
            Id: event.detail.product.Id?.valueOf(),
            Name: event.detail.product.Name?.valueOf(),
            Primary_Image_URL__c:
              event.detail.product.Primary_Image_URL__c?.valueOf(),
            Product_Category__c:
              event.detail.product.Product_Category__c?.valueOf(),
            Product_SKU__c: event.detail.product.Product_SKU__c?.valueOf(),
            Product_Sub_Category__c:
              event.detail.product.Product_Sub_Category__c?.valueOf(),
            Product_Type__c: event.detail.product.Product_Type__c?.valueOf(),
            Is_Kit__c: event.detail.product.Is_Kit__c?.valueOf(),
            Changeable__c: event.detail.product.Changeable__c?.valueOf()
          }
        ];
        this.template
          .querySelector("c-sbr_3_0_spotlight-panel-cmp")
          ?.toggleSpotlightPanel(this.selectedProducts);
        break;
      case "availability-asset":
        this.activeTab = "availability-asset";
        this.productCat = event.detail.productCat?.valueOf();
        this.activeAvailTab = event.detail.activeTab?.valueOf();
        this.locationInfo = event.detail.locationInfo?.valueOf();
        this.template
          .querySelector("c-sbr_3_0_availability-mobile-assets-cmp")
          ?.toggleAvailAssetPanel(
            this.productCat,
            this.activeAvailTab,
            this.locationInfo
          );
        break;
      default:
        break;
    }
  }

  sendCustomerSelected(event) {
    this.isCustomerAdded = event.detail.isCustomerSelected.valueOf();
    if (event.detail.viewState.valueOf() === "item-spotlight") {
      this.previousCustomer = event.detail.previousCustomer.valueOf();
    }
  }

  get productListContainerDisplay() {
    return this.activeTab === "item-search"
      ? "item-search show"
      : "item-search";
  }

  get itemSpotlightDisplay() {
    return this.activeTab === "item-spotlight"
      ? "item-spotlight show"
      : "item-spotlight";
  }

  get addCustomerInfoDisplay() {
    return this.activeTab === "cust-info" ? "cust-info show" : "cust-info";
  }

  get productFilterDisplay() {
    return this.activeTab === "prod-filter"
      ? "prod-filter show"
      : "prod-filter";
  }

  get availabilityAssetsDisplay() {
    return this.activeTab === "availability-asset"
      ? "availability-assets show"
      : "availability-assets";
  }

  showFilters() {
    this.callFilterCmp = !this.callFilterCmp;
    // FRONT - 1933
    let consumableSpotlightPanel = this.template.querySelector(
      ".consumableSpotlightPanel"
    );
    consumableSpotlightPanel.classList.toggle("hideConsumableSpotlightPanel");
  }

  /* FRONT - 10481 : Sales Tab Content*/
  _showTabsPanel = true;

  @api
  get showTabsPanel() {
    return this._showTabsPanel;
  }

  set showTabsPanel(value) {
    this._showTabsPanel = value;
  }
  /* END : FRONT - 10481*/

  //FRONT-10483
  tabChangeHandler(event) {
    let currentState = event.target.value;
    //  event.stopPropagation();
    //  event.preventDefault();
    this.rentalButtonClass = this.unselectedClass;
    this.salesButtonClass = this.unselectedClass;
    this.assetButtonClass = this.unselectedClass;

    switch (currentState) {
      case "Rental":
        this.rentalButtonClass = this.selectedClass;
        this.activeTabForheader = "Rental";
        break;

      case "Sales":
        this.salesButtonClass = this.selectedClass;
        this.activeTabForheader = "Sales";
        break;
      case "Asset":
        this.assetButtonClass = this.selectedClass;
        this.activeTabForheader = "Asset";

        break;
      default:
        break;
    }
  }

  get rentalDisplay() {
    return this.activeTabForheader === "Rental" ? "rental show" : "rental-hide";
  }

  get salesDisplay() {
    return this.activeTabForheader === "Sales" ? "sales show" : "asset-hide";
  }

  get assetDisplay() {
    return this.activeTabForheader === "Asset" ? "asset show" : "sales-hide";
  }

  //FRONT-1933
  getSpotLinePanelId(event) {
    let spotLightPanelId;
    let compId = event.target.dataset.compId;
    if (compId === "salesItemSearchContainer") {
      spotLightPanelId = "salesSpotLightPanel";
    } else if (compId === "rentalItemSearchContainer") {
      spotLightPanelId = "rentalSpotLightPanel";
    } else if (compId === "assetItemSearchContainer") {
      spotLightPanelId = "assetSpotLightPanel";
    }
    return spotLightPanelId;
  }

  //FRONT-1933
  activeTabHandler(event) {
    this.activeSubTabName = event.target.value;
  }

  //FRONT-11319
  handleSpotlight(event) {
    this.showAssetSpotlight = event.detail.showSpotlight;
  }

  applySalesProductFilters(event) {
    this.template
      .querySelector(
        "c-sbr_3_0_sales-item-search-container-cmp[data-comp-id=salesItemSearchContainer]"
      )
      .handleApplyProductFilter(
        event.detail.availableOnly,
        event.detail.stockVendorValue,
        event.detail.manufacturerValue
      );
    this.showFilters();
  }

  handleBackToItemSearchButton() {
    const salesDataBox = this.template.querySelector(".showSalesData");
    salesDataBox.classList.toggle("slds-show");
  }

  //FRONT-11309
  productFilterPillRemoveHandler(event) {
    this.template
      .querySelector(
        "c-sbr_3_0_sales-product-filter-cmp[data-comp-id='salesProductFilter']"
      )
      .updateSelectedProductFilters(
        event.detail.availableOnly,
        event.detail.stockVendorValue,
        event.detail.manufacturerValue
      );
  }
}