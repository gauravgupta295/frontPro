import { LightningElement, api } from 'lwc';

export default class Sbr_3_0_POSearchableCombobox extends LightningElement {

    isOpen = false;
    highlightCounter = null;
    _maxLength = 200;
    _value = "";
    _recordId = '';
    _optionValue = ''

    @api messageWhenInvalid = "Please type or select a value";
    @api required = false;

    @api
    get maxLength() {
        return this._maxLength;
    }

    set maxLength(val) {
        this._maxLength = val;
    }
    

    @api
    get value() {
        return this._value;
    }

    set value(val) {
        this._value = val;
    }

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(recId) {
        this._recordId = recId;
    }


    @api label = "Select";

    _options = [
        {
            id: this._recordId,
            label: '--None--',
            value: this._value
        }
    ];

    @api
    get options() {
        return this._options;
    }

    set options(val) {
        this._options = val || [];
    }

    get tempOptions() {
        let options = this.options;
        if (this.value) {
            options = this.options.filter((op) => op.label.toLowerCase().includes(this.value.toLowerCase()));
        }
        return this.highLightOption(options);
    }

    get isInvalid() {
        return this.required && !this.value;
    }

    handleChange(event) {
        this._value = event.target.value;
        this.fireChange();
    }

    handleInput(event) {
        this.isOpen = true;
    }

    fireChange() {
        let recId = (this._value == this._optionValue) ? this._recordId : undefined;
        this.dispatchEvent(new CustomEvent("change", { detail: { id: recId, value: this._value } }));
    }

    get classes() {
        let classes = "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click";
        if (this.isOpen) {
            return classes + " slds-is-open";
        }
        return classes;
    }

    get inputClasses() {
        let inputClasses = "slds-input slds-combobox__input";
        if (this.isOpen) {
            return inputClasses + " slds-has-focus";
        }
        return inputClasses;
    }

    allowBlur() {
        this._cancelBlur = false;
    }

    cancelBlur() {
        this._cancelBlur = true;
    }

    handleDropdownMouseDown(event) {
        const mainButton = 0;
        if (event.button === mainButton) {
            this.cancelBlur();
        }
    }

    handleDropdownMouseUp() {
        this.allowBlur();
    }

    handleDropdownMouseLeave() {
        if (!this._inputHasFocus) {
            this.showList = false;
        }
    }

    handleBlur() {
        this._inputHasFocus = false;
        if (this._cancelBlur) {
            return;
        }
        this.isOpen = false;

        this.highlightCounter = null;
        this.dispatchEvent(new CustomEvent("blur"));
    }

    handleFocus() {
        this._inputHasFocus = true;
        this.isOpen = true;
        this.highlightCounter = null;
        this.dispatchEvent(new CustomEvent("focus"));
    }

    handleSelect(event) {
        this.isOpen = false;
        this.allowBlur();
        this._value = event.currentTarget.dataset.value;
        this._recordId = event.currentTarget.dataset.recordid;
        this._optionValue = event.currentTarget.dataset.value;
        this.fireChange();
    }

    handleKeyDown(event) {
        if (event.key == "Escape") {
            this.isOpen = !this.isOpen;
            this.highlightCounter = null;
        } else if (event.key === "Enter" && this.isOpen) {
            if (this.highlightCounter !== null) {
                this.isOpen = false;
                this.allowBlur();
                this._value = this.tempOptions[this.highlightCounter].value;
                this._recordId = this.tempOptions[this.highlightCounter].id;
                this._optionValue = this.tempOptions[this.highlightCounter].value;
                this.fireChange();
            }
        } else if (event.key === "Enter") {
            this.handleFocus();
        }

        if (event.key === "ArrowDown" || event.key === "PageDown") {
            this._inputHasFocus = true;
            this.isOpen = true;
            this.highlightCounter = this.highlightCounter === null ? 0 : this.highlightCounter + 1;
        } else if (event.key === "ArrowUp" || event.key === "PageUp") {
            this._inputHasFocus = true;
            this.isOpen = true;
            this.highlightCounter = this.highlightCounter === null || this.highlightCounter === 0 ? this.tempOptions.length - 1 : this.highlightCounter - 1;
        }

        if (event.key === "ArrowDown" || event.key === "ArrowUp") {
            this.highlightCounter = Math.abs(this.highlightCounter) % this.tempOptions.length;
        }

        if (event.key === "Home") {
            this.highlightCounter = 0;
        } else if (event.key === "End") {
            this.highlightCounter = this.tempOptions.length - 1;
        }
    }

    highLightOption(options) {
        let classes = "slds-media slds-listbox__option slds-listbox__option_plain slds-media_small";

        return options.map((option, index) => {
            let cs = classes;
            let focused = "";
            if (index === this.highlightCounter) {
                cs = classes + " slds-has-focus";
                focused = "yes";
            }
            return { classes: cs, focused, ...option };
        });
    }

    renderedCallback() {
        this.template.querySelector("[data-focused='yes']")?.scrollIntoView();
    }


}