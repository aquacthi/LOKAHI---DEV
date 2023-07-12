import { LightningElement, wire } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import sResource from '@salesforce/resourceUrl/BIM';
import communityBasePath from '@salesforce/community/basePath';

export default class Ccsp_header extends LightningElement {
    bimLogo = `${sResource}/images/Amazon_BIM_Logo.png`;

    homePageUrl = `${communityBasePath}/`;
    
    loadCSS() {
        const globalStyle = document.getElementById('globalStyle');
        const styleLen = globalStyle ? globalStyle.length : 0;

        return styleLen === 0;
    }   

    connectedCallback() {
        const loadCSS = this.loadCSS();
        if (!loadCSS) {
            return;
        }
        
        loadStyle(this, `${sResource}/css/global.css`)
        .then((event) => {
            if (event) {
                event.target.setAttribute('id', 'globalStyle');
            }
        });
    }
}