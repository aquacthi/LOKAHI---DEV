import { LightningElement, wire } from 'lwc';
import communityBasePath from '@salesforce/community/basePath';

import BIM_Footer_Contact_Title from '@salesforce/label/c.BIM_Footer_Contact_Title';
import BIM_Footer_Contact_Email from '@salesforce/label/c.BIM_Footer_Contact_Email';
import BIM_Footer_Copyright from '@salesforce/label/c.BIM_Footer_Copyright';
import BIM_Help_Doc_Label from '@salesforce/label/c.BIM_Help_Doc_Label';
import BIM_Footer_Help_Doc_Link from '@salesforce/label/c.BIM_Footer_Help_Doc_Link';
import BIM_Footer_Help_center from '@salesforce/label/c.BIM_Footer_Help_center';
import BIM_Footer_Disclaimer from '@salesforce/label/c.BIM_Footer_Disclaimer';

export default class bim_footer extends LightningElement {
    // inquiryAddress;
    label = {
        BIM_Footer_Contact_Title,
        BIM_Footer_Contact_Email,
        BIM_Footer_Copyright,
        BIM_Help_Doc_Label,
        BIM_Footer_Help_Doc_Link,
        BIM_Footer_Help_center,
        BIM_Footer_Disclaimer
    }
    currentYear = new Date().getFullYear();
    copyrightText = this.updateDynamicLabel(BIM_Footer_Copyright, this.currentYear);

    updateDynamicLabel(stringToFormat, ...formattingArguments) {
        if (typeof stringToFormat !== 'string') throw new Error('\'stringToFormat\' must be a String');
        return stringToFormat.replace(/{(\d+)}/gm, (match, index) =>
            (formattingArguments[index] === undefined ? '' : `${formattingArguments[index]}`));
    }
}