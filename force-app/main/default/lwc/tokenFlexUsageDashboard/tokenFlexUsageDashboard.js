import { LightningElement, wire, track, api } from 'lwc';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import ChartJS from '@salesforce/resourceUrl/chartjs_v280';
import WWD_Portal_Resources from '@salesforce/resourceUrl/WWD_Portal_Resources';

import getTokenFlexUsage from '@salesforce/apex/TokenFlexDashboardController.getTokenFlexUsage';
import getProductName from '@salesforce/apex/TokenFlexDashboardController.getProductName';
// import chartjs from '@salesforce/resourceUrl/DashboardChartJs';
// import chartjs from '@salesforce/resourceUrl/lwcc__chartjs_v280';

export default class TokenFlexUsageDashboard extends LightningElement {
    downImg = WWD_Portal_Resources + '/WWD_Portal_Resources/images/caret-down.svg';

    isTable = true;
    tokenFlexUsageList;
    initialTokenFlexUsagenData;
    sortBy;
    sortDirection = 'asc';
    resultData = true;

    /**
     * Summary fields
     */
    @track costCenterOptions;
    @track usageDateOptions;
    @track totalTokensConsumed = 0;
    @track totalTokenCost = 0;
    @track selectedCostCenter = [];
    @track _usageDate;

    @api chartConfig;
    
    chartConfiguration;

    chart;
    @track isChartJsInitialized;
    @track chartConfiguration;

    connectedCallback() {
        // loadScript(this, chartjs);
        loadStyle(this, WWD_Portal_Resources + '/WWD_Portal_Resources/wwd.css'); 
    }

    renderedCallback() {
        if (this.isChartJsInitialized) {
         return;
        }
        // load static resources.
        Promise.all([loadScript(this, ChartJS)])
         .then(() => {
           try {
            const ctx = this.template.querySelector("canvas.barChart").getContext('2d');
            this.chart = new window.Chart(ctx, {
                type: 'bar',
                data: {
                        labels: ["data1","data2","data3","data4","data5","data6","data7"],
                        datasets: [
                                    {
                                        label: 'dataset',
                                        barPercentage: 0.5,
                                        barThickness: 6,
                                        maxBarThickness: 8,
                                        minBarLength: 2,
                                        backgroundColor: "blue",
                                        data: [65, 59, 80, 81, 56, 55, 40],
                                    },
                                ],
                        },
                        resposive:true,
                    });
                console.log('========TokenFlexUsageDashboard==========');
            } catch(error) {
               // this.isChartJsInitialized = false;
               console.log('========TokenFlexUsageDashboard error==========' + error);
            }
           
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error loading ChartJS',
                    message: error.message,
                    variant: 'error',
                })
            );
        });
    }

    @wire (getTokenFlexUsage) 
    wiredTokenFlexUsage(result){
        try {
            if (result.data.tokenFlexUsageList) {
                const date = new Date();
                this.initialTokenFlexUsagenData = result.data.tokenFlexUsageList;
                this._usageDate = date.toISOString().substring(0, 7);
                   // this.handleSearch();
            } 
   
            if (result.data.costCenterList) {
                var tempCostCenter = [{label: 'All', value: 'All'}];
                for (let costCenter in result.data.costCenterList) {
                    tempCostCenter.push({label: costCenter, value: result.data.costCenterList[costCenter]});
                    if (costCenter !== 'All') {
                        if (costCenter !== 'No_dept_code') {
                            this.selectedCostCenter.push(costCenter);
                        }
                    }
                }                
                // this.handleSearch();
                this.costCenterOptions = tempCostCenter;
            } 
   
            if (result.data.usageDateList) {
                var tempUsageDate = [{label: this._usageDate, value: this._usageDate}];
                for (let usageDate in result.data.usageDateList) {
                    tempUsageDate.push({label: usageDate, value: result.data.usageDateList[usageDate]});
                }
                this.usageDateOptions = tempUsageDate;
   
                // this.calculateDeliverySummary();
            } 
   
            this.handleSearch();
        } catch (error) {
            console.log(error);
        }
    }
   

    @wire(getProductName, {})
    wireProductName({error, data}) {
        if (error) {
            this.error = error;
            console.log('error => ' + JSON.stringify(error));
            this.chartConfiguration = undefined;
        } else if (data) {   
            this.chartConfiguration = {
                type: 'bar',
                data: {
                    labels: ["data1","data2","data3","data4","data5","data6","data7"],
                    datasets: [
                                {
                                    label: 'dataset',
                                    barPercentage: 0.5,
                                    barThickness: 6,
                                    maxBarThickness: 8,
                                    minBarLength: 2,
                                    backgroundColor: "blue",
                                    data: [65, 59, 80, 81, 56, 55, 40],
                                },
                            ],
                },
                options: {
                    resposive:true,
                },
            };
            console.log('data => ', data);
            this.error = undefined;
        }
    }

    calculateDeliverySummary() {

        this.totalTokensConsumed = 0;
        this.totalTokenCost = 0;

        for (let rec of this.tokenFlexUsageList) {
            if (rec.Tokens_Consumed__c != null) {
                this.totalTokensConsumed = this.totalTokensConsumed + rec.Tokens_Consumed__c;
            }

            if (rec.Token_Cost__c != null) {
                this.totalTokenCost = this.totalTokenCost + rec.Token_Cost__c;
            }          
        }

        this.totalTokensConsumed = Math.round(this.totalTokensConsumed).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
        this.totalTokenCost = '$' + Math.round(this.totalTokenCost).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    }
    
    /* Multi-select */
    handleMultiSelectValueChange(event) {
        let dataSetId = event.currentTarget.dataset.id;
        
        if (dataSetId === 'cost_center_options') {
            this.selectedCostCenter = event.detail;
            this.handleSearch();
        }
    }

    changeDate(event) {
        this._usageDate = event.target.value;
        console.log(this._usageDate);
        this.handleSearch();
    }

    handleSearch() {
        console.log('=======this.selectedCostCenter==========' + this.selectedCostCenter);
        if (this.selectedCostCenter.length === 0 && !this._usageDate) {
            this.tokenFlexUsageList = this.initialTokenFlexUsagenData;
        } else {
            this.tokenFlexUsageList = this.initialTokenFlexUsagenData;

            if (this._usageDate) {
                let recs = [];

                for (let rec of this.tokenFlexUsageList) {
                    if (rec.Usage_Date__c && rec.Usage_Date__c.toString().substring(0, 7) == this._usageDate) {
                        recs.push(rec);
                    } 
                }

                if (recs.length == 0) {
                    this.resultData = false;
                } else {
                    this.resultData = true;
                }
                
                this.tokenFlexUsageList = recs;
                
            }

            if (this.selectedCostCenter && this.selectedCostCenter.length > 0) {
                let recs = [];

                for (let rec of this.tokenFlexUsageList) {
                    if (this.selectedCostCenter.includes('All')) {
                        recs.push(rec);
                    } else if (this.selectedCostCenter.includes(rec.Cost_Center__c)) {
                        recs.push(rec);
                    }
                }    

                if (recs.length == 0) {
                    this.resultData = false;
                } else {
                    this.resultData = true;
                }
                
                this.tokenFlexUsageList = recs;
            }
        }

        this.calculateDeliverySummary();       
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