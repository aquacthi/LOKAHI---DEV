/*
 * (Summary)    Token Flex Usage dashboard - Token Flex Usage table chart
 * (Copyright)  WWD
 * (Author)     kimdanbi
 * (Email)      kimdanbi@amazon.com

 * (Change Log)
 * Date       | Author                                   | Version | Comments
 * ------------------------------------------------------------------------------------------------
 * 2022-09-16 | kimdanbi                                 | 1.0     | Initial Design
 * 
 */
import { LightningElement, wire, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import Id from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';
import USER_COST_CENTER_ACCESS_FIELD from '@salesforce/schema/User.Cost_Center_Access__c';

import WWD_Portal_Resources from '@salesforce/resourceUrl/WWD_Portal_Resources';

import getTokenFlexUsage from '@salesforce/apex/TokenFlexUsageTableController.getTokenFlexUsage';
import getUsagePeriods from '@salesforce/apex/TokenFlexUsageTableController.getUsagePeriods';
import getApprovers from '@salesforce/apex/TokenFlexUsageTableController.getApprovers';
import getUsers from '@salesforce/apex/TokenFlexUsageTableController.getUsers';
import getBusinessUnits from '@salesforce/apex/TokenFlexUsageTableController.getBusinessUnits';
import getProductNames from '@salesforce/apex/TokenFlexUsageTableController.getProductNames';
import getDeliverySummary from '@salesforce/apex/TokenFlexUsageTableController.getDeliverySummary';
import getCSVHeaderNames from '@salesforce/apex/TokenFlexDashboardController.getCSVHeaderNames';

export default class TokenFlexUsageTable extends LightningElement {
    downImg = WWD_Portal_Resources + '/WWD_Portal_Resources/images/caret-down.svg';

    tokenFlexUsageList = [];
    initialTokenFlexUsagenData = [];
    sortBy;
    sortDirection = 'asc';
    userCostCenterAccess;
    
    headers = {};

    @track spinner = true;
    @track resultData  = true;
    /**
     * Option fields
     */
    @track usageDateOptions;
    @track selectedUsageDate = [];

    @track costCenterOptions;   
    @track selectedCostCenter = [];

    @track approverNameOptions;
    @track selectedApproverName = [];

    @track userOptions;
    @track selectedUser = [];

    @track businessUnitOptions;
    @track selectedBusinessUnit = [];

    @track productNameOptions;
    @track selectedProductName = [];

    @track totalTokensConsumed = 0;
    @track totalTokenCost = 0;

    
    @track isInitialized;

    connectedCallback() {
        loadStyle(this, WWD_Portal_Resources + '/WWD_Portal_Resources/wwd.css'); 

        getCSVHeaderNames()
        .then(result => {
            if (result) {
                
                this.headers = result;
            }
        })
        .catch(error => {
            console.log('getCSVHeaderNames error => ' + error);
        }) 
    }

    renderedCallback() {
        if (this.usageDateOptions && 
            this.costCenterOptions && 
            this.approverNameOptions && 
            this.userOptions &&
            this.businessUnitOptions &&
            this.productNameOptions &&
            !this.isInitialized) {
            console.log('>>>> CHANGED renderedCallback() ');

            getTokenFlexUsage({
                usageDates: this.selectedUsageDate, 
                costCenters: this.selectedCostCenter,
                approverNames: this.selectedApproverName,
                users: this.selectedUser,
                businessUnits: this.selectedBusinessUnit,
                productNames: this.selectedProductName})
            .then((data) => {
                
                console.log('>>>> in getTokenFlexUsage ');
                try {          
                    var tempList = [];
                    for (let tokenFlex in data) {
                        tempList.push(data[tokenFlex]);
                    }

                    this.tokenFlexUsageList = tempList;

                    if (this.tokenFlexUsageList.length == 0) {
                        this.resultData = false;
                    } else { 
                        
                        this.resultData = true;
                    }

                    // this.calculateDeliverySummary();              
                    this.isInitialized = true;

                } catch (error) {
                    console.error('Error in getting data', error);
                    this.spinner = false;
                }
            })
            .catch(error => {
                this.error = error;
                console.log('error => ' + JSON.stringify(error));

                this.spinner = false;
            })
            getDeliverySummary({
                usageDates: this.selectedUsageDate, 
                costCenters: this.selectedCostCenter,
                approverNames: this.selectedApproverName,
                users: this.selectedUser,
                businessUnits: this.selectedBusinessUnit,
                productNames: this.selectedProductName})
            .then((data) => {
                console.log('>>>> in getDeliverySummary ');

                try {          
                    
                    this.totalTokensConsumed = Math.round(data[0]).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
                    this.totalTokenCost = '$' + Math.round(data[1]).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
                    this.spinner = false;        
    
                } catch (error) {
                    console.error('Error in getting data', error);
                    this.spinner = false;
                }
            })
            .catch(error => {
                this.error = error;
                console.log('error => ' + JSON.stringify(error));
    
                this.spinner = false;
            })
        }
    }

    @wire(getRecord, { recordId: Id, fields: [USER_COST_CENTER_ACCESS_FIELD]}) 
    userDetails({error, data}) {
        if (data) {
            this.userCostCenterAccess = data.fields.Cost_Center_Access__c.value;
            var tempCostCenter = [{label: 'All', value: 'All'}];
            for (let costCenter of this.userCostCenterAccess.split(',')) {
                tempCostCenter.push({label: costCenter, value: costCenter});
                this.selectedCostCenter.push(costCenter);                            
            }                
            this.costCenterOptions = tempCostCenter;
            
        } else if (error) {
            this.error = error ;
            console.log(' >>>> this.userCostCenterAccess error ' + this.error);
        }
    }

    @wire(getUsagePeriods) 
    usagePeriodOption({error, data}) {
        if (data && data.length > 0) {
            var tempUsageDate = [{label: 'All', value: 'All'}];
            for (let usageDate of data) {                        
                tempUsageDate.push({label: usageDate, value: usageDate});
                this.selectedUsageDate.push(usageDate);
            }
            this.usageDateOptions = tempUsageDate;
        } else if (error) {
            this.error = error ;
            console.log(' >>>> usagePeriodOption error ' + this.error);
        }
    }

    @wire(getApprovers) 
    approverOption({error, data}) {
        if (data && data.length > 0) {
            var optionList = [{label: 'All', value: 'All'}];
            for (let val of data) {                        
                optionList.push({label: val, value: val});
                this.selectedApproverName.push(val);
            }
            this.approverNameOptions = optionList;
        } else if (error) {
            this.error = error ;
            console.log(' >>>> approverOption error ' + this.error);
        }
    }

    @wire(getUsers) 
    userOption({error, data}) {
        if (data && data.length > 0) {
            var optionList = [{label: 'All', value: 'All'}];
            for (let val of data) {                        
                optionList.push({label: val, value: val});
                this.selectedUser.push(val);
            }
            this.userOptions = optionList;
        } else if (error) {
            this.error = error ;
            console.log(' >>>> userOption error ' + this.error);
        }
    }

    @wire(getBusinessUnits) 
    businessUnitOption({error, data}) {
        if (data && data.length > 0) {
            var optionList = [{label: 'All', value: 'All'}];
            for (let val of data) {                        
                optionList.push({label: val, value: val});
                this.selectedBusinessUnit.push(val);
            }
            this.selectedBusinessUnit.push('');

            this.businessUnitOptions = optionList;
        } else if (error) {
            this.error = error ;
            console.log(' >>>> businessUnitOption error ' + this.error);
        }
    }

    @wire(getProductNames) 
    productNameOption({error, data}) {
        if (data && data.length > 0) {
            var optionList = [{label: 'All', value: 'All'}];
            for (let val of data) {                        
                optionList.push({label: val, value: val});
                this.selectedProductName.push(val);
            }
            this.productNameOptions = optionList;
        } else if (error) {
            this.error = error ;
            console.log(' >>>> productOption error ' + this.error);
        }
    }

    // calculateDeliverySummary() {
    //     getDeliverySummary({
    //         usageDates: this.selectedUsageDate, 
    //         costCenters: this.selectedCostCenter,
    //         approverNames: this.selectedApproverName,
    //         users: this.selectedUser,
    //         businessUnits: this.selectedBusinessUnit,
    //         productNames: this.selectedProductName})
    //     .then((data) => {
    //         try {          
                
    //             this.totalTokensConsumed = Math.round(data[0]).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    //             this.totalTokenCost = '$' + Math.round(data[1]).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    //             this.spinner = false;        

    //         } catch (error) {
    //             console.error('Error in getting data', error);
    //             this.spinner = false;
    //         }
    //     })
    //     .catch(error => {
    //         this.error = error;
    //         console.log('error => ' + JSON.stringify(error));

    //         this.spinner = false;
    //     })
    // }
    
    /* Multi-select */
    handleMultiSelectValueChange(event) {
        this.isInitialized = false;
        this.spinner = true;

        let dataSetId = event.currentTarget.dataset.id;
        let dataSetName = event.currentTarget.dataset.fieldname;

        if (event.detail.includes('All')) {
            this[dataSetId] = [];
            for (let data of this[dataSetName]) {
                if (data.value != 'All') {
                    this[dataSetId].push(data.value);
                }               
            }
        } else {
            this[dataSetId] = event.detail;
        }
        // this.calculateDeliverySummary();
    }

    // export token flex usage data
    downloadDetails() {
        this.exportCSVFile(this.headers, this.tokenFlexUsageList, "token flex usage data")
    }

    exportCSVFile(headers, totalData, fileTitle) {
        if(!totalData || !totalData.length){
            return null
        }

        const jsonObject = JSON.stringify(totalData);
        const result = this.convertToCSV(jsonObject, headers);

        if(result === null) return
            
        const blob = new Blob([result]);            
        const exportedFilename = fileTitle ? fileTitle+'.csv' :'export.csv';

        if(navigator.msSaveBlob){
            navigator.msSaveBlob(blob, exportedFilename);

        } else if (navigator.userAgent.match(/iPhone|iPad|iPod/i)){
            const link = window.document.createElement('a');
            link.href='data:text/csv;charset=utf-8,' + encodeURI(result);
            link.target="_blank";
            link.download=exportedFilename;
            link.click();

        } else {
            const link = document.createElement("a");

            if(link.download !== undefined){
                const url = URL.createObjectURL(blob);

                link.setAttribute("href", url);
                link.setAttribute("download", exportedFilename);
                link.style.visibility='hidden';

                document.body.appendChild(link);

                link.click();

                document.body.removeChild(link);
            }
        }        
    }

    convertToCSV(objArray, headers){
        const columnDelimiter = ',';
        const lineDelimiter = '\r\n';
        const actualHeaderKey = Object.keys(headers);
        const headerToShow = Object.values(headers) ;

        let str = '';
        str+=headerToShow.join(columnDelimiter); 
        str+=lineDelimiter;

        const data = typeof objArray !=='object' ? JSON.parse(objArray):objArray;
    
        data.forEach(obj=>{
            let line = '';

            actualHeaderKey.forEach(key=>{

                if(line !=''){
                    line+=columnDelimiter;
                }

                let strItem = obj[key]+'';
                line+=strItem? strItem.replace(/,/g, ''):strItem;
            })
            str+=line+lineDelimiter;
        })

        return str
    }

    handleSorting(event) {
        if(this.sortBy === event.currentTarget.dataset.fieldname) {
            this.sortDirection = this.sortDirection === 'asc' ? 'desc': 'asc';
        } else {
            if(this.template.querySelector('.arrow_desc')) {
                this.template.querySelector('.arrow_desc').classList.remove('arrow_desc');
            } else if(this.template.querySelector('.arrow_asc')) {
                this.template.querySelector('.arrow_asc').classList.remove('arrow_asc');
            }
        }
        
        if(this.sortDirection === 'asc') {
            event.currentTarget.classList.remove('arrow_desc');
            event.currentTarget.classList.add('arrow_asc');
        } else {
            event.currentTarget.classList.remove('arrow_asc');
            event.currentTarget.classList.add('arrow_desc');
        }

        this.sortBy = event.currentTarget.dataset.fieldname;
        this.sortData(this.sortBy, this.sortDirection);
    }

    // table sorting when the user is clicking the icon
    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.tokenFlexUsageList));

        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1: -1;

        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });

        this.tokenFlexUsageList = parseData;
    } 
}