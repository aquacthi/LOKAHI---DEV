import { LightningElement, wire, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';

import REQUEST_OBJECT from '@salesforce/schema/BC_Request__c';
import Id from '@salesforce/schema/User.Id';
import DENIAL_REASON_FIELD from '@salesforce/schema/BC_Request__c.Denial_Reason__c';

import getRequestProjectList from '@salesforce/apex/RequestApprovalController.getRequestProjectList';
import getRequestApprover from '@salesforce/apex/RequestApprovalController.getRequestApprover';
import updateRequestProject from '@salesforce/apex/RequestApprovalController.updateRequestProject';

const columns = [
    { label: 'BIM Project Name', fieldName: 'BIM_Project_Name__c' },
    { label: 'Approval Status', fieldName: 'Approval_Status__c' },
    { label: 'Project Name', fieldName: 'Project_Name__c' },
    { label: 'Project Name Entered', fieldName: 'Project_Name_Entered__c' },
    { label: 'Role', fieldName: 'Role__c' },
];

export default class LwcRequestApproval extends LightningElement {
    @api recordId;
    
    userId = Id;
    @track error;
    @track boolVisible = false;
    @track mycolumns = columns;
    @track mydata;
    @track isModalOpen = false;
    @track decision;
    @track modalError;
    @track noRowSelected = false;
    @track rejected = false;
    @track approved = false;
    @track denialReasonIsOther = false;
    @track denialReason = '';
    @track recordTypeIdBIM360Amazonian;
    @track recordTypeIdBIM360NonAmazonian;
    @track recordTypeIdTokenFlexLicense;
    @track denialReasonValues = undefined;
    @track otherDenialReason = '';

    @wire(getRequestApprover, {requestId:'$recordId' })
    setBoolVisible({ error, data }) {
        if (data) {
            this.boolVisible = data;
        } else if (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error fetching data',
                    message: error.body.message,
                    variant: 'error',
                }),
            );
        }
    }
    
    @wire(getRequestProjectList, {requestId: '$recordId' })
    setMyData({ error, data}) {
        if (data) {
            console.log(' Got data ', JSON.stringify(data));
            this.mydata = data;
        } else if (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error fetching data',
                    message: error.body.message,
                    variant: 'error',
                }),
            );
        }
    }

    @wire(getObjectInfo, { objectApiName: REQUEST_OBJECT })
    wiredObjectInfo({ error, data }) {  
        if (data) {
            this.objectInfo=data;
            const rtis = this.objectInfo.recordTypeInfos;
            this.recordTypeIdBIM360Amazonian=Object.keys(rtis).find(rti => rtis[rti].name === 'BIM 360 Amazonian'); 
            this.recordTypeIdBIM360NonAmazonian=Object.keys(rtis).find(rti => rtis[rti].name === 'BIM 360 Non-Amazonian'); 
            this.recordTypeIdTokenFlexLicense=Object.keys(rtis).find(rti => rtis[rti].name === 'Token Flex License'); 
        } else if (error) {
            this.error = error;
            this.denialReasonValues = undefined;
        }            
    }    

    @wire(getPicklistValues, { recordTypeId:"$recordTypeIdBIM360NonAmazonian", fieldApiName: DENIAL_REASON_FIELD } )
    wiredDenialReasonValues({ error, data }) {
        console.log('denialReasonValues data===='+JSON.stringify(data));
        console.log('denialReasonValues error===='+JSON.stringify(error));
        if (data) {
            this.denialReasonValues = data.values;
            this.error = undefined;
            console.log('denialReasonValues data===='+JSON.stringify(this.denialReasonValues));
        } else if (error) {
            this.error = error;
            this.denialReasonValues = undefined;
        }        
    }
    
    getSelectedRec() {
        var selectedRecords =  this.template.querySelector("lightning-datatable").getSelectedRows();
        if(selectedRecords.length > 0 || this.rejected){
            console.log('selectedRecords are ', selectedRecords);
   
            let ids = '';
            selectedRecords.forEach(currentItem => {
                ids = ids + ',' + currentItem.Id;
            });
            this.selectedIds = ids.replace(/^,/, '');
            this.lstSelectedRecords = selectedRecords;
            // alert(this.selectedIds);
            console.log('decision ', this.decision);
            console.log('selectedIds ', this.selectedIds);
            console.log('lstSelectedRecords are ', this.lstSelectedRecords);

            updateRequestProject({
                decision          : this.decision, 
                denialReason      : this.denialReason, 
                otherDenialReason : this.otherDenialReason, 
                projectRequestIds : this.selectedIds,
                recordId          : this.recordId
            })
            .then(result => {
                if(result !== undefined) {
                    const event = new ShowToastEvent({
                        "title"     : "Success",
                        "message"   : "Request Projects updatead successfully!",
                        "variant"   :"success"
                    });
                    this.dispatchEvent(event);  
                    // this.mydata = getRequestApprover({requestId: '$recordId' });
                    // eval("$A.get('e.force:refreshView').fire();");
                    window.location.reload();
                    // this.handleCancelClick(null);
                }                
                console.log('result======'+JSON.stringify(result));
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        "title"   : 'Error creating record',
                        "message" : error.body.message,
                        "variant" : 'error',
                    }),
                );
                console.log("error===", JSON.stringify(error));
                console.log("error body message===", JSON.stringify(error.body.message));
            });  
        }   
    }

    handleRejectButton() {
        this.approved = false;
        this.rejected = true;
        this.decision = 'Rejected';
        this.openModal();
    }

    handleApproveButton() {
        this.decision = 'Approved';
        this.approved = true;
        this.rejected = false;
        this.openModal();;
    }

    checkSelectedRows() {
        var selectedRecords =  this.template.querySelector("lightning-datatable").getSelectedRows();
        if(selectedRecords.length == 0 && this.decision == 'Approved'){
            this.noRowSelected = true;
            this.modalError = 'Error: Please select project(s) to approve';
        } else {
            this.noRowSelected = false;
            this.modalError = '';
        }
    }

    openModal() {
        this.checkSelectedRows();
        // to open modal set isModalOpen tarck value as true
        if(!this.noRowSelected) {
            this.isModalOpen = true;
        }
    }
    closeModal() {
        // to close modal set isModalOpen tarck value as false
        this.isModalOpen = false;
        this.resetDenial();
    }
    submitDetails() {
        // to close modal set isModalOpen tarck value as false
        //Add your code to call apex method or do some processing
        this.isModalOpen = false;
        this.getSelectedRec();        
        this.resetDenial();
    }

    changeFieldHandler(event) {
        var value = event.target.value;
        console.log("value===="+value);
        if(event.target.dataset.id === 'denialReason'){
            this.denialReason = value;
            if (value == 'Other') {
                this.denialReasonIsOther = true;
            } else {
                this.denialReasonIsOther = false;
            }
            console.log("this.denialReason===="+this.denialReason);
            console.log("this.denialReasonIsOther===="+this.denialReasonIsOther);
        }
        if(event.target.dataset.id === 'otherDenialReason'){
            this.otherDenialReason = value;
        }
    }

    resetDenial() {
        this.denialReason = '';
        this.otherDenialReason = '';
        this.denialReasonIsOther = false;
    }
}