/**
 * Created by rebeccanachison on 10/4/21.
 */

import {LightningElement} from 'lwc';
import companyName from '@salesforce/label/c.Company_Name';
import companyNameCustomerAcquisition from '@salesforce/label/c.Company_Name_Customer_Acquisition';
import companyNameCustomerManagement from '@salesforce/label/c.Company_Name_Customer_Management';

export default class CustomerPortalProjectFooter extends LightningElement {

    rebranded = companyName == 'Perch' ? true : false;

    label = {
        companyName,
        companyNameCustomerAcquisition,
        companyNameCustomerManagement
    }

}