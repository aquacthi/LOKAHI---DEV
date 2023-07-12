import { LightningElement, track, api } from 'lwc';

export default class MultiSelectPicklist extends LightningElement {

    value = [];
    hasRendered;
    comboboxIsRendered;
    dropDownInFocus = false;
    _disabled = false;
    _allData = '';
    _toggle = false;

    @track inputValue = '';
    @track inputOptions;

    @api label = "Default label";

    @api
    get disabled(){
        return this._disabled;
    }
    set disabled(value){
        this._disabled = value;
        this.handleDisabled();
    }

    @api
    get options() {
        return this.inputOptions;
        // return this.inputOptions.filter(option => option.value !== 'All');
    }
    set options(value) {
        let options = [];   
        let values = '';  
        let all = '';   
        this.inputOptions = options.concat(value);
        
        for (let data of value) {            
            if (data.value !== 'All') {
                all = all + data.label + ', ';
                // if (costCenter.value !== 'No_dept_code') {
                    values = values + data.label + ', ';
                    this.value.push(data.value);
                // }                
            }           
        }
        
        this._allData = all.slice(0, -2);
        this.inputValue = values.slice(0, -2);
    }

    @api
    clear(){
        this.value = [];
        this.inputValue = '';
        let listBoxOptions = this.template.querySelectorAll('.slds-is-selected');
        for (let option of listBoxOptions) {
            option.classList.remove("slds-is-selected");
        }

        this.closeDropbox();
    }

    renderedCallback() {
        if (!this.hasRendered) {
            //  we call the logic once, when page rendered first time
            this.handleDisabled();
        }
        this.hasRendered = true;

        if (!this._toggle) {
            this.template.querySelectorAll('.slds-listbox__item').forEach(element => {
                if (this.inputValue && this.inputValue.includes(element.dataset.value)) {
                    element.firstChild.classList.toggle("slds-is-selected")
                }          
            });
            this._toggle = true;
        }
        
    }

    handleDisabled(){
        let input = this.template.querySelector("input");
        if (input){
            input.disabled = this.disabled;
        }
    }

    handleClick() {
        let sldsCombobox = this.template.querySelector(".slds-combobox");
        sldsCombobox.classList.toggle("slds-is-open");
        if (!this.comboboxIsRendered){
            this.comboboxIsRendered = true;
        }
    }

    handleSelection(event) {
        let value = event.currentTarget.dataset.value;
        this.handleOption(event, value);
        
        let input = this.template.querySelector("input");
        input.focus();
        this.sendValues();
        this.closeDropbox();
    }

    sendValues(){
        let values = [];
        for (const valueObject of this.value) {
            values.push(valueObject);
        }

        this.dispatchEvent(new CustomEvent("valuechange", {
            detail: values
        }));
    }

    handleOption(event, value){
        let listBoxOption = event.currentTarget.firstChild;
        let isAll = false;

        if (listBoxOption.classList.contains("slds-is-selected")) {            
            this.value = this.value.filter(option => option != value);
        } else {
            let option = this.options.find(option => option.value === value);
            if (option.value) {
                this.value.push(option.value);
            }          
        }

        if (this.value.length > 1) {
            let values = '';

            for (const value of this.value) {
                if (value === 'All') {
                    values = this._allData + ',,';
                    isAll = true;
                    
                    break;
                } else if (value != 'All') {
                    values = values + value + ', ';
                } 
            }            
            this.inputValue = values.slice(0, -2);

        } else if (this.value.length === 1) {
            if (value === 'All') {
                this.inputValue = this._allData;
                isAll = true;

            } else {
                if (this.value[0]) {
                    this.inputValue = this.value[0];
                }   
            }
            
        } else {
            this.inputValue = '';
        }

        listBoxOption.classList.toggle("slds-is-selected");

        if (isAll) {
            this.value = [];
            for (let data of this.inputOptions) {
                this.value.push(data.value);
            }

            this.template.querySelectorAll('.slds-listbox__item').forEach(element => {{
                    if (!element.firstChild.classList.contains("slds-is-selected")) {            
                        element.firstChild.classList.add("slds-is-selected");
                    }
                }          
            });
        }
    }


    handleBlur() {
        if (!this.dropDownInFocus) {
            this.closeDropbox();
        }
    }

    closeDropbox() {
        let sldsCombobox = this.template.querySelector(".slds-combobox");
        sldsCombobox.classList.remove("slds-is-open");
    }

    handleMouseleave() {
        this.dropDownInFocus = false;
    }
    handleMouseEnter() {
        this.dropDownInFocus = true;
    }

    handleKeyPress() {
        return false;
    }
}