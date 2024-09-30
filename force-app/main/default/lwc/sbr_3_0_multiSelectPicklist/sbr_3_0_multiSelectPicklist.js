import { LightningElement, api, track } from "lwc";

export default class Sbr_3_0_multiSelectPicklist extends LightningElement {
  @api options;
  @api selectedValue;
  @api selectedValues = [];
  @api label;
  @api disabled = false;
  @track isAnySelected;
  @api isAnyChecked;
  @api multiSelect = false;
  @track value;
  @track values = [];
  @track optionData;
  @track searchString;
  @track noResultMessage;
  @track showDropdown = false;
  @api isMobile;
  //FRONT-7406
  @track valuePlaceholder = "Any Status";
  @api isShowSelectedStatusCount = false;
  commonCss = "slds-listbox slds-listbox_vertical recordListBox";
  dropdownCss = "slds-dropdown slds-dropdown_length-10";
  isDropdownCloseFlag = false;

  applyCssOnDevice() {
    if (!this.isMobile) {
      this.commonCss = this.commonCss + " content";
      this.dropdownCss = this.dropdownCss + " slds-dropdown_right";
    } else {
      this.dropdownCss = this.dropdownCss + " slds-dropdown_fluid";
    }
  }

  connectedCallback() {
    this.applyCssOnDevice();

    console.log("options: " + JSON.parse(JSON.stringify(this.options)));
    this.showDropdown = false;
    let optionData = this.options
      ? JSON.parse(JSON.stringify(this.options))
      : null;
    let value = this.selectedValue
      ? JSON.parse(JSON.stringify(this.selectedValue))
      : null;
    let values = this.selectedValues
      ? JSON.parse(JSON.stringify(this.selectedValues))
      : null;

    if (this.isAnyChecked) {
      //this.selectedValues.push("Any Status");
      values.push("Any Status");
    }

    if (this.values === null) {
      this.values = [];
      values.push("Any Status");
    }

    if (value || values) {
      let searchString;
      let count = 0;
      for (let i = 0; i < optionData.length; i++) {
        if (this.multiSelect) {
          if (
            values.includes(optionData[i].value) ||
            values.includes("Any Status")
          ) {
            optionData[i].selected = true;
            this.values.push(optionData[i].label);
            count++;
          }
        } else {
          if (optionData[i].value == value) {
            searchString = optionData[i].label;
          }
        }
      }
      if (this.values.includes("Any Status")) {
        this.values.splice(this.values.indexOf("Any Status"), 1);
      }
      //let selectedVal="Any Status";
      //this.executeSelectItem(selectedVal);
      if (this.multiSelect) this.searchString = count + " Filter(s) Selected";
      else this.searchString = searchString;
    }
    this.value = value;
    //this.values = values;
    this.optionData = optionData;
  }

  selectItem(event) {
    this.handleMouseIn();
    let selectedVal = event.currentTarget.dataset.id;
    this.executeSelectItem(selectedVal);
  }

  executeSelectItem(selected) {
    let selectedVal = selected;
    if (selectedVal) {
      let anyStatusCheckVal;
      let count = 0;
      let options = JSON.parse(JSON.stringify(this.optionData));
      if (selectedVal === "Any Status") {
        this.isAnyChecked = true;
      } else {
        this.isAnyChecked = false;
      }
      for (let i = 0; i < options.length; i++) {
        if (selectedVal === "Any Status") {
          if (options[i].value === "Any Status") {
            options[i].selected = options[i].selected ? false : true;
            anyStatusCheckVal = options[i].selected;
            this.values = [];
          } else {
            options[i].selected = anyStatusCheckVal;
            if (anyStatusCheckVal) this.values.push(options[i].value);
          }
        } else if (options[i].value === selectedVal) {
          if (this.multiSelect) {
            if (this.values.includes(options[i].value)) {
              this.values.splice(this.values.indexOf(options[i].value), 1);
            } else {
              this.values.push(options[i].value);
            }
            options[i].selected = options[i].selected ? false : true;
          } else {
            this.value = options[i].value;
            this.searchString = options[i].label;
          }
        } else if (
          options[i].value === "Any Status" &&
          this.isSelectAnyStatus(selectedVal)
        ) {
          //FRONT-13131 and 13132
          options[i].selected = true;
        } else if (options[i].value === "Any Status") {
          options[i].selected = false;
        }

        if (options[i].selected) {
          count++;
        }
      }
      this.optionData = options;
      if (this.multiSelect) {
        this.searchString = count + " Filter(s) Selected";
      }

      if (!this.multiSelect) {
        let ev = new CustomEvent("selectoption", {
          detail: {
            selectedStatus: this.values,
            isAnyChecked: this.isAnyChecked
          }
        });
        this.dispatchEvent(ev);
      }

      if (this.multiSelect) event.preventDefault();
      else this.showDropdown = false;
    }

    if (this.isMobile) {
      this.applyFilters();
    }
  }

  //FRONT-13131 and 13132
  isSelectAnyStatus(selectedVal) {
    let isSelectedAnyStatus = false;
    let arrayset = [];
    let booleanvalue;
    let options = JSON.parse(JSON.stringify(this.optionData));
    for (let i = 1; i < options.length; i++) {
      if (options[i].value === selectedVal) {
        options[i].selected = options[i].selected ? false : true;
      }
      if (options[i].value !== "Any Status") {
        arrayset.push(options[i].selected);
      }
    }

    booleanvalue = arrayset.every(checkboolean);
    function checkboolean(arraysetvalue) {
      return arraysetvalue == true;
    }
    if (booleanvalue == false) {
      isSelectedAnyStatus = false;
      this.isAnyChecked = false;
    } else {
      isSelectedAnyStatus = true;
      this.isAnyChecked = true;
    }
    return isSelectedAnyStatus;
  }

  showOptions() {
    if (!this.disabled && this.options) {
      this.noResultMessage = "";
      this.searchString = "";
      let options = JSON.parse(JSON.stringify(this.optionData));
      for (let i = 0; i < options.length; i++) {
        options[i].isVisible = true;
      }
      if (options.length > 0) {
        this.showDropdown = true;
      }
      this.optionData = options;
    }
  }

  closeAllPill() {
    var count = 0;
    this.values = [];
    var options = JSON.parse(JSON.stringify(this.optionData));
    for (let i = 0; i < options.length; i++) {
      // if (!options[i].selected) {
      if (options[i].value !== "Any Status") this.values.push(options[i].value);
      options[i].selected = true;

      // }
      if (options[i].selected) {
        count++;
      }
    }
    this.optionData = options;
    if (this.multiSelect) {
      this.searchString = count + " Filter(s) Selected";
      let ev = new CustomEvent("selectoption", {
        detail: {
          selectedStatus: this.values,
          isAnyChecked: this.isAnyChecked
        }
      });
      this.dispatchEvent(ev);
    }

    //FRONT-7406
    this.showSelectedStatusCount();
  }

  @api
  updateFilters(removedItem) {
    let count = 0;
    let options = JSON.parse(JSON.stringify(this.optionData));
    for (let i = 0; i < options.length; i++) {
      if (options[i].value === removedItem.label) {
        options[i].selected = false;
        this.values.splice(this.values.indexOf(options[i].value), 1);
      }
      if (options[i].selected) {
        count++;
      }
    }
    this.optionData = options;
    if (this.multiSelect) {
      this.searchString = count + " Filter(s) Selected";
    }

    //FRONT-7406
    this.showSelectedStatusCount();
  }

  handleMouseOut() {
    this.showDropdown = false;
    this.isDropdownCloseFlag = false;
  }

  //FRONT-22933
  handleMouseIn() {
    if (this.isDropdownCloseFlag === false) {
      this.showDropdown = true;
      this.isDropdownCloseFlag = true;
    } else if (this.isDropdownCloseFlag === true) {
      this.showDropdown = false;
      this.isDropdownCloseFlag = false;
    }
  }

  applyFilters() {
    let ev = new CustomEvent("selectoption", {
      detail: {
        selectedStatus: this.values,
        isAnyChecked: this.isAnyChecked
      }
    });
    this.dispatchEvent(ev);
    if (!this.isMobile) this.handleMouseOut();
    //FRONT-7406
    this.showSelectedStatusCount();
  }

  //FRONT-7406
  showSelectedStatusCount() {
    if (this.isShowSelectedStatusCount && this.optionData) {
      let allSelected = false;
      let count = 0;
      let options = JSON.parse(JSON.stringify(this.optionData));
      options.forEach((item) => {
        if (item.selected) {
          if (item.value === "Any Status") {
            allSelected = true;
          }
          count++;
        }
      });
      if (allSelected) {
        this.valuePlaceholder = "Any Status";
      } else {
        this.valuePlaceholder = "Status : (" + count + ")";
      }
    }
  }

  @api
  resetFilters() {
    this.isAnyChecked = true;
    this.closeAllPill();
    this.handleMouseOut();
  }
  toStartCaps(status) {
    return status
      .split(" ")
      .map((word) => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
      .join(" ");
  }
}